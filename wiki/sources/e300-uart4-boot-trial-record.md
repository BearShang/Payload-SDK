---
title: E300 UART4 临时启动的 DMA 错误与回滚
type: source
status: verified
updated: 2026-09-08
sources:
  - test/raw/e300-uart4-boot-trial-2026-09-08.json
tags:
  - source
  - e300
  - uart
  - acpi
source_path: test/raw/e300-uart4-boot-trial-2026-09-08.json
source_hash: d9608ed81f93fb96b99eb96b5b4c3e37ad753a1a122181ab23da27bd404af70d
ingested_at: 2026-09-08
---

# E300 UART4 临时启动的 DMA 错误与回滚

[选择性现场记录](../../test/raw/e300-uart4-boot-trial-2026-09-08.json)。首次登记无旧哈希，新哈希见 frontmatter。用户明确允许一次受控试启动及失败后走原路径恢复。本轮两次正常重启均由任务明确发起，分别用于试验与回滚，不计为此前未知原因重启。

## 临时启动结果

先只读核对实际启动分区 Image 哈希未变及 EFI UTF-16 initrd 选项，再以独立文件 psdk-uart4.cpio 放入该分区；没有覆盖 Image、设备树或启动配置。COM5 保留 115200 控制台，COM6 没有打开。重启后在倒计时出现时中断至 U-Boot，回读确认原 bootcmd 为 run nvmeboota，加载原 Image，通过 RAM 中 bootargs 加入独立 initrd。未保存环境。

第一次参数写法因 U-Boot 引号/转义行为不符合预期，被回读检查发现并在启动前修正；最终单引号完整参数保留 EFI 绝对路径、原 root 和 UART7 console。不能把当前启动的 RSDP 地址硬编码用于后续启动。

- EFI 明确报告 Loaded initrd from command line option；内核报告找到表并执行 DSDT Table Upgrade。
- SSH 恢复，读取 uptime 104.98 秒；当前 DSDT 哈希精确匹配最小候选 3e0cbf96ed65b99d42b6b791bd3cf594fc5e62faa5329bc86d8e94a2a20644db。
- UART4 的 ACPI 状态从 0 变为 15，驱动开始探测，但报告 Unable to set dma mask，probe 以 -5 失败，没有任何 ttyMT 节点。
- 控制台注销模块始终未加载，UART7 console 保留。未发送 UART4 测试字节，未运行 SDK 或申请电压；没有要求对调线。

## 回滚核对

告知用户后正常重启，由未修改的原保存环境启动。SSH 恢复，uptime 132.30 秒，initrd 参数不在，UART4 状态回到 0。原 DSDT SHA-256 ff78c38fdaa33ad52e88f5e5283e789db42dc7b3a1605b8c4ac35aa1b3d785c2 和 Image SHA-256 ce510ef53d94eb077bf1765aa43e13e0c2d63304d1e7627b63e1c68243013c66 均已核对。

仅在独立测试文件哈希匹配时删除启动分区的 psdk-uart4.cpio，卸载临时挂载，关闭 COM5 助手。审查目录的离线产物保留。原有 e300-ptp4l 服务仍为 activating/start-pre，Result=success 不等于同步成功；本轮未修改该服务，未以 SSH 恢复代替全部工作负载验证。

## 下一层待核查

运行内核 ACPI_CCA_REQUIRED=y。上游 Linux v6.6 的 [acpi_dma_supported / acpi_get_dma_attr / acpi_init_coherency](https://raw.githubusercontent.com/torvalds/linux/v6.6/drivers/acpi/scan.c)（2026-09-08 回查）在要求 _CCA 且设备/祖先未提供时可以判为不支持 DMA，继而使用 dummy DMA operations。这与错误相符，是下一步候选解释；尚未获得厂商 UART 驱动完整实现或证明实际故障的唯一原因，不直接补写 _CCA=0/1 或关闭 DMA。

本记录 verified 指观察和回滚有证据，不表示 UART4 链路成立。临时覆盖机制已验证，但仅改启用状态不足以使用 UART4。

- [[wiki/sources/e300-uart4-override-record|此前离线候选]]
- [[wiki/index|索引]]
