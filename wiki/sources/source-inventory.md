---
title: Payload-SDK 来源清单
type: overview
status: draft
updated: 2026-09-09
sources: []
tags:
  - inventory
---

# 来源清单

2026-09-08 完成高功率申请定向摄取，逐文件登记见下节。没有计算全仓指纹或宣称全仓摄取完成；未列入本批的资料仍待摄取。已摄取只表示限定范围有来源摘要，不表示实物验证。

| 来源位置 | 证据角色 | 状态 |
| --- | --- | --- |
| [doc](../../doc/) | 随仓说明、参考设计和模板 | 待摄取 |
| [硬件原理图](../../hardware/SCH_Schematic2_2026-09-08.pdf) | 项目硬件资料，发布状态未确认 | 已摄取第 1 页供电/跳帽/USB 拓扑并视觉复核；实物与高速信号质量未验证 |
| [SDK 库与头文件](../../psdk_lib/) | SDK 声明与二进制身份 | 电源管理与版本头文件已摄取；其余待摄取 |
| [示例](../../samples/) | 特定版本工程实现 | 下表登记的电源/GD32 GPIO/Linux USB 文件已摄取；其余待摄取 |
| [工具](../../tools/) | 原有随仓工具 | 待摄取；Wiki 维护工具不作为技术来源 |
| [README](../../README.md)、[构建入口](../../CMakeLists.txt) | 仓库说明及构建配置 | 根构建入口平台分支已摄取；README 待摄取 |
| [LICENSE](../../LICENSE.txt)、[EULA](../../EULA.txt) | 随仓许可证文本 | 待摄取，不提供法律解读 |
| [LLM Wiki 理念](../../LLM%20Wiki.md) | 框架理念 | 保留原文，未摄取 |
| [E300 只读现场记录](../../test/raw/e300-usb-readonly-2026-09-08.json) | 经授权读取的设备能力证据 | 已摄取 8 条命令结果，不含账号、地址或凭据 |

默认变更检测覆盖 `doc/`、`hardware/`，以及未来实际存在的 `sources/`、`datasheets/`、`test/raw/`。不提前建立空目录。工程实现需用户指定路径，或明确要求全仓初始化摄取。

## 来源登记

以下 8 个文件已摄取，摄取日期均为 2026-09-08。每个来源笔记明确实际范围与不确定性，硬件页仍为 draft。首次登记无旧哈希；新身份如下，后续修订须保留历史。

| 仓库相对路径 | SHA-256 | 来源笔记及范围 |
| --- | --- | --- |
| `hardware/SCH_Schematic2_2026-09-08.pdf` | `ca31c43b26ab6d7a47e15bcb41963327e32dc4fd6ead4a45f7e1b3405426e3c2` | [[wiki/sources/custom-board-schematic|自制转接板原理图]] |
| `psdk_lib/include/dji_power_management.h` | `51cfcbcab2f3fd54e377a3b7b0fb09bfe805a8ed68abb33543ccfd65e4649b63` | [[wiki/sources/power-management-api|电源管理 API 声明]] |
| `psdk_lib/include/dji_version.h` | `c69d052d7b71f625192e9fd9b1436005f9db3d36dbb789d6166b96999cf8d66a` | [[wiki/sources/sdk-version|本仓 SDK 版本声明]] |
| `samples/sample_c/module_sample/power_management/test_power_management.c` | `e2a3ca208d122d4996abc948887b63bf8fc646a5a985ea6e00b88185a52c754f` | [[wiki/sources/power-management-sample|高功率申请示例分支]] |
| `samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c` | `4976d4b10c2843259e076379f790e81400ac9e674cf4bae704de81ea413d7768` | [[wiki/sources/gd32-high-power-pin|GD32 高功率 GPIO 示例]] |
| `samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.c` | `56b805bf27b10d3044455c63a02ac218883c63a42e3ae2524210d9211dec17fe` | [[wiki/sources/linux-usb-bulk-implementation|Linux USB Bulk 适配实现]] |
| `samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h` | `22e7e24e04da2b307d16c615a83a361edb9493f773304eab14b53daf220a1be4` | [[wiki/sources/linux-usb-bulk-config|Linux USB Bulk 端点配置]] |
| `CMakeLists.txt` | `18b663d7bf19f4d9b446dbebc3de84894d6cf30199e7d2e86685473a57f91a59` | [[wiki/sources/root-build-entry|根构建入口的平台范围]] |

