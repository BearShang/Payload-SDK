---
title: E300 接线后 USB 复查来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-usb-connected-2026-09-08.json
tags:
  - source
  - e300
  - usb
source_path: test/raw/e300-usb-connected-2026-09-08.json
source_hash: da4559fc286671c081af824a31134cb60a3043cacbc7b5cbbe896e1235e61b23
ingested_at: 2026-09-08
---

# E300 接线后 USB 复查来源

## 来源身份与范围

[选择性命令记录](../../test/raw/e300-usb-connected-2026-09-08.json) 包含用户报告自制板 USB2 已接到 E300 后的 6 条只读命令结果。日期为调查日期，未保存地址、账号、凭据或设备序列号；原来的探测记录保持不变。

## 证据地图与结论

- lsusb 与 lsusb -t：只见 Linux USB 2.0/3.0 根集线器，无外接设备条目。
- /sys/class/udc：目录为空；四个 UPHY role-switch 的 role 仍为 none。
- /dev 检索未返回 ttyUSB、ttyACM 或 ttyGS 节点。
- 定向内核日志查询退出码为 1 且没有输出，不作为“没有 USB 错误”或“设备未发生插拔”的证据。
- 相比此前记录，当次 Host 树中也不再显示原有 HID 条目；不推断是谁拔除，也不将变化归因于飞行器。

## 冲突与不确定性

- USB2 是自制原理图的器件位号，不因此判定连接速度是 USB 2.0。
- 用户在记录后补充确认 E300 端为 USB-A、M400 已开机；后续截图定位为 J3 的 CON2/CON3 两只 USB 口之一，具体插孔未区分。原理图追踪见验证页，不改写当次探测来源；线缆和实机控制器映射仍未验证。
- 对飞机作为 Host 的预期路径，E300 不应依靠 Host 枚举来寻找飞机；本次同时检查 UDC 和 gadget 串口，是为区分两种方向，不能仅以 lsusb 无飞机条目判断失败。
- 未切换 USB 模式、未加载模块、未运行 SDK 或申请 24 V。verified 仅指记录内观察有返回文本支持。

## 修订历史

- 2026-09-08：首次新增；旧哈希无，新哈希 da4559fc286671c081af824a31134cb60a3043cacbc7b5cbbe896e1235e61b23。后续观察另增记录，不覆盖来源。

## 相关页面

- [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 只读验证]]
- [[wiki/sources/source-inventory|来源清单]]
