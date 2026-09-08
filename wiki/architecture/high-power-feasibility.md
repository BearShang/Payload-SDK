---
title: 自制转接板申请高功率可行性评估
type: architecture
status: draft
updated: 2026-09-08
sources:
  - hardware/SCH_Schematic2_2026-09-08.pdf
  - psdk_lib/include/dji_power_management.h
  - psdk_lib/include/dji_version.h
  - samples/sample_c/module_sample/power_management/test_power_management.c
  - samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c
  - samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.c
  - samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h
  - CMakeLists.txt
  - test/raw/e300-usb-readonly-2026-09-08.json
tags:
  - high-power
  - usb
  - m400
---

# 自制转接板申请高功率可行性评估

## 适用范围与结论

本地 SDK 头文件声明 3.16.0（build 2338）。首轮只分析源码和设计资料，并于 2026-09-08 补充核查 DJI 官方在线文档。随后经用户授权对 E300 做只读 SSH 能力探测；仍未运行示例、申请电压或进行电气测量。

**有条件可行，但“本自制转接板 + 普通电脑 USB Host 口直连，再补软件”不是已经成立的实现路径。** 图中没有处理器或协议桥；E-Port V2 负载通信要求 Device 端。需要先明确运行 PSDK 的处理器及 USB Device/桥接链路，再评估申请程序。

用户于 2026-09-08 明确报告：JUMP 7–8 与 3–4 分别接地，使用 M400 和 SkyPort V3 转接环。不是 ONLINE 与 HIGH_PWR_REQ 仅互连。目标电压已确认为 24 V，M1000/E300 独立供电。线缆型号及飞行器/转接环固件未知。原理图的 45 针定义与 E-Port V2 / SkyPort V3 同轴线定义相符，尚需核对实物线序。

### 本次验收

用户使用万用表测量自制板图示 **VCC 与 GND**，读到 **24 V** 即算本次通过。这里只验收电压申请功能，尚未测得，不预先判通过。不要求 M1000 由飞机供电、DC/DC 设计、负载电流或带载能力验证；后续若需这些能力应另立范围。

已检查 E300：ARM64 Ubuntu 和开发包具备运行平台基础，但当前 UDC 目录为空，尚无可用 Device 链路。详见 [[wiki/experiments/e300-usb-readonly-2026-09-08|只读 SSH 记录]]。下一步仅聚焦通信链路、SDK 初始化、24 V 申请与用户测压。

## 硬件与电源边界

| 项目 | 已有证据与判断 | 尚缺证据 |
| --- | --- | --- |
| 在位与申请 | 原理图第 1 页：CN1-43 经 JUMP 7–8 到地，CN1-36 经 3–4 到地。用户确认安装这两组跳帽。 | 实物引脚方向、焊接及地连接的通断确认 |
| 电源出口 | CN1 电源聚合为 VCC，VCC/GND 是用户指定测点，目标 24 V；不是向电脑 USB 申请 USB PD。 | 实测电压；额定电流/负载/浪涌不属本次验收 |
| USB 供电 | USB2-1 标为 VBUS，与 VCC 无可见连接，图中无降压器。不能因官方把飞机电源命名 VBUS 而将两网相连。 | PCB/实物隔离、USB Device 端的供电与 VBUS 检测方案、反灌边界 |
| USB 数据 | 图中有 D+/D-、SuperSpeed 转接与被动/保护器件，无 MCU、USB-UART 或主机间协议桥。 | 实际线缆类型、电脑接口角色、可用 Device 控制器 |
| 功率承受 | 本图未画 VCC 限流、保险丝、反灌保护或稳压。 | 带载承受能力未验证，不纳入此次电压功能验收 |
| 其他信号 | JUMP 1–2 是 PPS 对地，5–6 是 FTS 对地，不属于本轮申请所需跳帽。 | 不评估 FTS 安全功能或任何停桨行为 |

本表来自 [自制原理图第 1 页](../../hardware/SCH_Schematic2_2026-09-08.pdf)，视觉范围和限制见 [[wiki/sources/custom-board-schematic|逐文件来源笔记]]。原理图不证明实物可承受任何给定功率。继续通电验证前应先确认 VCC 与电脑 USB VBUS 没有误接；本轮不要求用户带电改线。

