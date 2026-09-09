---
title: E300 Device 驱动与串口控制台核查来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-driver-console-2026-09-08.json
tags:
  - source
  - e300
  - usb
source_path: test/raw/e300-driver-console-2026-09-08.json
source_hash: 5bbbde49f0a1ae21ecf2c77483f277ab75b8438807c893e3361f4060c4e77de8
ingested_at: 2026-09-08
---

# E300 Device 驱动与串口控制台核查来源

[只读命令记录](../../test/raw/e300-driver-console-2026-09-08.json) 保存 16 项选择性返回。仅记录技术信息；一项本机 PowerShell 引号失败的命令行片段已脱敏，并保留失败标记，随后正确重试。失败不是设备观察。未保存连接地址、账号或凭据。

## 已证实范围

- 运行内核 6.6.10；M1000_UDC 未启用；UDC 目录为空。模块目录检索没有发现 M1000 UDC 模块，不能靠现有 PHY 模块替代。
- phy-m1000-usb.ko 是 PHY 驱动；实际绑定目录为 mt-usb-phy，挂接四个 UPHY0001 实例；四个 role 返回 none。最初按模块名寻找平台驱动目录失败，正确路径后续已核实。
- /usr/src 有 headers，而 /lib/modules/6.6.10/source 不存在；不据此断言整机任何位置都没有源码。
- ttyS0 是当前内核控制台，serial-getty@ttyS0.service 正在运行。ttyS0 至 ttyS3 的节点存在，不意味着四路都接出或可用。
- 未操作串口、加载驱动、切换角色、修改服务/内核或申请电压。verified 仅表示记录中的观察有命令返回支持。

## 修订历史

- 2026-09-08 首次登记，旧哈希无；新哈希 5bbbde49f0a1ae21ecf2c77483f277ab75b8438807c893e3361f4060c4e77de8。后续现场观察另增记录。

## 相关页面

- [[wiki/experiments/e300-usb-readonly-2026-09-08|验证记录与 J2/J10 电路核查]]
- [[wiki/sources/source-inventory|来源清单]]