另核查 DJI 官方在线接口、电源管理和开发套件说明，访问日期与链接保存在 [[wiki/architecture/high-power-feasibility|可行性评估]]。网页不是本地逐文件摄取身份，不计入上述 8 个文件，也没有虚构快照哈希。

## 后续现场记录

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-custom-req-open-core-trial-2026-09-09.json`，SHA-256 `702e506d1eb498a7a94b0e50820861821582e86d38712b47daabd74554d07c80`；[[wiki/experiments/e300-usb-uart-2026-09-09|移除 HIGH_PWR_REQ 跳帽对照]]，仍在识别阶段超时，无改善，已恢复关闭且未重启或申请电压。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-official-skyport-core-trial-2026-09-09.json`，SHA-256 `9924d475bfe1e8fcda193bf94eccc6085161944e4478b9e8b403bd3206f3efcf`；[[wiki/experiments/e300-usb-uart-2026-09-09|官方板 SkyPort V3 绑定阻塞]]，识别与载荷协商完成，认证芯片未绑定，45 秒后恢复关闭，未绑定或申请电压。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-official-e3-core-trial-2026-09-09.json`，SHA-256 `3faf39d95f9ef3011abde336595072d8b20ea9974b0f32c1e0b2c7eab51f9458`；[[wiki/experiments/e300-usb-uart-2026-09-09|官方板 E3 核心初始化通过]]，识别 M400/921600，初始化及基础信息返回 0，反初始化报 0xec，已恢复关闭且未申请电压。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-cp210x-aircraft-replug-2026-09-09.json`，SHA-256 `c7f5ccea89fefc8950e4043e758b98d8abc3a21010625cb8b11f4ddaac5b4341`；[[wiki/experiments/e300-usb-uart-2026-09-09|CP2102 接回飞机记录]]，五档隔离测试通过后恢复飞机连接，一次识别仍超时，已恢复关闭、未重启或申请电压。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-cp210x-pair-baud-2026-09-09.json`，SHA-256 `ebaab9ed37880b922f453faa091e6c3283984636e02de142af8d5048cbdf18e0`；[[wiki/experiments/e300-usb-uart-2026-09-09|双 CP2102 五档测试]]，双 USB 头接 E300 时 10 项、40960 字节全部匹配，恢复关闭、启动标识未变，未运行飞机探测或申请电压。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-cp210x-pair-identity-2026-09-09.json`，SHA-256 `7c73568822a5556dbc69adac2d2b5df4fce30e885a31f842c4b71e269877956a`；[[wiki/experiments/e300-usb-uart-2026-09-09|J3/J1 双适配器记录]]，原飞机侧移到 J1 后只读查询也为 CP2102，未打开串口或改配置。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-cp210x-flush-trial-2026-09-09.json`，SHA-256 `e563c4a5ecbeda57fbfeb2d874df186ff1064b31b34b45b13f156981982de25c`；[[wiki/experiments/e300-usb-uart-2026-09-09|J3 外置串口记录]]，接收缓存清理对照仍超时，本地只读查询为 CP2102，飞机端身份未回读。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-cp210x-core-trial-2026-09-09.json`，SHA-256 `1654441a36345717c5ea40987af3ec7a9372a8115ebc67e0a71e69d7d0cb387e`；[[wiki/experiments/e300-usb-uart-2026-09-09|J3 外置串口记录]]，双 CP210x 本地绑定正常，但核心识别 45 秒超时，已关闭恢复；被动接收静默不证明断线或实际波特率。

- 2026-09-09 追加工程观察（未单独来源摄取）：`test/raw/e300-usb-uart-bound-2026-09-09.json`，SHA-256 `a720add4d7c00e0b27628446d6307c2d2c84ad2ca0a50e4b13c155b8d01691b5`；以及 `test/raw/e300-ch340-core-trial-2026-09-09.json`，SHA-256 `d1573afc40329c7138e978867c51bc7fb8d125c820e1d31d3937eb585e14ae7f`。见 [[wiki/experiments/e300-usb-uart-2026-09-09|J3 外置串口记录]]：brltty 冲突修复、模块安装、双 CH340 探测超时与官方芯片范围核对。

