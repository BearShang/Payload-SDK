---
title: GD32 高功率 GPIO 示例
type: source
status: verified
updated: 2026-09-08
sources:
  - samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c
tags:
  - source
  - high-power
source_path: samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c
source_hash: 4976d4b10c2843259e076379f790e81400ac9e674cf4bae704de81ea413d7768
ingested_at: 2026-09-08
---

# GD32 高功率 GPIO 示例

## 来源身份与范围

[原始文件](../../samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c)
- 全文件阅读；适用 GD32F527 示例的 BSP，不是自制板驱动。文件注释的 V2.0.0 / 2019-09-20 不用作本仓 SDK 版本。

## 证据地图与结论

- `HIGH_POWER_APPLY_PORT/PIN` 为 GPIOA / GPIO_PIN_7。
- `DjiTest_HighPowerApplyPinInit` 将 PA7 配为无上下拉、推挽输出，并通过 GPIO_BOP 置高。
- `DjiTest_WriteHighPowerApplyPin` 对 RESET 写 GPIO_BC（低），对 SET 写 GPIO_BOP（高），未知枚举返回错误。

## 冲突与不确定性

- 不能推定 PA7 到官方板 HIGH_PWR_REQ 之间没有反相/缓冲器件，本批未摄取官方 GD32 开发板原理图。
- 自制板图中没有 GD32；若以后使用 GPIO，与硬接地节点的电气连接必须单独设计，不能直接照搬推挽置高。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `4976d4b10c2843259e076379f790e81400ac9e674cf4bae704de81ea413d7768`。本轮仅建立上述范围的结论，未修改来源。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]

