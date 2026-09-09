---
title: E300 状态回调修正与零接收复测
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-uart-status-fix-2026-09-08.json
tags:
  - source
  - e300
source_path: test/raw/e300-uart-status-fix-2026-09-08.json
source_hash: ba838b3eda8781818c36fbc5e992672c72ab253aebb072ed9984f51401c2aea9
ingested_at: 2026-09-08
---

# E300 状态回调修正与零接收复测

[新增现场记录](../../test/raw/e300-uart-status-fix-2026-09-08.json)。首次登记无旧哈希，新哈希见 frontmatter，不覆盖历史记录。

用户授权暂缓重启原因调查并继续。状态回调现对合法 UART1 查询返回成功且未连接，UART0 反映本地打开状态；不伪造飞机连接。七项回调断言和七项配置检查通过，已明确重新配置 CMake 并清理重编，不能将初次未发现测试当成通过。

核对内核和模块指纹后重载控制台适配；一次 45.010 秒试验仍在 UART0 识别阶段零接收超时，没有走到修正后的回调。前后启动标识一致，程序退出、termios 恢复且无串口持有者。此结论只覆盖该次观察区间，不代表后续不会重启，也不是完整 SDK 初始化验证。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|完整过程及最新状态]]
