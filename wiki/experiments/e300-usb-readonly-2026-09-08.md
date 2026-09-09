---
title: E300 作为 24 V 申请平台的只读验证
type: experiment
status: draft
updated: 2026-09-08
sources:
  - test/raw/e300-usb-readonly-2026-09-08.json
  - test/raw/e300-usb-connected-2026-09-08.json
  - test/raw/e300-driver-console-2026-09-08.json
  - test/raw/e300-ttyS0-getty-masked-2026-09-08.json
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

## 接线后复查

2026-09-08 用户报告自制板 USB2 接口已经接到 E300。USB2 是原理图位号，不代表所用连接速度。随后用户确认 E300 端为 USB-A、M400 已开机，并提供 J3 截图；后续实物照片与说明将插口描述为 J3 靠上的 USB-A，当前只插这一根 USB。物理位置按用户报告记录，不据此猜测 CON2/CON3 与机壳上下孔的对应关系，也不再要求用户为当前评估拔插定位。这些补充不改写已经保存的命令返回。

复查 lsusb/lsusb -t 仅见根集线器；UDC 仍为空，四个 role 为 none，未出现 ttyUSB/ttyACM/ttyGS。因此物理接线报告尚未转化为可用 PSDK 通信证据。对飞机 Host 路径，关键仍是 E300 Device 是否成立，不能只凭 lsusb 没有飞机条目作判断。

原始记录为 [接线后命令返回](../../test/raw/e300-usb-connected-2026-09-08.json)，身份及诊断限制见 [[wiki/sources/e300-usb-connected-record|接线后来源笔记]]。没有切换角色、修改系统或申请电压。

## MTT_E300 参考工程回查

### J3 通路核对

用户截图与 [参考底板原理图 602-10035-0000-300.pdf](../../../../MTT_E300/datasheet/E300/E300模组对应底板资料260306/模组开发资料_2026-03-06/01_SOM模组底板参考设计原理图和PCB/01_原理图/01_Design_Entry_HDL/602-10035-0000-300.pdf) 第 9 页的 J3 相符。2026-09-08 核查 SHA-256 为 `fb36040c76f54cc0ac9a46034f8d1f21b035af007dc9eaef89e4b48dd4d73547`。本次完整视觉复核第 9、10、32 页；图签 PCB REV 为 A03、BOM REV 为 B，带有通用参考原理图/装配和 BOM 未最终确定的说明，不据此确认实物板版本。

| J3 逻辑单元 | 数据通路 | VBUS 通路 |
| --- | --- | --- |
| VBUS1 / DN1 / DP1，U1/U2/U3 | CON3_USB_DM/DP 经 R16/R15 到 USB3_DM/DP；第 32 页到模组连接器 J15 的 165/167 脚 | USBA_CON3_VBUS，经第 10 页 U80 由 V5_DUAL 供电 |
| VBUS2 / DN2 / DP2，U10/U11/U12 | CON2_USB_DM/DP 经 R8/R7 到 USB2_DM/DP；第 32 页到 J15 的 171/173 脚 | USBA_CON2_VBUS，经第 10 页 U55 由 V5_DUAL 供电 |

- 第 9 页两组数据线路为模组通道转接，含零欧电阻、ESD 和 SuperSpeed AC 耦合路径；未见 MCU 或 USB-串口桥。
- 第 10 页 U55/U80 标注 GS7615STDE-R，两个 EN 接到 FINGER_PS_OFF_N；不能把这个公共电源控制网络当成已证实的独立 USB 数据角色切换机制，也不能为试验单口而盲目修改。
- 上表中的第一/第二逻辑单元不能直接推定为机壳的上/下孔；若将来需要单控制器映射，仍需装配图或经过授权的端口定位。
- 对当前评估，两组都落到模组普通 USB 通道，且此前目标机没有注册 UDC。用户已说明仅连接这一根 USB，因此当前不是多个设备之间的选择歧义；不要求用户再分清这两个插孔，也不把“换 J3 另一个孔”当作解决 Device 链路的办法。
- 这是参考设计与现有软件状态的联合判断，不证明芯片物理上绝无 Device 能力；原生 Device 方案仍需厂商驱动/固件和接口电气规则支持。
- 本轮只读资料，没有再次操作目标机、插拔试验或切换角色。Poppler 提示缺少 Symbol/ArialUnicode 字体，本次使用的网络名、引脚号和连线已在渲染图中复核。

