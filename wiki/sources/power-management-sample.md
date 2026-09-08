---
title: 高功率申请示例分支
type: source
status: verified
updated: 2026-09-08
sources:
  - samples/sample_c/module_sample/power_management/test_power_management.c
tags:
  - source
  - high-power
source_path: samples/sample_c/module_sample/power_management/test_power_management.c
source_hash: e2a3ca208d122d4996abc948887b63bf8fc646a5a985ea6e00b88185a52c754f
ingested_at: 2026-09-08
---

# 高功率申请示例分支

## 来源身份与范围

[原始文件](../../samples/sample_c/module_sample/power_management/test_power_management.c)
- 全文件阅读，证据角色为本仓特定示例实现；版本边界见 [[wiki/sources/sdk-version|SDK 版本声明]]。

## 证据地图与结论

- `DjiTest_RegApplyHighPowerHandler` 要求 pinInit 和 pinWrite 均非空，再保存处理器。
- `DjiTest_PowerManagementStartService` 先初始化电源管理、获取飞机基础信息。
- SkyPort V2、X-Port、SkyPort V3、E-Port V2 ribbon cable，或 aircraftType 为 FC30 时进入申请分支；分支要求引脚处理器，执行 pinInit 并注册 pinWrite。
- SkyPort V3 / E-Port V2 ribbon cable 分支选择 V2，示例固定请求 17 V；其他上述分支使用旧 API。退出申请分支后还会注册关机通知。
- 不能仅凭这个服务函数成功返回认定已申请：不匹配申请分支时也可能走到最后返回成功。

## 冲突与不确定性

- 注释声称仅 RTOS 申请、Linux 不申请，但该函数实际以飞机/适配器分支判断，没有相应 OS 条件编译。应区分过时注释、函数实现以及尚未完整摄取的上层调用链。
- 未运行，未验证平台覆盖；示例默认 17 V 不代表本项目已经选定 17 V。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `e2a3ca208d122d4996abc948887b63bf8fc646a5a985ea6e00b88185a52c754f`。本轮仅建立上述范围的结论，未修改来源。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]

