---
title: Linux USB Bulk 端点配置
type: source
status: verified
updated: 2026-09-08
sources:
  - samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h
tags:
  - source
  - high-power
source_path: samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h
source_hash: 22e7e24e04da2b307d16c615a83a361edb9493f773304eab14b53daf220a1be4
ingested_at: 2026-09-08
---

# Linux USB Bulk 端点配置

## 来源身份与范围

[原始文件](../../samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h)
- 全文件阅读；仅为 Raspberry Pi 示例头文件的配置快照。

## 证据地图与结论

- `LINUX_USB_BULK1/2/3_EP_IN_FD` 与 OUT_FD 指向 /dev/usb-ffs/bulk1、bulk2、bulk3 的 ep1 / ep2。
- `LINUX_USB_VID/PID` 为 0x2CA3 / 0xF001；三组接口号为 0、1、2，端点为对应的 IN/OUT 地址。
- 包含 POSIX/Linux 风格头文件。这不是 Windows USB 驱动或可自动创建的 COM 口。

## 冲突与不确定性

- 本配置的 F001 为此 Bulk 示例身份，不应与官方网页的 USB VCOM F002 混同。
- 端点文件路径只是预期配置，不证明本机存在这些端点或已完成枚举。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `22e7e24e04da2b307d16c615a83a361edb9493f773304eab14b53daf220a1be4`。本轮仅建立上述范围的结论，未修改来源。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]

