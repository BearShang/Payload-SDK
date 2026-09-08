---
title: E300 作为 24 V 申请平台的只读验证
type: experiment
status: draft
updated: 2026-09-08
sources:
  - test/raw/e300-usb-readonly-2026-09-08.json
  - psdk_lib/include/dji_power_management.h
  - CMakeLists.txt
tags:
  - e300
  - high-power
  - usb
---

# E300 作为 24 V 申请平台的只读验证

## 目标与边界

用户已确认目标是 M400 + SkyPort V3 申请 **24 V**，并指定 MTT_E300 参考工程及一台 E300，授权尝试 SSH 登录。随后明确 M1000 与自制板分开供电，本次由用户使用万用表测量自制板图示 VCC/GND，读到 24 V 即通过。

**本次验收仅为电压申请功能，不要求 E300 由飞机供电、DC/DC 设计、目标负载电流或带载能力测试。** 用户提供的测点截图对应已摄取原理图的 VCC/GND 端子。当前尚未申请或测得 24 V，不标记通过。后续若扩展到带载，应另立任务，不将其混入此次验收。

SSH 已成功连接，仅执行能力读取。本轮不改内核/USB 角色、网络或时钟，不部署或运行 PSDK，不申请电压；原先“仅离线资料评估”的边界由用户明确扩展到此次只读 SSH，未扩展到设备控制。

## 观察结果

| 检查项 | 结果 | 判断边界 |
| --- | --- | --- |
| OS / CPU | Ubuntu 22.04.4，Linux 6.6.10，aarch64 | 与本仓 ARM64 Linux 路线架构相符，ABI 和运行尚未测试 |
| 开发包 | gcc/g++、make、cmake、libusb 开发包已登记安装 | 不是 PSDK 编译/链接通过 |
| UDC | /sys/class/udc 存在但为空 | 当前无法绑定一个已注册 UDC 来形成 gadget |
| USB Role Switch | UPHY0001:00 至 :03 的 role 均为 none | 没有尝试切换，不能推定切到 device 即可工作 |
| 内核配置 | GADGET=y，CONFIGFS/LIBCOMPOSITE/F_ACM/F_FS=m，M1000_UDC 未启用 | 有 gadget 框架，但专用控制器路径尚未成立 |
| gadget 目录 | /sys/kernel/config/usb_gadget 不存在 | 未加载/配置状态需进一步区分，本轮未加载模块 |
| Host 拓扑 | xhci-m1000、xhci_hcd 根集线器及 HID | 证明 Host 栈在工作，不证明 Device 功能或飞机链路 |

来源：[8 条命令的原始返回](../../test/raw/e300-usb-readonly-2026-09-08.json)、[[wiki/sources/e300-usb-readonly-record|来源身份和局限]]。

**结论：E300 可以作为 PSDK Linux 运行平台候选，但这台机器当前没有已注册的 USB Device 控制器；不能把 USB 直连方案标记为已可用。** 这是当前状态，不是宣称 E300 硬件永远不支持 Device。

Linux 官方说明要求 gadget 绑定具体 UDC 才能由 Host 枚举，框架和端点描述并不替代控制器。[Linux gadget/configfs 文档，访问 2026-09-08](https://docs.kernel.org/usb/gadget_configfs.html)

## MTT_E300 参考工程回查

本轮只读打开相邻的 MTT_E300 参考工程，未运行其脚本、复用 SSH/时钟配置或修改该工程。跨库资料没有复制进本仓来源层，也不为仓库外路径建立不合规范的 source_path；本节属于定位明确的跨库原始资料回查，不宣称完成该工程的正式摄取。

核对 [M1000 MXM 模组规格书，2026-03-05](../../../../MTT_E300/datasheet/E300/E300模组对应底板资料260306/模组开发资料_2026-03-06/02_SOM模组规格书与设计指南/M1000%20MXM模组规格书_2026-03-05.pdf) 的 PDF 第 5、8 页，并完整视觉复核这两页。核查时逐文件 SHA-256 为 `d97abfb981a54ac820ec69c3597ab069830054a36a592d89486b8d112bf59331`，截图只保存在本仓 wiki/.tmp/high-power/。

- 第 5 页：金手指 168/170 是软件加载专用 USB，不是对外功能接口。不能直接把 Download 口当作运行中可用的 PSDK gadget 口。
- 第 8 页：模组 PWR_SRC 主电源输入范围 **12–20 V**。24 V 超过该模组规定范围，不能直供 PWR_SRC。
- 上述电源范围仅保留为本次资料回查结果。用户已明确 M1000 独立供电，该范围与 DC/DC 设计不再是此次申请/测压的前置条件。
- 参考工程存在不同整机和参考底板资料，不能根据用户名称 E300 就固定套用某款端口编号。需核对当前整机/底板的型号或接口照片。

## 24 V 软件路径

本地 [电源头文件](../../psdk_lib/include/dji_power_management.h) 对应表达式为 `DjiPowerManagement_ApplyHighPowerSyncV2(E_DJI_HIGH_POWER_VOLTAGE_24V)`。这里只记录目标 API，不创建或运行调用程序。

应在 SDK 初始化、适配器确认、链路成立及固定接地方案的回调适配核实之后使用。现有示例的 17 V 默认值不代表用户目标；本轮没有修改示例。程序返回码作为诊断记录，用户万用表在 VCC/GND 测得 24 V 是本次通过依据；不追加限流负载或满功率验收要求。

## 后续路线与门槛

- 原生 Device 路线：先向供应商确认当前型号/固件下可用的物理口、UDC 驱动、角色切换方式与 VBUS 控制。不能仅因内核有 role-switch 节点就盲写 device。
- 串口桥接路线：飞机端采用其支持的 USB-串口 Device，再以 UART 连 E300 的合适串口；必要时 E300 侧再加 USB-串口。此为候选方案，不是已接通；电平、串口资源、SDK 波特率/适配配置都需确认。
- 自制板 USB VBUS 在原图没有 5 V 电源来源，若使用总线供电桥接器需另审受控的 5 V 供电、地和反灌边界，不能从 24 V 直接接入。
- E300 按用户要求保持独立供电，不在本任务评估飞机供电与 DC/DC。只需确认用于通信的物理端口及适配方案。

## 冲突与未执行项

- 参考工程已有 gPTP 实测，不意味着 USB Device 或 PSDK 已验证，本轮不更改其既有同步工作负载。
- UDC 为空、M1000_UDC 配置未启用是阻塞证据，但没有完成所有硬件/固件根因判断。
- 未对 USB 端口加电/切换、未测试 USB 枚举、未编译/运行 SDK、未测 24 V 或任何负载功率。
- 当前资料的跨库相对链接依赖两个项目保持现有相对位置；将来迁移应重新定位，不静默替换证据。

## 相关页面

- [[wiki/architecture/high-power-feasibility|总可行性评估]]
- [[wiki/sources/e300-usb-readonly-record|探测记录来源]]
- [[wiki/index|Wiki 索引]]
