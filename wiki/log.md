---
title: Payload-SDK Wiki 操作日志
type: overview
status: draft
updated: 2026-09-08
sources: []
tags:
  - log
---

# 操作日志

追加记录，不重写已发生的历史。日期使用实际操作日；操作类别为 init、ingest、query、lint。结构检查不代表语义或硬件验证。

## [2026-09-08] init | 建立知识库框架

- 按用户确认的范围，原位增加规范、索引、概览、来源清单、模板、手动摄取技能及维护工具。
- 初始页面：[[wiki/index|索引]]、[[wiki/project-overview|概览]]、[[wiki/sources/source-inventory|来源清单]]、本日志。
- 来源均待摄取；未读取原理图内容，未执行 SDK 构建或硬件测试。
- 本条仅记录初始化，不预先声明检查通过；实际验证结果在完成后追加。

## [2026-09-08] lint | 框架与维护工具验收

- `wiki_lint.ps1`：4 个正式页面，零错误、零警告；索引覆盖全部页面。
- `test_wiki_tools.ps1`：PowerShell 5.1 和 PowerShell 7 下各通过 35 项隔离回归检查。覆盖字段、真实日期、来源身份、链接、示例排除、中文路径、Git 增删改名、哈希漂移、登记冲突、清单边界及只读保证。
- 摄取技能通过 skill-creator 的 `quick_validate.py`；显式调用策略、UI 元数据、模板资源引用另行通过校验。7 份页面或技能模板的 YAML 可解析，24 处本地 Markdown 引用存在。正式维护脚本无需第三方模块。
- 当前仓库只读变更检测发现 6 个待摄取候选，其中包括现有硬件 PDF；未执行摄取，未在实际仓库生成逐文件清单或技术来源笔记。
- 已跟踪文件中仅 README 追加入口；SDK 源码与库文件无差异。CMake、硬件 PDF 和 `LLM Wiki.md` 的 SHA-256 与改造前一致；用户编辑器配置未改动。
- 本次检查仅验证框架与工具；不代表 SDK 构建、原理图语义、设备运行或飞行测试通过。未暂存、提交或推送任何变更。

## [2026-09-08] ingest | M400 SkyPort V3 自制板高功率可行性

- 用户显式调用摄取技能，授权相关硬件与申请流程分析，要求不急于行动。用户补充确认 JUMP 7–8、3–4 分别接地，M400 使用 SkyPort V3；仅作用户报告，不当作实测。
- 首次摄取 8 个文件，旧哈希均无。逐文件完整新 SHA-256、路径及范围登记在 [[wiki/sources/source-inventory|来源清单]] 及各来源笔记，未采用目录哈希。
- 来源：hardware/SCH_Schematic2_2026-09-08.pdf（第 1 页完整视觉复核及 JUMP 放大）；psdk_lib/include/dji_power_management.h；psdk_lib/include/dji_version.h；samples/sample_c/module_sample/power_management/test_power_management.c；samples/sample_c/platform/rtos_freertos/gd32f527_development_board/drivers/BSP/apply_high_power.c；samples/sample_c/platform/linux/raspberry_pi/hal/hal_usb_bulk.c 与 hal_usb_bulk.h；CMakeLists.txt。
- 新页面：[[wiki/architecture/high-power-feasibility|可行性评估]]、[[wiki/sources/custom-board-schematic|自制原理图]]、[[wiki/sources/power-management-api|电源 API]]、[[wiki/sources/sdk-version|版本]]、[[wiki/sources/power-management-sample|电源示例]]、[[wiki/sources/gd32-high-power-pin|GD32 GPIO]]、[[wiki/sources/linux-usb-bulk-implementation|Linux USB 实现]]、[[wiki/sources/linux-usb-bulk-config|USB 端点配置]]、[[wiki/sources/root-build-entry|构建入口]]。
- 同步更新 [[wiki/index|索引]]、[[wiki/project-overview|概览]]、[[wiki/sources/source-inventory|来源清单]] 和本日志。官方在线核查链接/日期放入评估，不伪造本地网页身份。
- 结论范围：两组接地与目标接口规范一致；电压选择仍需 SDK 通信。被动板未提供电脑 Host 到飞机 Host 的 Device/协议桥能力。VCC 与 USB VBUS 在图中分离，实物与承载能力未验证。
- 明确保留示例注释与实际分支的冲突、固定接地与 GPIO 回调适配的不确定性。截图只放 wiki/.tmp/high-power/；未修改来源或实现、未访问 USB、未构建/运行示例、未暂存/提交/推送。
- 本条不预先宣称检查通过，实际结果在检查完成后追加。

## [2026-09-08] lint | 高功率定向摄取验收

