---
title: Payload-SDK Wiki 索引
type: overview
status: draft
updated: 2026-09-09
sources: []
tags:
  - index
  - payload-sdk
---

# Payload-SDK Wiki

持久化项目知识库入口。已摄取首批 8 个本地文件及后续 17 份 E300 检查记录，并补充核查官方接口说明。2026-09-09 官方板/E3/双 CP2102 路线核心初始化和飞机信息读取成功，反初始化报 0xec；自制板/SkyPort V3 路线仍未通过，尚未申请电压或进行飞行验证。

**旧 J10 路线保持停用：曾发生重启，console 恢复后未再重载注销模块。见 [[wiki/sources/e300-resumed-restart-record|历史重启记录]]。当前使用 J3 外置桥接器，不沿用旧路线的运行状态。**

## 从这里开始

排查已按用户要求暂停。官方板 SWITCH 附近候选器件据用户报告为三脚、丝印 V8SOF，型号未知，不能将其认定为完整双路 USB 数据选择器；尚未定位官方板 D+/D- 的实际切换器件。自制板识别问题未解决，未申请或验证 24 V。

官方板通路补充：用户报告 12 号 USB_D 到 1 号口未测通，高速对经 TUSB1002A。TI 手册确认该芯片只处理 SuperSpeed，不是 CP2102 的 USB 2.0 D+/D- 转换器；官方板 D+/D- 存在 Onboard/Expand 选择功能，具体开关型号待丝印/原理图。不能把自制板被动通路的蜂鸣判据直接用于官方板有源通路。见 [[wiki/experiments/e300-usb-uart-2026-09-09|官方板 USB 路径边界]]。

最新对照：用户移除自制板 JUMP 3–4、保留 ONLINE 7–8 后，一次识别测试仍在 45.008 秒超时，没有改善；已停止恢复、无重启或电压申请，不支持持续外部下拉为唯一原因。当前 JUMP 3–4 仍移除，下一步断电补测跨 U38 到 USB 插座触点的完整 D+/D-，不只测 CN1 到 U38 前段。见 [[wiki/experiments/e300-usb-uart-2026-09-09|移除请求跳帽对照]]。

CN1 最新复核：原理图 1–45 脚网络分配与 DJI 同轴定义逐项一致，含 12=D+、13=D-；用户报告 CN1 到 U38 导通。尚缺 PCB 封装与实物触点编号映射，下一步检查 1/45 方向和 12/13 焊盘，不把通断正常当作物理脚位正确。完整核对表见 [[wiki/sources/custom-board-schematic|CN1 原理图复核]]。

当前任务调整：用户要求先解决自制板，不推进绑定。CP2102 使用 USB 2.0 Full-Speed D+/D-，优先检查 CN1 → U38 → USB2 的通断、焊接/封装及 D1/D2，再看 PCB/叠层；不先归因于独立 USB 3.2 SuperSpeed 走线阻抗。hardware/ 当前仅有原理图，PCB 待提供。见 [[wiki/experiments/e300-usb-uart-2026-09-09|自制板 USB 排查范围]]。

最新结果：已改为 SkyPort V3 → 官方板 Expand/12 → 双 CP2102 → E300 J3。识别 M400、载荷口 1、SkyPort V3 和 921600，载荷协商完成，但认证芯片未绑定，45 秒后已停止恢复。下一步保持接法、连接飞机调试 USB 到电脑，准备 Assistant 绑定；当前程序不在运行，未绑定或申请电压。E3 对照此前 Core_Init / GetBaseInfo 均返回 0、Core_DeInit 报 0xec。见 [[wiki/experiments/e300-usb-uart-2026-09-09|官方板两条路径对照]]。以下各段保留此前检查时点，不表示当前接法。

当前路线为 E300 J3 外置 CP210x 对接桥接器，不再启用 UART4。用户已将双 CH340 更换为 CP210x，本地 ttyUSB0 由原系统驱动自动绑定，但核心识别仍在 45 秒后超时，已关闭恢复且未重启或申请电压。下一步核对当前飞机状态和飞机侧枚举，不把本地串口或少量 RX 当作握手成功。见 [[wiki/experiments/e300-usb-uart-2026-09-09|J3 外置串口记录]]。

补充：用户已确认飞机供电/挂载。补齐官方 HAL 的接收缓存清理后对照仍识别超时；本地只读芯片查询返回 CP2102，飞机侧实际身份待回读，暂停盲重试。

当前接线更新：原飞机侧 USB 头暂接 E300 J1（ttyUSB1/1-2），原 J3 保留（ttyUSB0/1-3）。两端只读查询均为 CP2102、10c4:ea60；尚未证明飞机主机侧的配置或握手，不能在当前双 USB 接 E300 状态运行飞机探测。

最新定量验证：上述接法下五档 115200/230400/460800/921600/1000000 双向各 4096 字节全部匹配，共 10 项、40960 字节。参数恢复、端口关闭，启动标识未变，未运行 SDK 或申请电压。待将 J1 端接回自制板后继续调查飞机主机侧链路；本测试不等同飞机枚举或握手成功。见 [[wiki/experiments/e300-usb-uart-2026-09-09|双 CP2102 五档测试]]。

