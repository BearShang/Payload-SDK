---
title: 根构建入口的平台范围
type: source
status: verified
updated: 2026-09-08
sources:
  - CMakeLists.txt
tags:
  - source
  - high-power
source_path: CMakeLists.txt
source_hash: 18b663d7bf19f4d9b446dbebc3de84894d6cf30199e7d2e86685473a57f91a59
ingested_at: 2026-09-08
---

# 根构建入口的平台范围

## 来源身份与范围

[原始文件](../../CMakeLists.txt)
- 全文件阅读；仅解释现有入口，不配置或运行构建。

## 证据地图与结论

- `USE_SYSTEM_ARCH` 默认 LINUX，也有 RTOS 分支。
- Linux 分支加入 C/C++ manifold3 示例，并通过 uname -m 区分 x86_64 / aarch64 的 GNU/Linux SDK 静态库路径。
- RTOS 分支配置 arm-none-eabi 工具链并加入 STM32F4 示例目录。
- 此入口没有 Windows 原生构建分支；默认入口也不是自动选择 Raspberry Pi 或自制板。

## 冲突与不确定性

- 未全仓清点可用二进制，不据此断言任何 Windows 移植绝无可能。
- 更换运行环境并不能单独解决 USB Host / Device 的硬件角色。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `18b663d7bf19f4d9b446dbebc3de84894d6cf30199e7d2e86685473a57f91a59`。本轮仅建立上述范围的结论，未修改来源。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]