- Windows PowerShell 执行 wiki_lint.ps1：13 个正式页面，零错误、零警告；执行 test_wiki_tools.ps1：35 项隔离回归检查全部通过。
- 对 8 个摄取来源重新计算 SHA-256，全部与本轮登记一致，来源文件没有变化。
- 人工语义复核：区分 API 声明、示例条件分支、PDF 设计、用户接线报告和官方在线规范；确认用户已补充 SkyPort V3；保留 USB 角色、固定接地回调、实物隔离及功率承受的未知项。
- 结构通过不代表 USB 通信、SDK 运行、电气或飞行验证。本轮无设备访问、无工程实现修改、无暂存/提交/推送。

## [2026-09-08] query | 24 V 目标与 E300 只读能力评估

- 用户明确目标 24 V，指定 MTT_E300 参考工程并授权 SSH 登录。成功连接后只读查询系统、UDC、USB role、内核配置、开发包与 Host 拓扑，未提权或修改设备配置。
- 新增原始选择性命令记录 test/raw/e300-usb-readonly-2026-09-08.json；首次身份 SHA-256 为 2d67ca29c3f396e272b2c20b7744a5c69126b31d328168b9fbf3106e2821528e。记录不含网络地址、账号或密码，后续不覆盖。
- 新增 [[wiki/sources/e300-usb-readonly-record|探测来源]] 与 [[wiki/experiments/e300-usb-readonly-2026-09-08|E300 只读验证]]，同步 [[wiki/architecture/high-power-feasibility|总评估]]、[[wiki/index|索引]]、[[wiki/sources/source-inventory|来源清单]]、[[wiki/project-overview|概览]]。
- MTT_E300 工程仅只读回查；M1000 模组手册第 5、8 页已视觉复核。未复制来源或其他项目配置，派生分析和截图只放本仓 wiki/.tmp/high-power/。
- 当前观察：ARM64 Ubuntu 和开发包具备基础，UDC 目录为空，M1000_UDC 配置未启用；不将 role-switch 节点或 gadget 框架当作已可用 Device，也不断言硬件永久不支持。
- 用户随后收窄验收：M1000 独立供电，自制板图示 VCC/GND 由用户万用表测得 24 V 即通过。不再把 M1000 输入电压、DC/DC、负载电流或带载测试列为本次前置条件。
- 剩余范围仅为通信链路、SDK 初始化及固定接地回调适配、24 V 申请和用户测压。尚未申请或测量，不标记通过；未构建/运行示例、未加载模块/切换 USB 角色、未改变网络/时钟、未暂存/提交/推送。

## [2026-09-08] lint | E300 探测与电压验收范围检查

- Windows PowerShell 执行 wiki_lint.ps1：15 个正式页面，零错误、零警告；test_wiki_tools.ps1 的 35 项隔离回归全部通过。
- 语义复核确认：用户指定的 24 V 测点验收不被模组输入电源或带载测试扩展；SSH 只读结果不冒充 PSDK 通信或 Device 枚举成功。
- 新现场记录保留独立 SHA-256 且不含地址、账号、密码；外部工程只回查，不复制配置或伪造本仓来源身份。图像与临时解析脚本仅存 wiki/.tmp/。
- 本次工具检查不是 24 V 验收，申请与用户万用表读数仍未发生。

## [2026-09-08] lint | 公开 fork 上传前检查

- 用户明确批准将 Wiki、自制硬件原理图和脱敏探测记录上传到自己的公开 fork；本条记录发布前检查，不预先宣称推送成功。
- wiki_lint.ps1：15 页，零错误、零警告；test_wiki_tools.ps1：35 项隔离回归全部通过。9 个已登记来源重新计算 SHA-256，均与来源笔记一致。
- 对待上传的 30 个文本文件进行常见令牌、私钥、口令赋值、内网地址和本机用户目录模式检查，未发现匹配；此检查不声称能发现所有敏感内容。原理图沿用已视觉复核的原文件，未改动。
- .gitignore 排除整个 .obsidian/ 和 wiki/.tmp/；编辑器设置、会话、派生截图和临时分析不上传。README 入口同步实际摄取状态，不再宣称资料均待摄取。
- MTT_E300 跨库资料仅保留带页码及哈希的引用，不将该工程文件复制进本次上传；这些引用在单独克隆本仓时不可用，现有验证页已说明限制。
- 本次不修改 SDK 实现或原始资料，不运行 SDK，也不把结构检查或上传当作 24 V 测压验收。
- 发布检查发现本机 core.autocrlf=true，补充 .gitattributes 将 PDF 标为 binary，并禁用 test/raw/ 的换行转换；已核对暂存 PDF/探测记录与工作区原文件的 Git blob 标识一致。默认 diff 空白检查另报告部分页末空行，原始记录不为消除此类样式提示而改写。