接回飞机后的最新结果：用户已恢复原 J1 端到自制板，一次 45 秒核心探测仍识别超时；已退出恢复、未重启或申请电压。不再重复相同扫描，下一步寻求官方开发板已知正常对照；当前没有飞机 USB 主机侧读回证据。见 [[wiki/experiments/e300-usb-uart-2026-09-09|接回飞机对照记录]]。

官方板对照准备：用户将 12 号口接电脑；已核实它是飞机 USB 扩展通道，Expand 模式应接 USB Device，不是电脑调试口。拟保留 E300 和 CP2102，仅换官方板转接路径，待确认其 1 号同轴接口连接；未操作固件或电压。见 [[wiki/experiments/e300-usb-uart-2026-09-09|官方板对照接法]]。

最新只读分析：实际启动 Image 已核对 DMA 检查失败早于串口注册；缺少适用 _CCA 是有力解释，但不能据此猜测缓存一致性取值。等待完整 UART4 板级配置证据，未再次重启或改线。见 [[wiki/sources/e300-uart4-dma-audit-record|实际内核 DMA 路径]]。

最新替代路线：用户确认电平转换后的 TX/RX 为 1.8 V，UART4 外置桥接器接电脑 COM6，J10/COM5 作控制台。获准试启动已实际加载最小表、UART4 状态变为 15，但驱动设置 DMA mask 失败，尚无串口节点和收发。已通过正常重启恢复原表/参数，移除启动分区测试文件，COM5 助手已关闭。见 [[wiki/sources/e300-uart4-boot-trial-record|DMA 错误与回滚]]。

- [[wiki/project-overview|项目概览]]：仓库身份、目录职责与知识边界。
- [[wiki/sources/source-inventory|来源清单]]：资料位置及待摄取状态。
- [[wiki/log|操作日志]]：初始化、摄取、查询回写与检查的追加记录。

## 分类

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]：M400 / SkyPort V3、跳帽与供电边界、USB 角色、申请 API 和待确认条件。状态 draft，不是操作授权。
- [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 只读 SSH 与 J3 接口核对]]：用户确认 J3 靠上孔且仅接一根 USB；CON2/CON3 分别接模组 USB2/USB3，接线后 UDC 仍为空。E300 独立供电，仅以自制板 VCC/GND 测得 24 V 验收。
- [[wiki/sources/source-inventory|逐文件来源登记]]：原理图、电源 API、示例、版本及 Linux USB / 构建入口的来源笔记。

其他分类后续按实际证据创建，不为尚不存在的专题创建链接。

接口核查：J10 为板载 CP2102N USB-串口 Device，J2 为下载口。用户负责 USB 5 V 边界，UART7/ttyS0 控制台已按下述试验释放；飞机枚举仍待验证。详见 [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 接口验证记录]]。

串口准备历史：已通过 [[wiki/experiments/e300-runtime-console-detach-2026-09-08|运行期最小模块适配]] 注销 ttyS0 console；日志隔离、卸载回滚与重载曾实测通过。最新重启后模块未加载，不能沿用此前的已释放状态，不宣称永久静默。

通信历史包含 0xec、零接收超时和识别 M400 / 921600 后的状态回调错误；不能用早期“未识别”覆盖后来的识别结果。最新重启试验仅回传启动前检查通过，具体 SDK 阶段未知，尚无完整初始化成功或电压申请。见 [[wiki/experiments/e300-runtime-console-detach-2026-09-08|通信试验与验证边界]]。

## 维护入口

电脑对照历史：J10 接维护电脑时，115200、460800、921600 三档两个方向各 4096 字节均匹配；之后用户已接回自制板。该测试证明电脑主机下链路可用，不代表 M400 桥接器设置或 PSDK 初始化通过。见 [[wiki/sources/e300-pc-baud-record|三档波特率记录]]。

飞机调试口：用户更新 Assistant 后，Windows BULK 接口均为 OK；Enterprise Series 已识别 M400 / V17.02.5007，PSDK 页面提示未发现设备，无波特率读回入口。此时 SDK 程序已停止，不把页面提示当作 USB 枚举失败的直接证据。见 [[wiki/experiments/e300-runtime-console-detach-2026-09-08|Assistant 连接诊断]]。

桥接器设置核查：CP2102N 的主机侧参数走 USB 控制请求，当前 E300 UART SSH 链路无法直接读回；已核查官方命令与 CP2102N 旧波特率命令兼容性边界，等待飞机侧诊断入口，不宣称取得实际值。见 [[wiki/experiments/e300-runtime-console-detach-2026-09-08|主机侧可观测边界]]。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|运行期控制台注销与回滚]]：当前 Linux 串口准备状态、实际检查、限制和恢复方式。

- [[wiki/experiments/e300-j10-console-trial-2026-09-08|J10 串口及控制台释放试验]]：电脑枚举和串口链路已确认；RAM 临时 console=tty0 试启动后 ttyS0 仍由 ACPI/SPCR 注册，试验未通过，已恢复原启动环境且未写 Flash。

- [知识库规范](../AGENTS.md)
- [手动摄取技能](../.agents/skills/payload-sdk-ingest/SKILL.md)
- [LLM Wiki 理念](../LLM%20Wiki.md)
