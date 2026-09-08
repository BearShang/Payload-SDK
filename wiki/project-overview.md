---
title: Payload-SDK 项目概览
type: overview
status: draft
updated: 2026-09-08
sources: []
tags:
  - overview
  - payload-sdk
---

# 项目概览

当前仓库为 DJI Payload SDK 工程。本页提供导航，不是平台支持承诺。首批已建立电源管理、自制板和通信边界的来源笔记；本地版本头文件声明为 3.16.0（build 2338），不是运行时确认。

## 目录职责

| 位置 | 文件层面用途 | 知识状态 |
| --- | --- | --- |
| [README](../README.md) | 上游项目说明与文档入口 | 待摄取 |
| [CMakeLists](../CMakeLists.txt) | 根构建入口 | 平台分支已摄取，未执行构建 |
| [psdk_lib](../psdk_lib/) | SDK 头文件与库文件 | 电源与版本头文件已摄取，其余待摄取 |
| [samples](../samples/) | C/C++ 示例与平台适配目录 | 电源/GD32 GPIO/Linux USB 定向摄取，未运行 |
| [doc](../doc/) | 参考设计与随仓资料 | 待摄取 |
| [hardware](../hardware/) | 当前项目的硬件资料 | 单页 PDF 已视觉复核供电/跳帽/USB 拓扑，发布状态及实物未验证 |
| [tools](../tools/) | 随仓工具及本轮增加的 Wiki 工具 | 原有工具待摄取 |
| [LLM Wiki](../LLM%20Wiki.md) | 知识库理念说明 | 保留原文，未建立来源笔记 |

## 当前边界

已完成 [[wiki/architecture/high-power-feasibility|自制板高功率申请可行性]] 的定向资料分析，并经用户授权完成 [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 只读 SSH 能力探测]]。目标明确为独立供电的 E300 运行申请程序，用户在自制板 VCC/GND 测到 24 V 即通过。没有完成 SDK 启动链路的全面摄取，也没有进行 SDK 编译/运行、电压申请、电气测量或飞行测试。

后续摄取须保留 SDK 声明、示例行为、设计意图和实测结果之间的区别。实际开发平台、目标载荷、飞行器和硬件适配状态仍须在具体任务中依据资料确认。

## 相关页面

- [[wiki/index|Wiki 索引]]
- [[wiki/sources/source-inventory|来源清单]]
