---
title: 电源管理 API 声明
type: source
status: verified
updated: 2026-09-08
sources:
  - psdk_lib/include/dji_power_management.h
tags:
  - source
  - high-power
source_path: psdk_lib/include/dji_power_management.h
source_hash: 51cfcbcab2f3fd54e377a3b7b0fb09bfe805a8ed68abb33543ccfd65e4649b63
ingested_at: 2026-09-08
---

# 电源管理 API 声明

## 来源身份与范围

[原始文件](../../psdk_lib/include/dji_power_management.h)
- 证据角色：本仓 SDK 公共头文件声明。全文件阅读；高功率 API 为主要摄取范围。
- 对应本仓版本见 [[wiki/sources/sdk-version|版本声明]]；不是已链接二进制的运行查询。

## 证据地图与结论

- `DjiPowerManagement_Init`：使用电源管理前初始化。
- `DjiPowerManagement_RegWriteHighPowerApplyPinCallback`：头文件要求在申请前注册引脚写回调；枚举 RESET 为低、SET 为高。
- `DjiPowerManagement_ApplyHighPowerSync` 与 `DjiPowerManagement_ApplyHighPowerSyncV2`：向飞机同步申请高功率；注释给出的最长执行时间略大于 600 ms。
- V2 使用 `E_DjiHighPowerVoltage`，枚举电压 13.6 / 17 / 24 V。声明本身不证明所有飞机、转接器或固件都支持每一档。
- `DjiPowerManagement_OutputHighPower` 专用于 Manifold 3 对外高压输出，不是本自制转接板向飞机请求电源的替代 API。
- 关机回调不得阻塞；头文件说明准备等待时间为 10 s。

## 冲突与不确定性

- 无 SDK 私有实现，未确认固定接地时 SDK 回调的实际调用顺序、重试行为或是否可以省略回调。
- API 成功返回不等于负载端实测电压正确，也不等于获得额外于平台规格的功率。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `51cfcbcab2f3fd54e377a3b7b0fb09bfe805a8ed68abb33543ccfd65e4649b63`。本轮仅建立上述范围的结论，未修改来源。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]