- 2026-09-09 新增工程观察记录（尚未单独建立来源摄取笔记）：`test/raw/e300-usb-uart-driver-2026-09-09.json`，SHA-256 `66bcb9a42fa2ead99705a351a0fbe6e68de8739ebee8c192a20d00740b4f3e6e`；[[wiki/experiments/e300-usb-uart-2026-09-09|J3 外置串口记录]]，CH340 独立模块已临时加载，但绑定 EBUSY、无 ttyUSB，未运行 SDK。

- 2026-09-08 新增第 25 份本地来源：`test/raw/e300-uart4-dma-audit-2026-09-08.json`，SHA-256 `f2c490e359fb7a348891391832246d6e9da0845e97b5d2fe7f24c0344ac94a5e`；[[wiki/sources/e300-uart4-dma-audit-record|实际启动 Image 的 DMA 路径]]，只读核对失败先于串口注册，未选择 _CCA 值或再次试启动。

- 2026-09-08 新增第 24 份本地来源：`test/raw/e300-uart4-boot-trial-2026-09-08.json`，SHA-256 `d9608ed81f93fb96b99eb96b5b4c3e37ad753a1a122181ab23da27bd404af70d`；[[wiki/sources/e300-uart4-boot-trial-record|UART4 临时启动和回滚]]，表覆盖生效但 DMA mask 失败，已恢复原启动并清理独立文件，未收发 UART4 数据。

- 2026-09-08 新增第 23 份本地来源：`test/raw/e300-uart4-override-prepared-2026-09-08.json`，SHA-256 `0a32daa6f417fde821c3d06a8b4ee39e09e5f3111e8cfd20588b6c062c3fc4b5`；[[wiki/sources/e300-uart4-override-record|UART4 最小覆盖表准备]]，用户报告 1.8 V、COM5 恢复标记实收、候选逐字节保护与独立反编译通过，尚未试启动。

- 2026-09-08 新增第 22 份本地来源：`test/raw/e300-uart4-acpi-audit-2026-09-08.json`，SHA-256 `4989d43b1c630de08f26b0ec2a12708357a277b1c983f1b3e8d4003fa1cb2694`；[[wiki/sources/e300-uart4-acpi-record|UART4 的 ACPI 与电平]]，反编译确认 COM1 禁用，回查规格书 1.8 V 及参考底板无转换路径，未执行配置变更。

- 2026-09-08 新增第 21 份本地来源：`test/raw/e300-uart4-preflight-2026-09-08.json`，SHA-256 `3b6dc56055a6917bc06d0dfff50176622a588bdb8a676d5a31c6b23b28f133c6`；[[wiki/sources/e300-uart4-preflight-record|外置桥接 UART4 启动前检查]]，COM6 正常，但 E300 无 ttyMT 实例，尚未发送数据。

- 2026-09-08 新增第 20 份本地来源：`test/raw/e300-resumed-restart-2026-09-08.json`，SHA-256 `1db6ff62bab05a42495e1c847bfe2645f9c5133a488b62caedacc221352a24a0`；[[wiki/sources/e300-resumed-restart-record|恢复测试后再次重启]]，已停止重载和重试，未获得本轮 SDK 阶段日志。
- 2026-09-08 新增第 19 份本地来源：`test/raw/e300-uart-status-fix-2026-09-08.json`，SHA-256 `ba838b3eda8781818c36fbc5e992672c72ab253aebb072ed9984f51401c2aea9`；[[wiki/sources/e300-uart-status-fix-record|回调修正与零接收试验]]，该次区间启动标识未改变，不代表后续重启试验。

- 2026-09-08 新增第 18 份本地来源：`test/raw/e300-identify-restart-2026-09-08.json`，SHA-256 `0c238f58b3fa38aaf1657d0804cbc4bdb49b74ad607dbcb4d782f9a6a2c37d06`；[[wiki/sources/e300-identify-restart-record|识别推进与重启观察]] 记录 M400/921600 识别、状态回调错误及随后的未知原因重启，当前测试暂停。

- 2026-09-08 新增第 17 份本地来源：`test/raw/e300-pc-baud-test-2026-09-08.json`，SHA-256 `5ab0f6193ebe0065ed6c3cc0fd1799b47c550a45859754b488d756ddedf5befc`；[[wiki/sources/e300-pc-baud-record|电脑主机三档波特率对照]] 记录 115200/460800/921600、每方向 4096 字节匹配与清理状态，不覆盖飞机端失败记录。

