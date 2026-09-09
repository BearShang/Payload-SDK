---
title: E300 与维护电脑三档波特率对照来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-pc-baud-test-2026-09-08.json
tags:
  - source
  - e300
  - uart
source_path: test/raw/e300-pc-baud-test-2026-09-08.json
source_hash: 5ab0f6193ebe0065ed6c3cc0fd1799b47c550a45859754b488d756ddedf5befc
ingested_at: 2026-09-08
---

# E300 与维护电脑三档波特率对照来源

[选择性测试记录](../../test/raw/e300-pc-baud-test-2026-09-08.json) 记录用户将 J10 从自制板移到电脑后的二进制收发对照。首次登记，旧哈希无，新哈希见 frontmatter。包含测试脚本指纹，不含账号、口令或唯一设备身份。

- Windows 枚举 COM5 / 10C4:EA60 正常，E300 控制台已释放。每次测试在 root 级检查 UART/console 无持有者。
- 115200、460800、921600 三档，每档两个方向各 4096 字节完全匹配。正向覆盖全部字节值，反向 XOR 0xa5；PC 比对完整返回后再发确认，避免 UART 尚未发完就恢复波特率。
- Linux termios 设置读回一致；两端按 8N1 无流控运行。各次退出 0、Linux 设置已恢复、PC COM 句柄关闭，最后 root fuser 无持有者。
- verified 仅覆盖三次短数据传输。它证明电脑主机条件下的 UART/桥接器链路可用，不证明 M400 主机设置、PSDK 初始化、长时可靠性或实际波形精度。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|通信试验及边界]]
- [[wiki/sources/source-inventory|来源清单]]
