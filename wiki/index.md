---
title: Payload-SDK Wiki 索引
type: overview
status: draft
updated: 2026-09-08
sources: []
tags:
  - index
  - payload-sdk
---

# Payload-SDK Wiki

持久化项目知识库入口。已摄取首批 8 个本地文件及后续 1 份 E300 只读 SSH 记录，并补充核查官方接口说明；尚未进行 PSDK 通信、电压申请或飞行验证。

## 从这里开始

- [[wiki/project-overview|项目概览]]：仓库身份、目录职责与知识边界。
- [[wiki/sources/source-inventory|来源清单]]：资料位置及待摄取状态。
- [[wiki/log|操作日志]]：初始化、摄取、查询回写与检查的追加记录。

## 分类

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]：M400 / SkyPort V3、跳帽与供电边界、USB 角色、申请 API 和待确认条件。状态 draft，不是操作授权。
- [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 只读 SSH 验证]]：已登录，ARM64 环境具备基础，当前 UDC 为空；用户要求 E300 独立供电，仅以自制板 VCC/GND 测得 24 V 验收。
- [[wiki/sources/source-inventory|逐文件来源登记]]：原理图、电源 API、示例、版本及 Linux USB / 构建入口的来源笔记。

其他分类后续按实际证据创建，不为尚不存在的专题创建链接。

## 维护入口

- [知识库规范](../AGENTS.md)
- [手动摄取技能](../.agents/skills/payload-sdk-ingest/SKILL.md)
- [LLM Wiki 理念](../LLM%20Wiki.md)
