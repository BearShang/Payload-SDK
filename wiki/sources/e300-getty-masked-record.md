---
title: E300 串口登录停用后的回读来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-ttyS0-getty-masked-2026-09-08.json
tags:
  - source
  - e300
  - uart
source_path: test/raw/e300-ttyS0-getty-masked-2026-09-08.json
source_hash: 8af46bb455dc4559f46377f751203e29eb0d8e44ce57b95448875c1a52925804
ingested_at: 2026-09-08
---

# E300 串口登录停用后的回读来源

[现场回读](../../test/raw/e300-ttyS0-getty-masked-2026-09-08.json) 保存用户授权修改后重新建立 SSH 连接执行的 5 项检查；不含连接地址、账号、口令或设备序列号。

- serial-getty@ttyS0 返回 inactive、masked，服务覆盖路径指向 /dev/null。状态查询的非零退出码与返回状态一起解释，不当成执行成功码。
- /proc/consoles 仍含 ttyS0，故仅串口登录已停用，内核控制台未释放。
- ttyS0 的 iomem_base 为 0x47000，与厂商 UART7 地址一致；不是仅凭名称猜测。
- 未用此结果声称 USB 枚举、PSDK 通信或 24 V 申请成功。

首次登记于 2026-09-08，旧哈希无，新哈希为上述 source_hash。之前的只读记录不覆盖。

- [[wiki/experiments/e300-usb-readonly-2026-09-08|变更过程、回滚及未完成项]]
- [[wiki/sources/source-inventory|来源清单]]
