---
title: E300 UART4 外置桥接链路启动前检查
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-uart4-preflight-2026-09-08.json
tags:
  - source
  - uart
  - e300
source_path: test/raw/e300-uart4-preflight-2026-09-08.json
source_hash: 3b6dc56055a6917bc06d0dfff50176622a588bdb8a676d5a31c6b23b28f133c6
ingested_at: 2026-09-08
---

# E300 UART4 外置桥接链路启动前检查

[新增观察记录](../../test/raw/e300-uart4-preflight-2026-09-08.json)。首次登记无旧哈希，新哈希见 frontmatter；不覆盖此前 J10 记录。

用户已拔下 J10 与自制板连接，选择外置 USB-UART 桥接器，将 E300 UART4 接维护电脑 COM6，并要求不通时先提示对调 TX/RX。电脑 PnP 确认 Silicon Labs CP210x COM6 状态 OK，但尚未打开串口或发送测试数据。

E300 的 /proc/tty/drivers 已登记 M1000_uart（ttyMT，主设备号 253，次设备号 0-6）；/boot 对应配置中 SERIAL_MTHREADS=y。实际 /dev/ttyMT* 不存在，mthreads-uart 驱动目录仅有 uevent，/proc/tty/driver/M1000_uart 仅有表头，没有端口实例。ttyS0 仍是 UART7 控制台，ttyS1-3 为 unknown 占位项，不能将 ttyS3/4 猜成 UART4。

结论限定为驱动存在但没有可用的 UART0-6 实例，尚不能确定固件描述、设备枚举或引脚复用的具体原因。ACPI 设备路径名称筛选无匹配，不等同完整 AML 分析。这里是收发前的软件阻塞，不是实测零 RX，因此没有要求用户对调线。

[厂商 UART 文档 1.5.0](https://docs.mthreads.com/e300/version-1.5.0/e300-doc-online/hardware_drivers/uart/)（2026-09-08 核查）区分 UART0-6 的 mthreads_serial 驱动和 UART7 的 8250 驱动，需配置控制器及别名；不能用通用串口节点名称代替具体硬件映射。本文 verified 仅指观察成立，不代表链路通过。

未修改内核、固件、启动模式或引脚，未重启、重载控制台模块或运行 SDK。应先确认当前固件的 UART4 启用路径，再进行限时双向收发；如果届时零接收，先按用户要求提示换线。

- [[wiki/index|索引]]
- [[wiki/experiments/e300-runtime-console-detach-2026-09-08|此前 J10 试验]]
