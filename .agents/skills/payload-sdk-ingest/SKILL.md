---
name: payload-sdk-ingest
description: 手动摄取 Payload-SDK 的指定资料、来源变化或明确授权的全仓初始化批次，保留逐文件身份与证据边界并维护 Obsidian Wiki。仅在用户显式调用 $payload-sdk-ingest 时使用，不用于普通 SDK 编码或自动摄取新文件。
---

# Payload-SDK 来源摄取

先阅读根级 `AGENTS.md`、`wiki/index.md`、`wiki/sources/source-inventory.md` 和日志最新记录。遵守证据角色及文件权限，不修改来源、不运行 SDK 示例、不访问设备、不提交或推送。

## 模式

- 用户指定文件或范围清晰的目录：只摄取该目标；源码、构建文件和原有工具可在此模式处理。
- 未指定路径或指定 `changed`：运行来源变化检测，默认限 `doc/`、`hardware/` 和未来存在的 `sources/`、`datasheets/`、`test/raw/`。
- 只有用户明确要求“全仓初始化摄取”时，`.` 才表示全仓模式。生成清单后按边界清晰的批次摄取，不把生成清单当作完成摄取。

以下命令从仓库根运行，脚本也支持 `-Root` 指定其他仓库；`-Path`、`-Output` 相对该根解析。需要 PowerShell 5.1 或 7 与 Git，无第三方模块。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/payload-sdk-ingest/scripts/changed_authoritative_sources.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/payload-sdk-ingest/scripts/source_fingerprint.ps1 -Path "hardware/example.pdf"
powershell -NoProfile -ExecutionPolicy Bypass -File .agents/skills/payload-sdk-ingest/scripts/repository_manifest.ps1
```

前两项只读并输出 JSON。扫描器退出码 0 表示扫描完成，仍须查看 `decision_count` 和 `requires_decision`；非零表示扫描失败。涉及删除、重命名、类型变化、未合并、登记冲突、来源缺失或疑似迁移时，先向用户确认再修订相关项目结论。

清单脚本仅在明确调用时写入 `wiki/sources/repository-manifest.csv`；每行独立 SHA-256，状态为 inventoried，不表示已摄取。它排除 Wiki、技能、编辑器状态、缓存和构建产物；第三方库及二进制只登记身份与后续摘要范围。来源指纹拒绝仓库外路径、符号链接及维护产物。被 Git 忽略的未登记资料不自动发现，须指定文件处理。

## 摄取事务

1. 计算指纹，在现有来源笔记搜索路径和 SHA-256。优先复用规范笔记；同内容不同路径先核对是否副本或迁移，不制造重复概念。
2. 读取实际内容并标明范围。SDK 声明、示例实现、设计意图、测量结果分开陈述，缺失版本、平台、单位、时序或连接证据时明确未知。不得把凭据复制进知识库。
3. PDF 中的原理图、图表、公式和关键布局须视觉复核，引用页码；派生文本与截图只放 `wiki/.tmp/`。不可读或无法定位的证据保留 draft，不虚构技术结论。
4. 使用 [来源模板](assets/source-note.md) 建立逐文件来源笔记；使用 [知识页模板](assets/knowledge-page.md) 更新相关规范页面。模板不属于正式 Wiki，替换全部占位内容后才发布。
5. 修订已有路径时记录旧哈希、新哈希、日期和变化摘要，更新受影响的结论；不能只替换哈希。冲突或关键项目约定不明时暂停并向用户提出聚焦问题。
6. 同次更新来源清单、索引，在日志追加 `## [YYYY-MM-DD] ingest | 标题`，包含来源身份、范围与变更页面。
7. 运行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/wiki_lint.ps1`，复核语义后报告来源、页面、检查结果和未解决问题。不宣称扫描成功就等于摄取完成。

## 工具约定

三个脚本复用仓库内 `tools/wiki_common.ps1`，不要单独拷贝脚本到其他项目。元数据格式遵循 AGENTS 中的受限 frontmatter 约定；登记解析失败时扫描必须失败，不把坏记录当作未登记来源继续摄取。

日常用索引和 `rg` 检索。仅当用户明确要求全仓摄取时运行清单；首次搭建框架不运行真实摄取，也不批量生成无证据的专题页。
