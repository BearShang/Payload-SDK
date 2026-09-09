---
title: E300 首次 PSDK 核心通信试验来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-psdk-core-trial-2026-09-08.json
tags:
  - source
  - e300
  - psdk
source_path: test/raw/e300-psdk-core-trial-2026-09-08.json
source_hash: 0803e8800c5b3caad7fdc9c86dafbf6e1998f1f9bd76731616370baf44e00408
ingested_at: 2026-09-08
---

# E300 首次 PSDK 核心通信试验来源

[选择性观察记录](../../test/raw/e300-psdk-core-trial-2026-09-08.json) 记录两次实际核心初始化尝试及中间一次保护拒绝，不保存凭据或完整终端记录。首次登记，旧哈希无，新哈希见 frontmatter。

- 第一次通过运行前检查，使用用户指定的既有应用信息，配置波特率 460800。SDK 自动选用了多个波特率，初始化最终返回 0xec，TX 1406 / RX 1861 字节；没有取得机型或适配器。
- 后一次执行前发现 ttyS0 console 恢复、适配模块不存在、uptime 为 144 秒，检查拒绝打开 UART。期间有设备重启迹象，本任务未执行重启；原因未知。设备墙上时间和历史 journal 不一致，不能用旧关机日志确定这次原因。
- 核对原模块 SHA-256 与内核版本后重新加载，console 为空、getty masked/inactive、fuser 无占用。
- 第二次实际尝试达到 45 秒上限，退出 124；所有周期观察 RX 均为 0，40 秒时 TX 为 32377。没有观察到 DjiCore_Init 返回。监督进程恢复 termios，之后未发现核心验证进程。
- verified 只表示上述选择性观察有命令结果支持，不表示 SDK 初始化、凭据认证、飞机枚举或 24 V 已通过。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|工程过程与试验边界]]
- [[wiki/sources/source-inventory|来源清单]]
