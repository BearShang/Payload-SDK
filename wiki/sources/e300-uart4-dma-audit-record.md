---
title: E300 UART4 实际内核 DMA 拒绝路径
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-uart4-dma-audit-2026-09-08.json
tags:
  - source
  - e300
  - uart
  - acpi
source_path: test/raw/e300-uart4-dma-audit-2026-09-08.json
source_hash: f2c490e359fb7a348891391832246d6e9da0845e97b5d2fe7f24c0344ac94a5e
ingested_at: 2026-09-08
---

# E300 UART4 实际内核 DMA 拒绝路径

[选择性静态审查记录](../../test/raw/e300-uart4-dma-audit-2026-09-08.json)。首次登记，无旧哈希。范围为实际启动 Image 的反汇编和已反编译 ACPI 表，不是新一次 UART4 启动试验。

## 已确认

只读挂载启动分区，对 Image 做 SHA-256 保护，使用当前内核 kallsyms 相对 _text 的偏移定位函数，随后卸载。所读 Image 身份与此前试启动一致，不使用内容不同的根文件系统 /boot/vmlinuz 替代。

- mthreads_serial_probe 在 Image 偏移 0x737ab8 调用 dma_set_mask，参数为 64 位全一掩码；非零返回走报错和清理，字符串引用精确对应此前 Unable to set dma mask。成功分支才继续设置 coherent mask、分配 4096 字节 DMA 缓冲并注册串口。因此此处失败先于用户串口收发，换波特率或对调 TX/RX 不能解决此错误。
- 实际 Image 的 platform_dma_configure 调用 acpi_get_dma_attr / acpi_dma_configure_id；属性为零时设置 dma_dummy_ops。acpi_dma_supported 检查 flags 的 bit 11，已安装头文件该位为 cca_seen；dma_dummy_supported 恒返回零，dma_set_mask 的相应失败分支返回 -5。
- COM1 的 _DSD 只有 serial_id=4 和 clock-frequency=4000000，设备内没有 _CCA 或时钟引用。先前仅修改 _STA，不足以构成完整 UART4 平台配置。
- 所审查 probe 错误分支没有退回 PIO；不能把“关闭 DMA”当作现成的配置开关。该结论不涵盖驱动所有函数。

这些静态路径与 [Linux v6.6 ACPI 实现](https://raw.githubusercontent.com/torvalds/linux/v6.6/drivers/acpi/scan.c) 中缺少适用 _CCA 时拒绝 DMA 的规则一致（2026-09-08 回查）。与此前仅依据上游源码的候选解释相比，现已核对实际启动二进制中的关键调用路径。

## 不确定性与下一步

缺少适用 _CCA 是有力解释，但没有采集失败 probe 当时的 live dma_ops/cca_seen，不能称为动态唯一根因证明，也不能推论 UART4 硬件不支持 DMA。原始 Image 中未重定位的指针槽读数不作为运行时指针证据。

需要当前 E300 板级支持包的 UART4 完整 ACPI/设备树参考及 mthreads_serial.c，确认缓存一致性、DMA 路由、时钟、IRQ 和 pinmux。已检查的内核头文件及 MTT_E300 对应源码文件名中未找到驱动源码，不等于穷尽所有存储位置。其他设备的 _CCA=0 不是 UART4 正确取值的充分证据；不盲补 0/1，不改二进制跳过检查。

本轮没有重启、加载模块、补写 ACPI、操作串口或运行 PSDK。最终 UART4 状态仍为 0，无 ttyMT 节点，临时挂载已卸载。verified 仅指审查范围有证据，不代表 UART4 或 24 V 验证通过。

- [[wiki/sources/e300-uart4-boot-trial-record|此前试启动与回滚]]
- [[wiki/index|索引]]