### J2 与 J10：不能混为原生 Device 口

用户提出改接 J2 或 J10 后，追加视觉复核同一参考原理图第 34、35 页，文件身份不变，派生图保存在 wiki/.tmp/high-power/。结论仅适用于该参考设计，实物版本和装配仍待验证。

| 接口 | 原理图证据 | 当前用途判断 |
| --- | --- | --- |
| J2，第 34 页 | 标注 DOWNLOAD TO SOC；D+/D- 经 R28/R34 接 USB_DP/DM，即模组下载专用通道；VBUS/CC 未接功能网络 | 烧录用途，不能据此认为运行 Ubuntu 时能提供 PSDK Device；不按 S1、不进入下载模式 |
| J10，第 35 页 | D+/D- 经 R30/R36 到 U10 CP2102N-A02-GQFN24R；TXD 经 R88 接 UART7_RX，RXD 经 R89 接 GPIO15_UART7_TX | 板载 USB-串口桥，USB 侧为 Device；不依赖 M1000 原生 UDC，是更直接的候选通信路线 |

J10 的 VBUS 接 V5_USB_UART，再接 U10 VREGIN，并经 R168/R169 分压送 VBUS 检测；VIO 另由 V3P3_S3 供电。不能把 VIO 已有电视为整颗桥接器已有电。自制板 USB2 的 VBUS 没有可见 5 V 来源，因此仅把同一根线改到 J10，仍不能保证桥接器供电或枚举。USB VBUS 不能接自制板的 24 V VCC；需先核实实物 5 V 供电路径和反灌边界。本页不指示临时飞线加电。

