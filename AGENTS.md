# Payload-SDK 知识库规范

本仓库保留 DJI Payload SDK 工程，并用 `wiki/` 积累可追溯知识。Wiki 不是 SDK 实现，也不意味着硬件已验证。

## 分层与权限

- 原始资料：`doc/`、`hardware/`；未来存在的 `sources/`、`datasheets/`、`test/raw/` 同属来源层。Wiki 任务不得修改、移动、重命名或删除这些资料。修订测量数据须新增记录。
- 工程实现：`psdk_lib/`、`samples/`、`tools/` 和构建文件。可在用户要求的工程任务中修改；Wiki 任务仅阅读，不调整构建、不运行示例或设备控制代码。
- 知识层：`wiki/`。提取文本、截图和临时分析放入 `wiki/.tmp/`，不回写来源目录；构建产物不复制进 Wiki。
- 保留 `LLM Wiki.md` 理念文档。不自动提交、推送或暂存文件，不夹带已有未跟踪资料。

## 页面与证据

仓库根目录是 Obsidian 库根。中文正文、英文文件名；页面双链使用完整库内路径，例如 `[[wiki/project-overview|项目概览]]`。原始资料使用相对当前页面的标准 Markdown 链接，不写机器绝对路径。

分类按实际内容创建：`architecture/` 系统边界与接口，`concepts/` 稳定概念，`components/` 软件模块与硬件实体，`decisions/` 选择及影响，`experiments/` 验证记录，`sources/` 来源摘要。不创建空白专题来填满分类。

每个正式页面须有 YAML frontmatter，包含 `title`、`type`、`status`、`updated`、`sources`、`tags`。`type` 使用 architecture、concept、component、decision、experiment、source、overview；`status` 使用 draft、verified、superseded；日期为真实的 YYYY-MM-DD。

本地检查器支持明确的 frontmatter 子集：顶层唯一键、单行字符串（无引号、JSON 双引号或 YAML 单引号）、缩进的字符串列表和空列表 `[]`。不支持嵌套映射、多行值、内联非空列表、锚点或标签；不要把该检查器当作通用 YAML 解析器。模板位于摄取技能的 `assets/`。

`sources` 中只列相对仓库根的证据文件路径，不列 Wiki 页面。导航与规划页使用 `sources: []`。来源笔记使用 `type: source`，另需 `source_path`、64 位十六进制 SHA-256 `source_hash`、`ingested_at`；单个文件一份身份，来源清单使用 `type: overview`，无需来源身份。

- 区分 SDK 头文件声明、特定版本示例的实现、硬件设计意图和实测结果。示例不证明全部平台支持，原理图不证明实物工作正常。
- 引用注明文件、符号或页码及适用版本；必要时记录 SDK、平台、飞行器、载荷和固件版本。坐标、单位、时序或供电边界没有证据时明确未知。
- `verified` 仅表示页面范围内的结论已有证据支持，不代表运行、飞行或电气安全验证完成。未分析的材料只标记“待摄取”。
- 来源矛盾写入“冲突与不确定性”，不能静默覆盖。重要项目约定无法确定时先询问用户。凭据、应用密钥和设备隐私不复制到 Wiki。

## 工作流

### 摄取

仅在用户显式调用 `$payload-sdk-ingest` 时加载 `.agents/skills/payload-sdk-ingest/SKILL.md`。普通对话也可按本规范处理明确授权的来源，不因文件出现而自动摄取。

1. 阅读索引、来源清单和日志最新记录，选择一个文件或边界清晰的批次。
2. 记录逐文件指纹，读取证据；图表、原理图不能仅靠文本提取，须视觉复核并保留页码。
3. 更新来源笔记和受影响的规范页面，保留修订前后哈希、版本范围及变化摘要。
4. 同次更新来源清单与索引，在日志追加 `## [YYYY-MM-DD] ingest | 标题`，列出来源与变更页面。
5. 运行结构检查并复核语义。清点文件、计算哈希或生成清单均不等于完成摄取。

### 查询

先读 `wiki/index.md`，再进入相关页面；缺证据、歧义或可能过期时回查原始资料。回答给出可追溯引用。产生可复用知识时回写相应页面，同步索引，并追加 `query` 日志；不把短暂聊天填进 Wiki。

### 检查

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/wiki_lint.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_wiki_tools.ps1
```

检查器检测页面结构、文件级双链及索引可达性，不验证标题锚点、技术语义或硬件能力。还需人工检查过时结论、来源冲突、重复概念、引用缺失与版本漂移。完成检查后追加 `lint` 日志；检查失败不得宣称通过。

日常检索使用索引和 `rg`。不为知识库安装数据库、搜索引擎或网站服务，不复制其他项目的编辑器配置、自动推送或协作约定。
