---
title: E300 识别成功后的状态回调错误与重启观察
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-identify-restart-2026-09-08.json
tags:
  - source
  - e300
  - psdk
source_path: test/raw/e300-identify-restart-2026-09-08.json
source_hash: 0c238f58b3fa38aaf1657d0804cbc4bdb49b74ad607dbcb4d782f9a6a2c37d06
ingested_at: 2026-09-08
---

# E300 识别成功后的状态回调错误与重启观察

[选择性现场记录](../../test/raw/e300-identify-restart-2026-09-08.json) 为新增观察，不覆盖之前零接收或电脑收发记录。首次登记，旧哈希无，新哈希见 frontmatter；不记录连接账号、地址或应用凭据。

- 用户接回 J10 后，本次 SDK 识别 M400 系列、Extension Port V2 类型、UART 921600，并完成载荷协商。
- 核心初始化仍返回 0xec；身份初始化报告 Get uart status error，返回 227。收发为 TX 1406 / RX 12751，读写硬错误计数为零。没有进入基本信息 API 或电源申请。
- 监督程序约 12.034 秒结束，monotonic 与 wall elapsed 一致，报告恢复 termios。随后用户报告再次重启；读取 uptime 53.47 秒，console 恢复且适配模块不在。
- 本轮没有主动重启/关机命令。但不能排除 SDK、内核适配或其他因素间接相关，也不能仅凭时间邻近断言因果。
- 只读检查 pstore 为空、watchdog class 无条目，systemd RuntimeWatchdogUSec 为 0。历史 journal 虽有正常关机消息，未找到与本次程序匹配的条目，不能可靠归于此次重启；当前启动日志也未建立原因。
- verified 仅指所列观察有证据支持，不代表原因确定、完整初始化成功或安全性通过。后续 SDK 测试暂停，未重载模块、修改状态回调或强制复现。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|过程与当前暂停状态]]
- [[wiki/sources/source-inventory|来源清单]]