[摩尔线程 UART 文档 1.5.0](https://docs.mthreads.com/e300/version-1.5.0/e300-doc-online/hardware_drivers/uart/) 明确 UART7 对应 ttyS0。只读现场检查发现 /proc/consoles 的 ttyS0 已作为内核控制台，serial-getty@ttyS0.service 也在运行。按该文档与参考设计，J10 候选路线需要释放这一路串口，不能让登录提示/内核日志与 PSDK 数据混用；不能只停止 getty 就假定内核 console 已消失。实际固件映射仍须核对，未做任何停服务、启动参数修改或重启。

候选链路是：飞机 USB Host -> 自制板 USB2 数据线 -> J10 的 CP2102N Device -> E300 UART7 -> PSDK UART HAL。飞机侧对具体 CP2102N VID/PID/固件的识别、串口波特率及应用初始化仍未实测；E300 自己不需要出现 ttyUSB0 才能使用这一路板载 UART。

### 原生 Device 驱动核查补充

新观察见 [[wiki/sources/e300-driver-console-record|驱动与控制台来源]]。M1000_UDC 未启用、没有发现对应已安装模块、UDC 为空；已存在的 PHY 驱动和 role-switch 不等于可用 UDC。因此当前 J3 直连路线不是仅补 libusb 或 gadget 描述就能成立。

公开厂商 AOSP 仓库的 [t035/init.common.usb.rc](https://gitee.com/MooreThreads-AI-SOC/aosp-device-mthreads-m1000/blob/gitee-mt-14-AD1A.240905.004/t035/init.common.usb.rc) 含 configfs/FunctionFS gadget 配置和 set_udc 服务入口。访问日期 2026-09-08，API 返回 blob SHA-1 为 411911aa001e41474e33eb20c3bf8623d4ee2346；这是远程文件版本标识，不是本地来源 SHA-256。它只证明该 AOSP 工程有 Device 配置路径，不证明当前 Ubuntu、J3 或当前固件可用。不能断言 M1000 芯片永久不支持 Device。

[厂商 Linux SDK 环境文档 1.5.0](https://docs.mthreads.com/e300/version-1.5.0/e300-doc-online/install/sdk_environment/) 将配套 kernel/firmware 源码列在 NDA 资源内。本轮未获取私有代码，公开硬件配置及发布说明未给出可直接用于当前 J3 的 Device 操作办法，故不尝试切换或替换内核。以上在线材料仅回查，不虚构本地摄取身份。

### 模组资料背景

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
- 串口桥接路线优先核查板载 J10 CP2102N，不再默认需要购买外置桥接器；仍须解决桥接器 USB 5 V 供电、UART7 控制台占用及飞机枚举兼容性。未处理前不把换线视为可运行。
- 自制板 USB VBUS 在原图没有 5 V 电源来源，若使用总线供电桥接器需另审受控的 5 V 供电、地和反灌边界，不能从 24 V 直接接入。
- E300 按用户要求保持独立供电，不在本任务评估飞机供电与 DC/DC。只需确认用于通信的物理端口及适配方案。

## 冲突与未执行项

- 参考工程已有 gPTP 实测，不意味着 USB Device 或 PSDK 已验证，本轮不更改其既有同步工作负载。
- UDC 为空、M1000_UDC 配置未启用是阻塞证据，但没有完成所有硬件/固件根因判断。
- 未对 USB 端口加电/切换、未测试 USB 枚举、未编译/运行 SDK、未测 24 V 或任何负载功率。
- 当前资料的跨库相对链接依赖两个项目保持现有相对位置；将来迁移应重新定位，不静默替换证据。

## 授权后的串口准备

用户随后报告 J10 已连接，USB 5 V 由其负责，不再要求讨论供电方案。该报告只更新接线及分工，不证明桥接器已经供电或被飞机枚举。随后用户明确授权处理串口占用及必要的系统配置。

本轮确认 ttyS0 的 iomem_base 为 0x47000，与厂商 UART7 地址一致。当前启动命令行有 console=ttyS0,115200n8。机器没有 /boot/grub/grub.cfg；只读挂载 NVMe 启动分区后发现 extlinux/extlinux.conf，但其 append 内容与当前命令行不同，不证明当前启动链消费该文件。未盲改 GRUB 或 extlinux。厂商 [U-Boot 配置文档 1.5.0](https://docs.mthreads.com/e300/version-1.5.0/e300-doc-online/boot_system_config/uboot/) 说明启动参数由环境配置组织，环境保存于 QSPI；本机未发现 fw_printenv/fw_setenv，/proc/mtd 也未列出可访问分区。尚未获得当前固件的实际环境，不猜测 Flash 偏移或直接写入。

已执行并核实：

- 在设备 /var/backups/psdk-ttyS0-20260908/ 保存 extlinux.conf.original 和 grub.original；未修改这两份配置的原文件。SHA-256 分别为 e0142f2ff81acc49ae72da9aa5f813e7cbd3fc2ca5ba7e8e841fcbea6d195b32、70a5d423ad2dd3d95f1c30eced7848bf6d79b474e8412f2b52d436651f0cde32。备份只留在设备，不复制包含分区标识的配置到 Wiki。
- systemctl mask --now serial-getty@ttyS0.service：停用并持久屏蔽该登录实例；修改前 /etc/systemd/system/ 下无同名覆盖文件，服务为 enabled-runtime，来自 generator。
- 重连回读得到 inactive、masked；/proc/consoles 仍列 ttyS0。因此内核控制台仍未释放，不能让 PSDK 占用该口。来源见 [[wiki/sources/e300-getty-masked-record|变更后回读]]。
- 临时只读挂载点已卸载并移除；SSH 可重连。没有重启、变更内核日志级别、修改 Flash、发送串口数据、启动 SDK 或申请 24 V。

回滚这次服务变更：在设备执行 sudo systemctl unmask serial-getty@ttyS0.service，再执行 sudo systemctl start serial-getty@ttyS0.service；恢复串口登录，不更改原有内核启动参数。

下一步需要在与飞机断开的条件下，通过 J10 接电脑访问 U-Boot，先读取实际环境和启动命令，再制定可回滚的 console 参数调整。未确认环境前不重启进入无人看守的固件操作。本次状态为部分完成，不是通信就绪。

## 相关页面

- [[wiki/experiments/e300-j10-console-trial-2026-09-08|后续 J10 接电脑与 U-Boot 试验]]：已完成串口验证及临时启动试验，未通过释放条件，原启动环境已恢复。本页此前的“未重启”只指当时批次。

- [[wiki/architecture/high-power-feasibility|总可行性评估]]
- [[wiki/sources/e300-usb-readonly-record|探测记录来源]]
- [[wiki/index|Wiki 索引]]