- 2026-09-08 新增第 16 份本地来源：`test/raw/e300-psdk-replug-trial-2026-09-08.json`，SHA-256 `b2657d50fd13bafd72ceaca7398f17e3151094dd54df84ed2b2189b1e42c3985`；[[wiki/sources/e300-psdk-replug-record|J10 重插后记录]] 包含连接识别日志、软件波特率与内核 RX 0，不覆盖前次观察，也不等同实际波特率测量。

- 2026-09-08 新增第 15 份本地来源：`test/raw/e300-psdk-core-trial-2026-09-08.json`，SHA-256 `0803e8800c5b3caad7fdc9c86dafbf6e1998f1f9bd76731616370baf44e00408`；[[wiki/sources/e300-psdk-core-trial-record|核心通信试验来源]] 记录首次 0xec、重启后保护拒绝、模块恢复与后续零接收超时。没有保存用户配置内容或将历史成功等同本轮通过。

- 2026-09-08 新增第 9 份本地来源：`test/raw/e300-usb-readonly-2026-09-08.json`，SHA-256 `2d67ca29c3f396e272b2c20b7744a5c69126b31d328168b9fbf3106e2821528e`；旧哈希无，首次记录 8 条只读命令。
- [[wiki/sources/e300-usb-readonly-record|来源笔记]] 与 [[wiki/experiments/e300-usb-readonly-2026-09-08|验证记录]] 已建立；未申请电压，未进行 PSDK 通信。
- 相邻 MTT_E300 工程仅作跨库资料回查，未修改或复制原始文件；引用路径、实际复核页码及核查哈希见验证记录，不计入本仓逐文件摄取身份。
- 后续 J3 截图已定位到跨库 602-10035-0000-300.pdf，复核第 9、10、32 页；原文件哈希和两组通道追踪表见 [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 验证页]]，不新增本仓正式来源文件身份。

- 2026-09-08 接线后新增第 10 份本地来源：`test/raw/e300-usb-connected-2026-09-08.json`，SHA-256 `da4559fc286671c081af824a31134cb60a3043cacbc7b5cbbe896e1235e61b23`；[[wiki/sources/e300-usb-connected-record|来源笔记]] 记录 6 条命令，UDC 仍为空、无外接 USB 枚举和相关串口，不覆盖第 9 份记录。

## 导航

- 2026-09-08 新增第 14 份本地来源：`test/raw/e300-runtime-console-detach-2026-09-08.json`，SHA-256 `bc86ca45251a67c7c950465711938a2079b5dc61ac11fcbb28d47f6651158977`；[[wiki/sources/e300-runtime-console-record|运行期适配记录]] 包含代码指纹、模块检查、双向标记与日志对照。新工程工具位于 tools/e300_uart_console/，不计为原 8 文件批次或新的只读摄取任务。

- 2026-09-08 新增第 13 份本地来源：`test/raw/e300-j10-uboot-console-trial-2026-09-08.json`，SHA-256 `98ca855982572318ade8c190addd021835b055e5a90f66745322feb1e4591a98`；[[wiki/sources/e300-j10-uboot-trial-record|J10/U-Boot 试验来源]] 记录电脑串口成立、临时参数未释放 console 及恢复状态。没有保存完整启动日志、设备序列号或网络配置。

- 2026-09-08 新增第 12 份本地来源：`test/raw/e300-ttyS0-getty-masked-2026-09-08.json`，SHA-256 `8af46bb455dc4559f46377f751203e29eb0d8e44ce57b95448875c1a52925804`；[[wiki/sources/e300-getty-masked-record|停用串口登录后的回读]] 记录 5 项结果，确认仅 getty 停用、内核 console 仍在，不覆盖之前的状态记录。

- 2026-09-08 新增第 11 份本地来源：`test/raw/e300-driver-console-2026-09-08.json`，SHA-256 `5bbbde49f0a1ae21ecf2c77483f277ab75b8438807c893e3361f4060c4e77de8`；[[wiki/sources/e300-driver-console-record|驱动与控制台来源笔记]] 记录 UDC/PHY/控制台只读核查，不覆盖前两份记录。跨库参考原理图同次追加视觉复核第 34、35 页 J2/J10，原文件哈希不变。

- [[wiki/index|Wiki 索引]]
- [[wiki/project-overview|项目概览]]
- [[wiki/log|操作日志]]
