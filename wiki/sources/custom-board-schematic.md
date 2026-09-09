---
title: 自制转接板原理图
type: source
status: draft
updated: 2026-09-09
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

### 2026-09-09 CN1 逐脚复核

用户报告 CN1 到 U38 的通断正常，未提供测量端点编号/电阻值或 PCB。再次核对原始 PDF 哈希未变，视觉复核第 1 页 CN1 全部 1–45 号连接，并对照 [DJI 官方 E-Port V2/SkyPort V3 同轴接口定义](https://developer.dji.com/doc/payload-sdk-tutorial/cn/payload-quick-start/configure-the-hardware-environment/drone-port.html)（核查日 2026-09-09）：

| CN1 脚号 | DJI 定义 | 原理图连接 | 判断 |
| --- | --- | --- | --- |
| 1–4、11、14、21–28、44、45 | GND | GND | 一致 |
| 5、6、38 | NC | 不连接标记 | 一致 |
| 7–10、15–18、31–34、39–42 | 飞机电源 VBUS | VCC | 分组一致，仅网络命名不同 |
| 12 | USB_DP | USB_D+ | 一致 |
| 13 | USB_DM | USB_D- | 一致 |
| 19 | USB3.0_RX_N | USB_RX- | 一致 |
| 20 | USB3.0_RX_P | USB_RX+ | 一致 |
| 29 | USB3.0_TX_P | USB_TX+ | 一致 |
| 30 | USB3.0_TX_N | USB_TX- | 一致 |
| 35 | PPS | PPS_3V3 | 一致 |
| 36 | HIGH_PWR_REQ | HIGH_PWR_REQ | 一致 |
| 37 | FTS PWM | FTS_PWM | 一致 |
| 43 | ONLINE | ONLINE | 一致 |

特别复核 10/18/34/42 接各自 VCC 竖线，21–28 全部接 GND；不能因相邻网络或缩略图误读成电源/地对调。此处仅认定图纸编号到网络的映射一致，不判定 PCB 或实装无误，也未检查 SuperSpeed 全链路的收发方向。

DJI 说明官方板用白点标记 1 号脚，同轴插头在规定引脚面视图的右侧为 1 号；不可把插头接触面视图机械套用到 PCB 俯视图。[Hirose DF36 官方系列目录](https://www.hirose.com/en/product/document?clcode=CL0662-4011-4-51&documentid=en_DF36_CAT&documenttype=Catalog&lang=en&productname=DF36A-25S-0.4V%2851%29&series=DF36) 第 6 页标准型插座图已视觉复核，明确标出 Contact No.1，并列出 DF36A-45S 型号；派生图在 wiki/.tmp/high-power/hirose-df36-p6.png。渲染有字体替换警告，但编号标记、插座外形和 45S 行可读。

仍待核查 CN1 的 PCB footprint 焊盘编号与实际插座的对应，特别是 1/45 方向、12/13 所在端。图中额外编号 46–56 全接地，但它们不属于 DJI 的 45 个信号脚；需用实际封装确认是否全部为屏蔽/固定焊盘，不能仅凭原理图确认。下一步需要带焊盘号和网络名的 CN1 PCB 局部图或源文件，不建议根据尚未成立的错脚假设改线。

- PDF 不记录实物跳帽状态。2026-09-08 用户补充确认 JUMP 3–4、7–8 分别接地，飞机为 M400，使用 SkyPort V3 转接环；这属于用户报告，尚无照片或测量佐证。
- 尚无 PCB、BOM 额定值、接线照片、通断/电压测量，不能确认实物 VCC 与 USB VBUS 隔离，更不能判定可承受 24 V 或目标电流。
- PPS 和 FTS 不是本次申请跳帽，不能因其也在 JUMP 上而一并短接。

## 修订历史

- 2026-09-08：首次摄取；旧哈希无，新哈希 `ca31c43b26ab6d7a47e15bcb41963327e32dc4fd6ead4a45f7e1b3405426e3c2`。本轮仅建立上述范围的结论，未修改来源。
- 2026-09-09：查询回查 CN1 1–45 脚；原始文件 SHA-256 不变，逐脚网络与 DJI 在线定义一致，新增封装/实装编号方向的未验证边界。未重新摄取文件或改变 ingested_at。

## 相关页面

- [[wiki/architecture/high-power-feasibility|自制板高功率可行性]]
- [[wiki/sources/source-inventory|来源清单]]
- [[wiki/index|Wiki 索引]]
