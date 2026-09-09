---
title: E300 电脑配置后再接回的重启记录
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-resumed-restart-2026-09-08.json
tags:
  - source
  - e300
  - restart
source_path: test/raw/e300-resumed-restart-2026-09-08.json
source_hash: 1db6ff62bab05a42495e1c847bfe2645f9c5133a488b62caedacc221352a24a0
ingested_at: 2026-09-08
---

# E300 电脑配置后再接回的重启记录

[新增选择性现场记录](../../test/raw/e300-resumed-restart-2026-09-08.json)。首次登记无旧哈希，新哈希见 frontmatter。没有保存账号、凭据或设备启动标识原值。

用户确认 J10 接电脑后，10c4:ea60 端口状态正常，成功打开为 921600、8N1、无流控、DTR/RTS false，零数据写入并正常关闭。这不是 M400 USB 主机侧读回。

用户接回自制板后，试验前启动标识与前轮相同，uptime 670.78 秒，控制台适配仍在；监督程序输出启动前检查通过。随后用户报告重启。挂起的本机 SSH 客户端已停止；其 -1 退出码是本机停止结果，不是 SDK 返回码。

只读复查确认启动标识改变、uptime 50.66 秒、ttyS0 console 恢复、适配模块及测试进程不在。pstore 和 watchdog class 均无条目；前一份 journal 的启动身份不匹配实际试验启动，不能用于认定此次原因。当前 GPU watchdog 启用消息也不证明触发了复位。

SDK 输出在远端监督程序中等待子进程结束后才脱敏回传，本次重启丢失了这部分内存日志，无法判断具体阶段或确认 termios 恢复。未发送重启命令，仍不能排除测试或内核适配间接相关。用户态 45 秒期限不能防止系统重启。已停止重载和重试，未调用电源管理，未测得 24 V。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|完整过程及最新状态]]
