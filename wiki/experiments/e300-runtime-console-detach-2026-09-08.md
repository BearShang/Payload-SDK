---
title: E300 运行期注销 ttyS0 控制台的最小适配
type: experiment
status: draft
updated: 2026-09-08
sources:
  - test/raw/e300-runtime-console-detach-2026-09-08.json
  - tools/e300_uart_console/psdk_uart_console.c
  - tools/e300_uart_console/Makefile
  - tools/e300_uart_console/validate_uart.py
  - tools/e300_psdk_probe/main.c
  - tools/e300_psdk_probe/CMakeLists.txt
  - tools/e300_psdk_probe/test_preflight.py
  - test/raw/e300-psdk-core-trial-2026-09-08.json
  - test/raw/e300-psdk-replug-trial-2026-09-08.json
  - test/raw/e300-pc-baud-test-2026-09-08.json
  - test/raw/e300-identify-restart-2026-09-08.json
  - test/raw/e300-uart-status-fix-2026-09-08.json
  - test/raw/e300-resumed-restart-2026-09-08.json
  - psdk_lib/include/dji_error.h
tags:
  - e300
  - uart
  - kernel
---

# E300 运行期注销 ttyS0 控制台的最小适配

**最新状态：状态回调已修正并经单元测试。恢复试验先零接收超时且未重启；随后电脑配置并接回后的 SDK 试验再次重启，启动标识变化已确认，未回传具体 SDK 阶段。当前 console 恢复、适配模块和测试进程不在，不再重载或重试。以下“当前”等描述仅代表各自历史试验时点。**

## 范围与结果

用户授权继续实施可回滚的最小内核适配。J10 全程接维护电脑，不接飞机。本轮未重启、替换 Image、刷固件、改 ACPI 表或运行 PSDK。

**当前启动中的 ttyS0 内核控制台已注销，UART 驱动仍工作。** 已实测 115200 8N1 双向收发、日志隔离、模块卸载恢复和重新加载。模块目前保持加载，getty 仍被屏蔽。本结果仅是 Linux 串口准备，不是飞机枚举、PSDK 初始化或 24 V 验收。

## 最小实现

[实现目录](../../tools/e300_uart_console/) 包含 psdk_uart_console.c、Makefile、validate_uart.py 与英文维护说明。设备侧使用独立的 psdk-uart-console-20260908 工作目录；不在 Wiki 保存带账号的部署路径或连接信息。

