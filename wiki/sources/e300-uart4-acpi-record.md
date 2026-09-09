---
title: E300 UART4 的 ACPI 禁用状态与信号电平
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-uart4-acpi-audit-2026-09-08.json
tags:
  - source
  - e300
  - acpi
source_path: test/raw/e300-uart4-acpi-audit-2026-09-08.json
source_hash: 4989d43b1c630de08f26b0ec2a12708357a277b1c983f1b3e8d4003fa1cb2694
ingested_at: 2026-09-08
---

# E300 UART4 的 ACPI 禁用状态与信号电平

[新增选择性记录](../../test/raw/e300-uart4-acpi-audit-2026-09-08.json)。首次登记无旧哈希，新哈希见 frontmatter，不覆盖前次检查。下载发行版 acpica-tools 并仅解包至设备侧独立审查目录，未系统安装；iasl 只读反编译当前 DSDT，没有加载修改表。

## 已定位的软件阻塞

当前 56043 字节 DSDT 的 SHA-256 为 ff78c38fdaa33ad52e88f5e5283e789db42dc7b3a1605b8c4ac35aa1b3d785c2。其中 UART4 对应命名空间 COM1，而非按名字猜测的 UART4：HID MCOM0001、serial_id=4、MMIO 0x0071B000、长度 0x1000、中断 0x38。其 _STA 方法固定 Return (Zero)，sysfs MCOM0001:00 的路径为 COM1，状态也为 0。另一实例 :01 才是 COM0，说明 sysfs 枚举后缀不能代替硬件编号。

此前名称筛选只查 UART/URT/SER 因而未匹配，并非 ACPI 缺少 UART4 描述。此次证据明确为已描述但禁用。UART7 的 COM7 仍返回 0x0F，用作控制台。

运行内核 /proc/config.gz 确认 SERIAL_MTHREADS=y、ACPI_TABLE_UPGRADE=y，CUSTOM_METHOD 和 CONFIGFS 均未启用。没有现成的 ACPI configfs 热加载接口。pinctrl 调试文件只有表头，尚无法据此确定引脚复用。UART4 描述的 clock-frequency 为 4000000，只是固件属性，不是实测时钟；不能保证仅把状态改为可用便能正确通信。

[厂商 ACPI 文档](https://docs.mthreads.com/e300/version-1.5.0/e300-doc-online/boot_system_config/acpi/)（2026-09-08 核查）解释 _STA=0 表示设备不存在；[Linux initrd 表升级说明](https://docs.kernel.org/6.5/admin-guide/acpi/initrd_table_override.html) 提供不刷底层固件的候选覆盖机制。当前仅记录候选，不修改 initrd、启动配置或重启；仍需确认实际启动路径、完整资源和回滚方式。

## UART4 不同于 J10 的电平

跨库 [模组规格书](../../../../MTT_E300/datasheet/E300/E300模组对应底板资料260306/模组开发资料_2026-03-06/02_SOM模组规格书与设计指南/M1000%20MXM模组规格书_2026-03-05.pdf) 第 13 页完整视觉复核：UART4 RXD/TXD 为 CMOS 1.8 V，分别在 E3-4/E3-6；UART7 RX/TX 是 CMOS 3.3 V。文件哈希 d97abfb981a54ac820ec69c3597ab069830054a36a592d89486b8d112bf59331，与此前一致。

跨库 [参考底板原理图](../../../../MTT_E300/datasheet/E300/E300模组对应底板资料260306/模组开发资料_2026-03-06/01_SOM模组底板参考设计原理图和PCB/01_原理图/01_Design_Entry_HDL/602-10035-0000-300.pdf) 第 33 页完整视觉复核：J26 的 1/3 脚分别引出 UART4 TX/RX，经零欧电阻及 ESD 支路，没有此路径的电平转换。哈希 fb36040c76f54cc0ac9a46034f8d1f21b035af007dc9eaef89e4b48dd4d73547，与此前一致。实物插口、装配及额外转换板仍待核对；不能由参考设计直接宣布实物可接。

已询问外置模块型号与 TX/RX 电平，并提示未确认时先断开信号线。此处是逻辑电平，独立于用户自行负责的 USB 5 V 供电。没有发送测试数据，未要求对调线，未声明电气损坏或重启由该接法导致。

- [[wiki/sources/e300-uart4-preflight-record|前次无端口实例观察]]
- [[wiki/index|索引]]
