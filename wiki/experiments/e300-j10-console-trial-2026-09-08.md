---
title: E300 J10 控制台释放试验
type: experiment
status: draft
updated: 2026-09-08
sources:
  - test/raw/e300-j10-uboot-console-trial-2026-09-08.json
  - test/raw/e300-ttyS0-getty-masked-2026-09-08.json
tags:
  - e300
  - uart
  - high-power
---

# E300 J10 控制台释放试验

## 范围与结论

用户明确授权处理 J10/UART7 的软件占用及必要重启，并按要求将 J10 从自制板断开，接到本机 USB。仅做通信准备，不运行 PSDK、不申请 24 V。5 V 仍由用户负责，不扩展该硬件讨论。

**J10 与电脑的 USB-串口通路已实测成立；控制台释放试验未通过。** 仅改 console=tty0 不够。失败的临时参数没有保存，设备已恢复原启动环境并可 SSH，getty 保持上一轮的 masked/inactive 状态。

## 过程与观察

1. Windows 枚举为 CP210x COM5，10C4:EA60；通过 115200 8N1 接收到 E300 ttyS0 发出的测试文字。
2. 通过 SSH 正常重启，首次自动中断未匹配厂商倒计时文案，设备正常进入 Linux；调整识别为 Press <SPACE> key to stop autoboot 后再次重启，成功进入 U-Boot。串口助手仅在识别到倒计时后发空格，不连续盲发启动命令。
3. 读取实际变量：bootcmd 为 run nvmeboota；其加载 NVMe 第一分区的 Image，运行 nvmeparamacpi 后 bootefi。nvmeparamacpi 展开 acpipara 并保留原 root/rootwait。
4. 原 acpipara 为 setenv bootargs rw acpi=on acpi_rsdp=${acpi_rsdp} console=ttyS0,115200n8；仅在 RAM 把 console 目标改为 tty0，保留 ACPI 和根文件系统参数，然后试启动。
5. SSH 回读确认 console=tty0 已进入内核命令行，但 /proc/consoles 同时有 tty0 和启用的 ttyS0。因此不能保存为成功方案，亦不能仅凭 getty 已停用就运行 PSDK。
6. 再次正常重启进入 U-Boot，回读 acpipara 已自动恢复原值，随后按原 bootcmd 启动；SSH 与原串口控制台恢复，串口助手关闭。本批共三次正常重启，未执行环境保存、Flash 擦写、内核/ACPI 表修改。

本机串口助手位于 wiki/.tmp/high-power/，仅为临时工具，不发布完整启动日志或设备身份。正式选择性记录见 [[wiki/sources/e300-j10-uboot-trial-record|来源笔记]]。

## 原因与版本限制

运行内核配置启用 CONFIG_ACPI_SPCR_TABLE。Linux v6.6 的 [ARM64 ACPI 初始化](https://raw.githubusercontent.com/torvalds/linux/v6.6/arch/arm64/kernel/acpi.c) 在启用 ACPI 时调用 acpi_parse_spcr(..., true)，其 [SPCR 解析实现](https://raw.githubusercontent.com/torvalds/linux/v6.6/drivers/acpi/spcr.c) 可注册固件指定串口。结合试启动中 ttyS0 仍注册的现象，SPCR 是本轮的主要原因判断；没有读取厂商完整内核源码，不能把上游实现逐字等同于厂商代码。

上游 [2024-06 acpi=nospcr 补丁](https://lists.infradead.org/pipermail/linux-arm-kernel/2024-June/937892.html) 为 ARM64 增加了关闭该默认串口的参数，v6.6 原始实现没有这一项。本机实际启动 Image 的字符串检索也未见 nospcr，故不能直接套用新版本选项。未试启动该参数，也不使用 acpi=off，后者可能影响整个平台设备发现。

还发现实际启动分区 Image 与 /boot/vmlinuz-6.6.10 解压内容的 SHA-256 不同。后续内核适配必须以实际加载镜像及其配套源码/模块为准，不能覆盖 /boot 下同名文件后宣称生效。两个哈希保存在现场记录中，镜像未修改。

## 当前状态与后续

后续进展：用户已授权更深入适配；[[wiki/experiments/e300-runtime-console-detach-2026-09-08|运行期模块方案]] 已在当前启动中完成注销、收发和回滚验证。下面保留本次 U-Boot 试验结束时的状态，不覆盖其失败记录。

- 原 U-Boot 环境未变；getty 持久屏蔽是上一轮唯一保留的功能配置变化，其恢复方法见 [[wiki/experiments/e300-usb-readonly-2026-09-08|先前记录]]。
- 要继续使用 J10，需要适用于实际内核/固件的 SPCR 控制台禁用方案，或先评估并授权更深入的内核适配；不能把未使用的串口号、降低日志级别、盲改 ACPI 表或换整个启动模式作为无风险替代。
- U-Boot 本身仍使用 UART7；即便将来释放 Linux console，也须把启动阶段日志与 PSDK 数据阶段分开考虑，不宣称整个上电过程 UART7 无输出。
- 试启动时出现既有 e300-ptp4l 服务等待/失败日志，本轮未改该服务；最终恢复启动后应继续区分其状态与本次串口试验，不把 SSH 恢复等同于所有工作负载恢复。
- 最终恢复启动后的定向回读为 e300-ptp4l ActiveState=activating、SubState=start-pre、Result=success；仅表示当时仍在启动准备，Result 不代表同步成功。未改其配置。
- 电脑枚举及串口收发成功，不证明飞机对 CP2102N 的枚举、PSDK 初始化或 24 V 申请成功。最终验收仍仅为用户在自制板 VCC/GND 测得 24 V。

## 导航

- [[wiki/index|Wiki 索引]]
- [[wiki/architecture/high-power-feasibility|总评估]]
- [[wiki/experiments/e300-usb-readonly-2026-09-08|前期接口核查与 getty 修改]]
