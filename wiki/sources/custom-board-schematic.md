---
title: 自制转接板原理图
type: source
status: draft
updated: 2026-09-08
sources:
  - hardware/SCH_Schematic2_2026-09-08.pdf
tags:
  - source
  - high-power
source_path: hardware/SCH_Schematic2_2026-09-08.pdf
source_hash: ca31c43b26ab6d7a47e15bcb41963327e32dc4fd6ead4a45f7e1b3405426e3c2
ingested_at: 2026-09-08
---

# 自制转接板原理图

## 来源身份与范围

[原始文件](../../hardware/SCH_Schematic2_2026-09-08.pdf)
- 证据角色：硬件设计意图；文件名日期为 2026-09-08，发布版本、PCB 版本及实物一致性未知。
- 范围：唯一一页（第 1 页）完整视觉复核，另放大检查右下角 JUMP。派生图仅保存在 `wiki/.tmp/high-power/`。
- Poppler 提示缺少 Symbol / ArialUnicode 字体；已在图像中读清本次所用引脚号、网络名和连线，不据此确认所有字形无缺失。

## 证据地图与结论

- 第 1 页 CN1：连接器标注 DF36A-45S-0.4V(51)；36 为 HIGH_PWR_REQ，43 为 ONLINE，35 为 PPS_3V3，37 为 FTS_PWM。
- 第 1 页 JUMP：1/3/5/7 分别为 PPS_3V3 / HIGH_PWR_REQ / FTS_PWM / ONLINE；2/4/6/8 共地。因此 3–4、7–8 跳帽分别将请求、在位信号接地；将 3 与 7 互连并不自动提供接地。
- 第 1 页 CN1 的电源脚聚合为 VCC，另引出 VCC / GND 端子。USB2（器件位号，不是速度名称）为 USB 3.x Type-A 形态接口，1 脚标 VBUS；图中 VBUS 与 VCC 不同名、无可见连接，也无 VCC 到 VBUS 的降压电路。不能把 DJI 文档所称电源 VBUS 和此图 USB VBUS 当作同一网络。
- 第 1 页 USB 2.0 D+/D- 经 U38 共模器件转接；SuperSpeed 路径含 U41 ESD 器件、C1/C2 100 nF 及收发网络映射。本轮不作 USB 3.0 信号完整性或收发映射验收。
- 全页未见 MCU、USB-UART 桥或可执行 PSDK 的处理器，也未见 VCC 路径上的限流、保险丝、反灌保护或 DC/DC。这里只能说“本图未画出”，不能排除外部电路。

## 冲突与不确定性

- PDF 不记录实物跳帽状态。2026-09-08 用户补充确认 JUMP 3–4、7–8 分别接地，飞机为 M400，使用 SkyPort V3 转接环；这属于用户报告，尚无照片或测量佐证。
- 尚无 PCB、BOM 额定值、接线照片、通断/电压测量，不能确认实物 VCC 与 USB VBUS 隔离，更不能判定可承受 24 V 或目标电流。
- PPS 和 FTS 不是本次申请跳帽，不能因其也在 JUMP 上而一并短接。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `ca31c43b26ab6d7a47e15bcb41963327e32dc4fd6ead4a45f7e1b3405426e3c2`。本轮仅建立上述范围的结论，未修改来源。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]