官方核查补充：E-Port V2 同轴线 43/36 分别为 ONLINE/HIGH_PWR_REQ，均允许直接或经 0 欧电阻接地；在位后默认 13.6 V，高电压仍需 SDK 协议选择。飞机是 USB Host，负载是 Device。因此已报告的两组接地符合该接口规则，但不是成功申请的证明。[DJI 飞行器硬件接口，核查日 2026-09-08](https://developer.dji.com/doc/payload-sdk-tutorial/cn/payload-quick-start/configure-the-hardware-environment/drone-port.html)

## 软件申请边界

1. 先有匹配目标设备的 OSAL/HAL、真实可通信链路和合法应用配置，再完成 SDK 初始化及飞机/适配器识别。凭据不记录在 Wiki 中。本批未完整摄取 SDK Core 启动链路。
2. 初始化电源管理。头文件要求申请前注册引脚写回调；不能因为硬件固定接地就假定回调可省略或空回调必然可用。
3. 根据真实适配器分支选择 API。当前示例对 SkyPort V3 / E-Port V2 ribbon cable 调用 V2，并固定选 17 V；用户目标已明确为 24 V，应使用 E_DJI_HIGH_POWER_VOLTAGE_24V，而本轮未修改或运行示例。
4. 检查确实进入申请分支、申请返回码及后续实测结果。服务函数成功返回不一定意味着执行了申请。
5. 按用户范围，在自制板 VCC/GND 用万用表确认 24 V 即完成本次验收；不将此记录扩写为带载或飞行验证成功。本轮没有执行申请或测压步骤。

证据：[电源 API](../../psdk_lib/include/dji_power_management.h) 的 Init / RegWriteHighPowerApplyPinCallback / ApplyHighPowerSyncV2；[示例](../../samples/sample_c/module_sample/power_management/test_power_management.c) 的 DjiTest_PowerManagementStartService。API 枚举允许表达 13.6 / 17 / 24 V，不自动保证全部转接器支持每档。

官方电源管理页说明 V2 的指定电压申请用于 SkyPort V3 / E-Port V2，并将 Manifold 3 对外输出高压列为另一功能。这里不调用 OutputHighPower 来代替向飞机申请。[DJI 电源管理，核查日 2026-09-08](https://developer.dji.com/doc/payload-sdk-tutorial/en/function-overview/basic-function/power-management.html)

## 电脑直连为什么尚不可行

普通电脑 Host 口与飞机 Host 口之间，不能用被动转接或换 USB 插头建立负载 Device。当前电脑仅知运行 Windows，未查询其 USB 控制器；不能排除特殊 Device/双角色硬件，但不能假定存在。换到 Linux、WSL 或安装 libusb 本身也不创建缺失的 Device 控制器。

本仓 [Linux USB HAL](../../samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.c) 明确分 Host/libusb 与 Device/端点文件两条路径；[端点头文件](../../samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h) 假定 /dev/usb-ffs 文件已准备好。[根 CMake](../../CMakeLists.txt) 默认 Linux/manifold3，并非 Windows 即插即用应用。本批没有验证 Windows 移植或任何 USB 枚举。

后续可评估两条路线，尚未选型、购买或实施：

- 在具备真实 USB Device 能力的 MCU / Linux 载荷板上运行 PSDK，电脑只负责开发与日志。需另审具体控制器、描述符、供电和 SDK 平台。
- 通过飞机支持的 USB-串口 Device 转换，再由 UART 接 PSDK 运行平台。若平台仍是电脑，还需电脑侧串口接口及合适的 SDK 运行环境；单个 USB-TTL 转换器插电脑不等于已经把两个 Host 接通。

官方 E-Port V2 开发指南列有 FT232、CP2102 和特定身份的 USB VCOM 路线，但它们是待匹配的通信方案，不是本被动板已经具备的功能。VCOM 的 F002 不等于本地 Bulk 示例的 F001。[DJI E-Port V2 开发套件](https://developer.dji.com/doc/payload-sdk-tutorial/en/payload-quick-start/quick-guide/E-Port%20V2.html)

## 冲突与不确定性

- 示例注释称“仅 RTOS、Linux 不申请”，函数实际按飞机/适配器选择分支。不可把注释当作 SDK 不支持 Linux 的证据。
- GD32 BSP 示例初始化 PA7 为推挽高，再按回调置高/低；与自制板固定接地方案不是可直接替换的电路。未解析官方板上的中间电路，也未验证固定接地的回调处理方式。
- 在线接口说明与本地文件是不同证据层。在线说明未另存为正式来源文件，不为 URL 伪造 SHA-256；sources 只列实际摄取的本地文件，在线链接保留核查日期，后续可能变化。
- 官方接口功率指标不能证明自制板承载能力；此次只验收 24 V 测点电压，不追加带载试验。
- 转接环、24 V 目标、E300 独立供电和 VCC/GND 测点已由用户确认。当前剩余关键项是 E300 通信接口、固定接地的回调适配和 SDK 申请链路，不以 E300 电源输入或负载电流阻塞本次任务。

## 相关页面

- [[wiki/sources/source-inventory|来源清单与逐文件哈希]]
- [[wiki/sources/power-management-api|电源管理 API]]
- [[wiki/sources/power-management-sample|示例分支]]
- [[wiki/sources/gd32-high-power-pin|GD32 引脚示例]]
- [[wiki/sources/linux-usb-bulk-implementation|Linux USB 实现]]
- [[wiki/sources/linux-usb-bulk-config|Linux 端点配置]]
- [[wiki/sources/root-build-entry|构建平台]]
- [[wiki/sources/sdk-version|版本声明]]
- [[wiki/index|Wiki 索引]]
