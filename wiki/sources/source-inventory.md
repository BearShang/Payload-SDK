---
title: Payload-SDK 来源清单
type: overview
status: draft
updated: 2026-09-08
sources: []
tags:
  - inventory
---

# 来源清单

2026-09-08 完成高功率申请定向摄取，逐文件登记见下节。没有计算全仓指纹或宣称全仓摄取完成；未列入本批的资料仍待摄取。已摄取只表示限定范围有来源摘要，不表示实物验证。

| 来源位置 | 证据角色 | 状态 |
| --- | --- | --- |
| [doc](../../doc/) | 随仓说明、参考设计和模板 | 待摄取 |
| [硬件原理图](../../hardware/SCH_Schematic2_2026-09-08.pdf) | 项目硬件资料，发布状态未确认 | 已摄取第 1 页供电/跳帽/USB 拓扑并视觉复核；实物与高速信号质量未验证 |
| [SDK 库与头文件](../../psdk_lib/) | SDK 声明与二进制身份 | 电源管理与版本头文件已摄取；其余待摄取 |
| [示例](../../samples/) | 特定版本工程实现 | 下表登记的电源/GD32 GPIO/Linux USB 文件已摄取；其余待摄取 |
| [工具](../../tools/) | 原有随仓工具 | 待摄取；Wiki 维护工具不作为技术来源 |
| [README](../../README.md)、[构建入口](../../CMakeLists.txt) | 仓库说明及构建配置 | 根构建入口平台分支已摄取；README 待摄取 |
| [LICENSE](../../LICENSE.txt)、[EULA](../../EULA.txt) | 随仓许可证文本 | 待摄取，不提供法律解读 |
| [LLM Wiki 理念](../../LLM%20Wiki.md) | 框架理念 | 保留原文，未摄取 |
| [E300 只读现场记录](../../test/raw/e300-usb-readonly-2026-09-08.json) | 经授权读取的设备能力证据 | 已摄取 8 条命令结果，不含账号、地址或凭据 |

默认变更检测覆盖 `doc/`、`hardware/`，以及未来实际存在的 `sources/`、`datasheets/`、`test/raw/`。不提前建立空目录。工程实现需用户指定路径，或明确要求全仓初始化摄取。

## 来源登记

以下 8 个文件已摄取，摄取日期均为 2026-09-08。每个来源笔记明确实际范围与不确定性，硬件页仍为 draft。首次登记无旧哈希；新身份如下，后续修订须保留历史。

| 仓库相对路径 | SHA-256 | 来源笔记及范围 |
| --- | --- | --- |
| `hardware/SCH_Schematic2_2026-09-08.pdf` | `ca31c43b26ab6d7a47e15bcb41963327e32dc4fd6ead4a45f7e1b3405426e3c2` | [[wiki/sources/custom-board-schematic|自制转接板原理图]] |
| `psdk_lib/include/dji_power_management.h` | `51cfcbcab2f3fd54e377a3b7b0fb09bfe805a8ed68abb33543ccfd65e4649b63` | [[wiki/sources/power-management-api|电源管理 API 声明]] |
| `psdk_lib/include/dji_version.h` | `c69d052d7b71f625192e9fd9b1436005f9db3d36dbb789d6166b96999cf8d66a` | [[wiki/sources/sdk-version|本仓 SDK 版本声明]] |
| `samples/sample_c/module_sample/power_management/test_power_management.c` | `e2a3ca208d122d4996abc948887b63bf8fc646a5a985ea6e00b88185a52c754f` | [[wiki/sources/power-management-sample|高功率申请示例分支]] |
| `samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c` | `4976d4b10c2843259e076379f790e81400ac9e674cf4bae704de81ea413d7768` | [[wiki/sources/gd32-high-power-pin|GD32 高功率 GPIO 示例]] |
| `samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.c` | `56b805bf27b10d3044455c63a02ac218883c63a42e3ae2524210d9211dec17fe` | [[wiki/sources/linux-usb-bulk-implementation|Linux USB Bulk 适配实现]] |
| `samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.h` | `22e7e24e04da2b307d16c615a83a361edb9493f773304eab14b53daf220a1be4` | [[wiki/sources/linux-usb-bulk-config|Linux USB Bulk 端点配置]] |
| `CMakeLists.txt` | `18b663d7bf19f4d9b446dbebc3de84894d6cf30199e7d2e86685473a57f91a59` | [[wiki/sources/root-build-entry|根构建入口的平台范围]] |

另核查 DJI 官方在线接口、电源管理和开发套件说明，访问日期与链接保存在 [[wiki/architecture/high-power-feasibility|可行性评估]]。网页不是本地逐文件摄取身份，不计入上述 8 个文件，也没有虚构快照哈希。

## 后续现场记录

- 2026-09-08 新增第 9 份本地来源：`test/raw/e300-usb-readonly-2026-09-08.json`，SHA-256 `2d67ca29c3f396e272b2c20b7744a5c69126b31d328168b9fbf3106e2821528e`；旧哈希无，首次记录 8 条只读命令。
- [[wiki/sources/e300-usb-readonly-record|来源笔记]] 与 [[wiki/experiments/e300-usb-readonly-2026-09-08|验证记录]] 已建立；未申请电压，未进行 PSDK 通信。
- 相邻 MTT_E300 工程仅作跨库资料回查，未修改或复制原始文件；引用路径、实际复核页码及核查哈希见验证记录，不计入本仓逐文件摄取身份。

## 导航

- [[wiki/index|Wiki 索引]]
- [[wiki/project-overview|项目概览]]
- [[wiki/log|操作日志]]
