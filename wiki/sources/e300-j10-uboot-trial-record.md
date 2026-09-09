---
title: E300 J10 串口及 U-Boot 临时控制台试验来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-j10-uboot-console-trial-2026-09-08.json
tags:
  - source
  - uart
  - e300
source_path: test/raw/e300-j10-uboot-console-trial-2026-09-08.json
source_hash: 98ca855982572318ade8c190addd021835b055e5a90f66745322feb1e4591a98
ingested_at: 2026-09-08
---

# E300 J10 串口及 U-Boot 临时控制台试验来源

[选择性现场记录](../../test/raw/e300-j10-uboot-console-trial-2026-09-08.json) 包含本机串口枚举、测试文字、U-Boot 指定变量和试启动/恢复后的检查。不是完整启动日志；设备序列号、网络标识及无关服务输出未保存。

## 证据范围

- J10 接 Windows 后枚举为 COM5，VID:PID 为 10C4:EA60；115200 8N1 下收到 E300 ttyS0 发出的 PSDK_CONSOLE_LINK_CHECK。随后能在 U-Boot 输入命令并获得返回。
- U-Boot 版本 2025.04-g9fbac6720652，实际启动链为 bootcmd -> nvmeboota -> nvmeparamacpi -> acpipara，不是先前参考文档中的另一版变量名。
- 只在 RAM 将 acpipara 的 console=ttyS0,115200n8 替换为 console=tty0，未执行 saveenv/env save。试启动后 /proc/consoles 同时出现 tty0、ttyS0，试验未释放串口。
- 再次重启回读 acpipara 恢复原值，按原环境启动后 SSH 可用，内核控制台仍是 ttyS0，getty 保持 masked/inactive。
- 实际启动分区 Image 与解压后的 /boot/vmlinuz-6.6.10 哈希不同；不能仅按相同版本号把后者当成实际加载镜像。实际 Image 检索未见 nospcr 字符串，但没有直接试启动 acpi=nospcr，不能混淆检索与功能验证。

verified 仅指限定观察有回读依据，不代表串口已交给 PSDK 或飞机已识别桥接器。首次登记旧哈希无，新哈希见 source_hash；后续观察新增记录。

- [[wiki/experiments/e300-j10-console-trial-2026-09-08|试验结论与下一步]]
- [[wiki/sources/source-inventory|来源清单]]