- 模块使用导出的 console_list_lock、unregister_console 和 register_console；不访问任意内存地址或篡改函数指针。
- 限定 ARM64、6.6.10、内建 8250 驱动、唯一 ttyS0，并检查标准 8250 的 setup/write/exit 回调符号；默认 dry_run=true，不改变控制台。
- 明确传入 dry_run=0 且 allow_last_console=1 才允许注销当前最后一个 console；内核日志仍保留在缓冲区，串口及 /dev/console 不再承担该输出目的地。
- 初版对 exit 回调为空的保守限制拒绝执行；确认当前回调为 univ8250_console_exit 后，回查 [Linux 6.6.10 8250 core](https://raw.githubusercontent.com/gregkh/linux/v6.6.10/drivers/tty/serial/8250/8250_core.c) 及 [8250 port](https://raw.githubusercontent.com/gregkh/linux/v6.6.10/drivers/tty/serial/8250/8250_port.c) 的标准退出/恢复路径，改为只接受已检查的准确回调名。不是忽略异常强制执行。
- 现场头文件和导出符号匹配此次构建及试运行。实际 Image 与 /boot 镜像不同的限制仍有效，不宣称取得厂商完整源码或证明所有 ABI 一致。
- Kbuild W=1 构建成功；唯一报告的构建警告为编译器版本差异：内核 GCC 11.2.0、现场 GCC 11.4.0。未强制加载，不为消除警告修改工具链。

## 实测

| 检查 | 结果 |
| --- | --- |
| 默认 dry-run | 找到 ttyS0，控制台列表不变 |
| 最后一个 console 保护 | 未传 allow_last_console 时返回 EBUSY，列表不变 |
| 实际注销 | /proc/consoles 为空；ttyS0 节点保留；root fuser 未发现 ttyS0 或 /dev/console 持有者 |
| UART 收发 | 115200 8N1 无流控；PC 与 E300 的固定标记逐字节匹配；最终构建再次通过 |
| 卸载回滚 | rmmod 后 /proc/consoles 恢复启用的 ttyS0；标记脚本在有 console 时拒绝运行 |
| 再次加载 | console 注销再次成功，UART 收发仍通过 |
| 日志隔离 | 等级 3 的对照标记在恢复 console 时从 COM5 收到；注销后 dmesg 仍可见标记，COM5 的 3 秒观察为 0 字符 |
| SSH 与现有状态 | SSH 可重连；taint 原值/最终值均为 4096；未改 ptp4l，最终仍在 start-pre 等待 |

等级 4 的首次日志标记没有构成有效对照，因为当前 console_loglevel=4 不输出同级日志；已用等级 3 重做，不用该首次结果支持隔离结论。临时测试没有改 console_loglevel。

来源身份见 [[wiki/sources/e300-runtime-console-record|记录来源]]。最终模块 SHA-256 为 c9304e05ac02b56e730a40e9d2969ac31422e6de39d2113d65e2f38970a45b66，二进制仅保留在设备，未复制进 Wiki。

## 使用与恢复

当前无需再加载，可在保持 E300 开机的前提下进入下一阶段通信准备。标记测试程序和本机串口助手均已退出，未留串口占用进程。

没有安装自动加载服务。重启会恢复原来的内核串口控制台，getty 仍保持 masked；重启后必须先重新检查和加载模块，不能直接运行 PSDK。早期固件和启动日志仍使用 UART7，这个模块不解决整个上电过程的静默问题。

回滚前先断开飞机并停止串口程序，在设备上执行 sudo rmmod psdk_uart_console，然后检查 /proc/consoles。此过程可能向 J10 重放内核日志。恢复 getty 是另外一步，按 [[wiki/experiments/e300-usb-readonly-2026-09-08|先前记录]] 操作；本轮未更改它。

若之后使用新的内核、镜像、头文件或不同板卡，必须重新审查，不能沿用此测试结论。没有验证其他波特率、休眠/恢复、异常故障路径、飞机识别或 SDK 会话。整个项目验收仍仅为用户测得自制板 VCC/GND 为 24 V。

## 接回自制板后的通信准备

用户随后确认 J10 已接回自制板。复查 console 仍已注销、模块保持加载，getty 为 masked/inactive/dead；没有再次发送维护电脑用的串口标记。

新增 [最小核心验证程序](../../tools/e300_psdk_probe/README.md)，复用本仓库 SDK 3.16.0 ARM64 静态库与 Linux OSAL，只提供 UART 注册、DjiCore_Init、DjiAircraftInfo_GetBaseInfo 和 DjiCore_DeInit。源码不调用电源申请、飞控模块或 DjiCore_ApplicationStart，也不修改串口权限和启动配置。

工程检查：E300 上编译、链接成功；唯一构建警告来自既有 OSAL 的未使用 stackSize 参数。七项配置保护检查通过，全部使用不打开 UART 的 --check 模式；虚构测试字段只验证长度和拒绝逻辑，未用于 SDK 初始化。尚未执行 --run，不把编译成功视为飞机通信成功。

准备阶段检查的 Linux Jetson 示例应用信息为占位符。随后用户指定既有应用信息并说明曾在官方 E-Port V2 开发板成功申请电源；这是用户报告的历史结果，不证明当前硬件通过。凭据仅在内存中读取、经 SSH stdin 传送，不记录于 Wiki。实际通信波特率、飞机对 CP2102N 的枚举、应用认证和 24 V 均仍待验证；115200 的电脑侧测试不证明飞机侧波特率。

## 首次核心通信尝试

详见 [[wiki/sources/e300-psdk-core-trial-record|选择性试验来源]]。配置波特率为 460800，SDK 实际自行切换多个速率。首次 DjiCore_Init 返回 0xec，累计发送 1406 字节、收到 1861 字节，未取得机型/适配器。[dji_error.h](../../psdk_lib/include/dji_error.h) 的 DJI_ERROR_SYSTEM_MODULE_RAW_CODE_SYSTEM_ERROR 将 0xec 定义为通用系统错误；不能据此宣称密钥无效。

两次尝试之间发现设备 uptime 仅 144 秒，console 恢复、模块不在；任务没有发起重启，原因未知。此时 --run 被保护检查拦截，未打开 UART。设备时间与 journal 历史不一致，旧关机条目不能归属于此次重启。构建出现时钟偏差警告，使用 clean-first 明确重编两份 C 源文件并重新链接，没有修改设备时钟。

再次核对模块哈希和内核后，重新加载已验证的适配模块，确认 console 为空、getty 屏蔽、无现有串口持有者。第二次实际试验在 45 秒超时停止，周期 RX 为 0，未返回初始化结果。监督程序终止子进程并恢复 termios，之后进程检查为空。未申请电压，也未执行应用模块。

用户在试验后再次确认 M400 仍开机、J10 仍接自制板，并完成仅重插 J10。重插后的第三次实际试验仍在 45 秒超时，所有周期 RX 为零；SDK 日志明确为 dji_access_adapter.c:322 的 UART0 连接识别失败，尚未取得适配器信息。见 [[wiki/sources/e300-psdk-replug-record|重插后来源记录]]。第一轮收到字节与后续零接收之间的变化尚未定位，不能混同为同一错误或直接归因于凭据。

试验后 UART 内核累计计数为 TX 117267 / RX 0，root fuser 未发现串口或 console 占用，控制台仍已注销。配置 460800 与 [DJI 官方 E-Port V2 示例](https://developer.dji.com/doc/payload-sdk-tutorial/cn/payload-quick-start/quick-demo/E-Port-V2.html) 一致（2026-09-08 核查）；该页面的 921600 调试日志口说明不应混同通信配置。现场 SDK 已请求 115200、230400、460800、921600、1000000，但这些是软件设置值，不是实测 UART 波形或 CP2102N USB 主机侧设置。因此尚不能完全排除实际速率/时钟误差，也没有依据仅凭配置值判为原因。没有测量波形、抓取 USB 或申请 24 V。

## 桥接器主机侧设置的可观测边界

用户无法测量波形，要求核实桥接器主机侧设置。当前拓扑中，M400 是 CP2102N 的 USB 主机，E300 接的是该芯片的 UART 侧。只读复查 E300 的 lsusb 仅显示 root hub，ttyS0 的驱动链接为 dw-apb-uart；本机 Windows 当前也未发现 DJI 或 Silicon Labs 的对应 USB 设备。这些检查不读取 M400 的 USB 状态，不能据此宣称飞机没有枚举桥接器。

依据 [Silicon Labs AN571 Rev. 0.4](https://www.silabs.com/documents/public/application-notes/AN571.pdf) 第 1 页及第 8-11 页（2026-09-08 核查），CP210x 的配置与状态请求经过 USB control pipe：GET_BAUDRATE 0x1D、GET_LINE_CTL 0x04、GET_FLOW 0x14 分别读取速率、帧格式和流控。E300 的 termios 或 TIOCMGET 不是这些 USB 请求的读回结果，不能替代主机侧证据。把 J10 改接电脑会更换 USB 主机，不是对 M400 当前设置的原位读取。

AN571 第 8 页明确 CP2102N 不支持旧 SET_BAUDDIV/GET_BAUDDIV（0x01/0x02），应使用 SET_BAUDRATE/GET_BAUDRATE。这是 CP2102 与 CP2102N 的兼容性核查点；没有 M400 主机日志、请求抓包或驱动证据，不能断言它使用旧命令或不支持 CP2102N。

当前尚未读到 M400 下发的真实速率、帧格式、流控或接口使能状态。已请求保持 J10 原接线，将 M400 调试接口接电脑，先检查 DJI Assistant 2 的设备/连接诊断入口；尚未连接确认，也不保证 SkyPort V3 页面提供这些底层参数。不把适用于 SkyPort V2/X-Port 的波特率设置说明直接套到 V3。本轮未运行 SDK、修改波特率、写桥接器配置或申请电压。

## 飞机接电脑后的 Assistant 诊断

用户随后连接飞机调试接口并提供 Assistant 截图；截图显示 DJI Assistant 2 V1.2.5 的等待连接页，没有识别出的设备。截图含用户账号，不复制进知识库。

Windows 只读 PnP 检查已发现 DJI VID_2CA3/PID_0020 的复合 USB 设备及 RNDIS 接口，说明电脑侧存在 USB 枚举，不能称为完全没接上。BULK Interface 存在错误；后续属性读取中 MI_05、MI_06 的 ProblemCode 为 28，没有绑定服务。按 [Microsoft Code 28 说明](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/cm-prob-failed-install)，这是驱动未安装/未正确安装的状态。设备接口在两次枚举间有变化，不把首次接口数量当作固定事实。

[M400 官方下载页](https://enterprise.dji.com/matrice-400/downloads) 在 2026-09-08 核查时列出 DJI Assistant 2 (Enterprise Series) Windows V2.1.20；用户截图中的 V1.2.5 不是该版本。下一步应使用对应 Enterprise Series 并核对其官方驱动安装结果，再检查设备页。不据此保证能读取 CP2102N 底层设置，也不把 Windows BULK 驱动缺失等同此前 M400 到 J10 的通信故障。本轮未安装/替换驱动、更新固件或运行 SDK。

## 更新后的 Assistant 与电脑速率对照

用户更新软件后，Windows 回读 MI_03-MI_07 均为 OK、libusb-win32 devices，不再是先前 Code 28。随后截图确认 Enterprise Series 已识别 Matrice 400，固件显示 V17.02.5007；Payload SDK 页提示未发现设备，没有显示可读回的波特率。此时最小 SDK 程序已停止，不能用这张页面单独证明 USB 桥接器没有被飞机枚举。未刷新、降级固件或点击绑定。

用户将 J10 从自制板改接维护电脑后，新增独立二进制对照工具 validate_baud.py / test_baud_pc.ps1，未改原来的 115200 标记脚本。三档均为 8N1 无流控，每档每方向各传一次 4096 字节，逐字节完全匹配：

| 配置波特率 | PC 到 E300 | E300 到 PC |
| --- | --- | --- |
| 115200 | 4096 字节匹配 | 4096 字节匹配 |
| 460800 | 4096 字节匹配 | 4096 字节匹配 |
| 921600 | 4096 字节匹配 | 4096 字节匹配 |

来源和脚本指纹见 [[wiki/sources/e300-pc-baud-record|三档对照记录]]。每次 Linux termios 读回符合设置，传输后恢复原参数，PC COM 句柄关闭；最后 root fuser 未发现 ttyS0 或 /dev/console 占用。没有运行 SDK 或发送飞机协议。当前 J10 仍接维护电脑，内核适配没有卸载。

这排除了本次条件下“E300 与 J10 完全不能在 460800/921600 收发”的假设，不构成波形计量、长时可靠性认证，亦未读取 M400 当前下发参数。后续应聚焦飞机 USB 主机枚举/驱动配置及 SDK 协议识别，不应继续仅凭零 RX 盲改 E300 波特率。

## 接回后识别推进与再次重启

详见 [[wiki/sources/e300-identify-restart-record|识别与重启来源]]。本次脱敏 INFO 日志在约 1.528 秒识别 Extension Port V2 类型和 Matrice 400 系列，2.028 秒识别 UART0 波特率为 921600，随后 USB-UART identity 回调提供 10c4:ea60，约 12 秒报告载荷协商结束。接口类型识别不等同 GetBaseInfo 返回了 SkyPort V3 适配器枚举；该 API 仍未执行。

核心初始化最终返回 0xec，错误定位在 dji_identity_verify.c:112 的 Get uart status error（227），随后 dji_core.c:246 报身份初始化失败。最小程序的 uart_status 对非 UART0 查询直接返回 INVALID；这是需修正/核实的适配问题，不应归因于密钥或波特率。此次没有记录具体被查询的逻辑端口号，不能把“查询了 UART1”写成实测事实。用户报告重启后，原定修正和下一次运行暂停，尚未改该回调。

本次 TX 1406 / RX 12751，读写硬错误计数均为零，monotonic 与 wall elapsed 均为 12.034 秒。监督程序已结束并报告恢复 termios；随后用户发现再次重启。读取 uptime 为 53.47 秒，ttyS0 console 恢复、模块不在。任务本轮未执行 reboot、poweroff、内核重载或固件操作，但尚不能排除试验与重启存在间接关联。

只读检查 pstore 为空、watchdog class 无条目，systemd RuntimeWatchdogUSec=0。当前 journal 的 boot identity 与内核一致，但前一份历史 journal 中未检出本次验证程序/模块记录；其正常关机尾部不能可靠归因于刚才的重启。当前启动错误消息不证明前次重启原因。动态符号表中未见 reboot/system/exec 导入也不能排除所有间接路径，不用它宣称程序绝无关联。

当前仅保留只读调查，不重载 console 模块，不继续 SDK 初始化或反复复现，不申请电压。恢复测试前应先处理重启风险，并核对 UART 状态回调的合法逻辑端口处理。

## 回调修正后恢复测试及再次暂停

用户明确暂缓重启调查并继续。[[wiki/sources/e300-uart-status-fix-record|修正记录]]：合法但未使用的 UART1 状态查询现在返回成功和未连接，七项回调断言及七项配置检查通过。加载已核对内核/指纹的模块后，45.010 秒试验零接收，未走到修正回调；该次前后启动标识一致，termios 已恢复。

[[wiki/sources/e300-resumed-restart-record|后续重启记录]]：用户将 J10 接电脑，端口成功设置 921600 / 8N1 / 无流控后关闭，未发送数据。再接回自制板时试验前启动标识仍未改变，启动前保护检查通过；随后用户报告重启，并以变化的启动标识、50.66 秒 uptime、console 恢复确认。没有主动重启命令，不排除间接关联。

SDK 日志在监督程序内缓冲至子进程退出，本轮因重启丢失，不能确定是否走到状态回调或认证。pstore 无记录，前一份 journal 并不对应本轮试验启动。当前停止 SDK 和模块重载，不申请电压。后续需先改善脱敏日志实时回传和本机断线超时，查明或隔离重启风险；不能把 45 秒进程期限当作系统级保护。

### 导航链接

- [[wiki/index|Wiki 索引]]
- [[wiki/architecture/high-power-feasibility|总评估]]
- [[wiki/experiments/e300-j10-console-trial-2026-09-08|此前 U-Boot 参数试验]]
