---
title: E300 USB 只读探测来源
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-usb-readonly-2026-09-08.json
tags:
  - source
  - e300
  - usb
source_path: test/raw/e300-usb-readonly-2026-09-08.json
source_hash: 2d67ca29c3f396e272b2c20b7744a5c69126b31d328168b9fbf3106e2821528e
ingested_at: 2026-09-08
---

# E300 USB 只读探测来源

## 来源身份与范围

[命令结果记录](../../test/raw/e300-usb-readonly-2026-09-08.json) 保存用户授权 SSH 访问后选择的 8 条只读命令、退出码与返回文本。网络地址、账号、密码、主机序列号均不写入本记录。用户将该目标指定为 E300，具体整机/底板版本未确认。

调查日期为 2026-09-08，不使用目标机登录横幅或系统时钟作为证据日期。此文件是选择性命令记录，不是完整 SSH 会话、示波器数据或 USB 抓包。

## 证据地图与结论

- `uname -mr` 与 os-release：Linux 6.6.10、aarch64、Ubuntu 22.04.4 LTS。
- `ls -l /sys/class/udc`：成功读取目录且为空，本次没有已注册可用的 UDC。
- 四个 UPHY role-switch 的 role 均读为 none。这不是写入 device 后的测试，也不能覆盖 xHCI 已在运行的事实。
- 同名内核配置文件：GADGET=y，CONFIGFS / LIBCOMPOSITE / F_ACM / F_FS=m，CONFIGFS_F_FS=y；M1000_UDC 未启用。该文件与运行内核版本名一致，但未对启动镜像作二进制配置核验。
- `ls -ld /sys/kernel/config/usb_gadget` 返回 1，报告目录不存在。这是实际观察，不是整批探测失败；不能单凭缺少此目录断言内核没有 gadget 功能。
- 包查询确认 gcc/g++、make、cmake、ARM64 libc/libstdc++ 和 libusb 开发包登记存在，不代表完成 PSDK 编译。
- `lsusb -t` 显示 xhci-m1000 / xhci_hcd Host 根集线器和 HID 设备。总线宣告速度不是链路吞吐测试。

## 冲突与不确定性

- CONFIG_USB_GADGET=y 不等于 UDC 已可用；CONFIG_USB_FUNCTIONFS 与 CONFIG_USB_CONFIGFS_F_FS 也不能混为同一配置项。
- USB Role Switch 节点存在并不证明连接器可安全用作 Device；缺失的 UDC 可能涉及驱动、固件、控制器和底板条件，未定位根因。
- 未执行 sudo、modprobe、角色切换、gadget 创建、固件更新、SDK 程序或电源申请。SSH 正常认证/会话记录不等同于“设备没有任何后台写入”。
- 该记录只能证明当次目标状态，不代表所有 E300 型号。

## 修订历史

- 2026-09-08：首次记录并摄取；旧哈希无，新哈希 `2d67ca29c3f396e272b2c20b7744a5c69126b31d328168b9fbf3106e2821528e`。后续探测必须新增记录，不覆盖本文件。

## 相关页面

- [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 只读验证]]
- [[wiki/architecture/high-power-feasibility|24 V 可行性]]
- [[wiki/sources/source-inventory|来源清单]]

