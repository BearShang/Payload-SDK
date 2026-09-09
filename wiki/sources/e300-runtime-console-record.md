---
title: E300 运行期串口控制台注销记录来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-runtime-console-detach-2026-09-08.json
tags:
  - source
  - e300
  - uart
source_path: test/raw/e300-runtime-console-detach-2026-09-08.json
source_hash: bc86ca45251a67c7c950465711938a2079b5dc61ac11fcbb28d47f6651158977
ingested_at: 2026-09-08
---

# E300 运行期串口控制台注销记录来源

[选择性试验记录](../../test/raw/e300-runtime-console-detach-2026-09-08.json) 包含实现指纹、预检查、卸载恢复、双向标记收发、内核日志隔离及最终回读。不是完整终端转录；没有保存地址、账号、凭据或设备序列号。

- 当前 /proc/consoles 为空，模块已加载，ttyS0 节点仍存在；getty 保持 inactive/masked。
- 模块默认 dry-run 不改控制台；未允许移除最后一个 console 时拒绝执行。卸载恢复及再次加载经过实测。
- J10 与电脑在 115200 8N1 无流控下双向标记完全匹配。等级 3 的内核日志对照在恢复控制台时可从电脑收到，注销后只在 dmesg 中出现，3 秒观察内电脑收到 0 字符。
- 最初等级 4 标记因当前 console_loglevel=4 未显示，不用于隔离成功证据；记录保留这一限制。
- 普通 SSH 用户回读模块的只读参数文件因权限不足失败，不能将其写成参数读取成功；实际加载参数由受控 insmod 操作与行为测试佐证。
- 最终记录的 ptp4l 仍为 activating/start-pre，未修改其配置。内核 taint 试验前后均为既有 4096。

首次登记旧哈希无，新哈希见 source_hash。verified 仅表示本记录范围内观察有返回支持，不表示飞机枚举、PSDK 通信、其他波特率或 24 V 已通过。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|运行期适配结果与回滚]]
- [[wiki/sources/source-inventory|来源清单]]
