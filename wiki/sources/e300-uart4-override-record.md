---
title: E300 UART4 最小覆盖表的离线准备
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-uart4-override-prepared-2026-09-08.json
tags:
  - source
  - e300
  - acpi
source_path: test/raw/e300-uart4-override-prepared-2026-09-08.json
source_hash: 0a32daa6f417fde821c3d06a8b4ee39e09e5f3111e8cfd20588b6c062c3fc4b5
ingested_at: 2026-09-08
---

# E300 UART4 最小覆盖表的离线准备

[新增选择性记录](../../test/raw/e300-uart4-override-prepared-2026-09-08.json)。首次登记无旧哈希，新哈希见 frontmatter。用户报告已使用电平转换模块并确认 TX/RX 为 1.8 V，不写成代理实测。J10 接回电脑 COM5，115200 下实际收到 E300 写出的恢复通道标记，之后 COM5 已关闭；外置桥接 COM6 枚举正常，尚未发送 UART4 测试数据。

原始 DSDT 哈希与 [[wiki/sources/e300-uart4-acpi-record|上一轮审查]] 相同。初次整表重编译虽零错误，但基线 AML 在 UART4 之外也发生字节变化，拒绝加载该候选，不能仅以编译成功宣布安全。

[最小构建工具](../../tools/e300_uart4_audit/build_override.py) 仅接受已审查原始表的完整 SHA-256。对已核对的 _SB/COM1/_STA 包结构，将 Return(Zero) 改为 Return(0x0F)，更新三个包长度、表长度、OEM revision 和校验和。反向操作逐字节恢复原始表；独立 iasl 反编译与人工审核的目标源正文一致。不是通用 AML 编辑器，也没有加载内核模块。

候选 AML 为 56044 字节，SHA-256 3e0cbf96ed65b99d42b6b791bd3cf594fc5e62faa5329bc86d8e94a2a20644db；仅含该表的 cpio 为 56832 字节，SHA-256 b05d61b34f063e1b92f2984a4f9ccfb5c5128ed7cfbdebcd37928d6081143e98。七项本地保护测试通过，实际构建另检查表身份、校验、字节保留、反编译和归档目录。构建产物仅在设备审查目录，不复制进 Wiki。

运行系统 UART4 状态仍为 0，UART7 console 保持启用。未修改启动文件、保存 U-Boot 环境、重启、运行 SDK 或申请电压。候选只经过离线验证，不证明设备初始化、引脚复用、时钟或通信成功。

[Linux EFI stub](https://docs.kernel.org/admin-guide/efi-stub.html) 和 [U-Boot bootefi](https://docs.u-boot.org/en/v2024.01/usage/cmd/bootefi.html)（2026-09-08 回查）给出 initrd 和加载选项路径。下一步仍需确认本机实际加载路径、取得受控重启确认、仅使用一次性内存启动参数并保留原启动与 COM5 恢复通道；文档支持不等同本机试启动成功。

- [[wiki/sources/e300-uart4-acpi-record|禁用状态及电平资料]]
- [[wiki/index|索引]]
