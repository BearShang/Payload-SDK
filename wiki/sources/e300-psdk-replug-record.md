---
title: J10 重插后的 PSDK 连接识别记录来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-psdk-replug-trial-2026-09-08.json
tags:
  - source
  - e300
  - uart
source_path: test/raw/e300-psdk-replug-trial-2026-09-08.json
source_hash: b2657d50fd13bafd72ceaca7398f17e3151094dd54df84ed2b2189b1e42c3985
ingested_at: 2026-09-08
---

# J10 重插后的 PSDK 连接识别记录来源

[选择性记录](../../test/raw/e300-psdk-replug-trial-2026-09-08.json) 新增于前一次记录之后，不覆盖其数据。首次登记，旧哈希无，新哈希见 frontmatter。记录不含应用凭据或设备身份。

- 用户确认 M400 保持开机、J10 接自制板，并完成重插。
- SDK 自报 V3.16.0-beta.0-build.2338；460800 配置下自动请求五种 UART 波特率。
- 日志 dji_access_adapter.c:322 持续报告 UART0 connection identification failed，45 秒超时。周期 RX 均为零，未获得成功初始化或适配器信息。
- 试验后内核 UART0 累计 TX 117267 / RX 0；这是当前驱动生命周期累计值，不是单次试验计数。底层未记录接收，不只是在应用解析层无报文。
- 监督程序恢复 termios；root fuser 对串口和 console 无持有者，/proc/consoles 为空。七项非 I/O 配置回归及监督脚本语法检查通过。
- verified 仅指上述观察。软件请求波特率不等于实测速率；没有测量 UART 波形，也没有证明 CP2102N 主机侧设置一致。不能将此结果归因于凭据或认定飞机 USB 枚举已成功。

- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|通信过程与限制]]
- [[wiki/sources/source-inventory|来源清单]]
