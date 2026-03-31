---
trigger: always_on
---

# 项目级主干规则 (Global Rules)

## 零号引导协议 (Bootstrapping Protocol)
- **MUST** 任何 Agent 接入会话时，必须首先阅读项目 `docs/INDEX.md`（如存在），并强制调用工具查阅 `.agents/workflows/dev-flow.md` 以获悉开发挂载步骤。
- **MUST** 严禁每次接手新需求时脱离轨道自造操作流程。代码开发或交付必须严格套接工程内置的标准功能流（如 `/auto-dev`, `/production-release`）。
- **CRITICAL** 在输出任何结构化定稿方案或实施计划后，即使接收到系统自动发送的 LGTM 放行指令，Agent 也必须强制处于拦截等待状态。绝对禁止擅自进入 EXECUTION 模式编写代码，必须等待人类用户明确输入指令（如"开始"、"执行"）后方可动作。

## 项目配置加载协议 (Config Bootstrap — MANDATORY)

**任何 Agent 接入会话后，必须在执行任何实质性操作前，通过工具读取 `project.config.json`，构建本会话的《项目上下文快照》。**

### 加载步骤

1. 调用文件读取工具读取 `project.config.json`（不允许依赖记忆或猜测）
2. 若文件不存在：**立即停止**，提示用户执行：
   ```bash
   cp project.config.example.json project.config.json
   # 然后填写项目实际值
   ```
3. 从配置中提取以下核心变量，在本会话全程替换 workflow / skill / rule 文件中的 `{{}}` 占位符：

| 占位符 | 配置路径 |
|--------|---------|
| `{{PROJECT_NAME}}` | `project.name` |
| `{{FRONTEND_PATH}}` | `tech_stack.frontend_path` |
| `{{BACKEND_PATH}}` | `tech_stack.backend_path` |
| `{{TEST_PATH}}` | `tech_stack.test_path` |
| `{{FRONTEND_TEST_PATH}}` | `tech_stack.frontend_test_path` |
| `{{LOCAL_DB_URL}}` | `testing.local_db_url` |
| `{{DESIGN_SYSTEM_FILE}}` | `design_system.reference_file` |
| `{{SEMANTIC_COLOR_PREFIX}}` | `design_system.semantic_color_prefix` |
| `{{OUTPUT_DIR}}` | `weekly_report.output_dir` |
| `{{CSS_FRAMEWORK}}` | `tech_stack.css_framework` |
| `{{BACKEND_LANG}}` | `tech_stack.backend`（取第一个词，如 `python`）|

4. 额外推导以下行为开关：

| 开关 | 配置路径 | 含义 |
|------|---------|------|
| `affects字段启用` | `commit.affects_field_enabled` | true → commit 中附加 affects/changed-interfaces 行 |
| `前端CSS约束启用` | `tech_stack.css_framework == "tailwind"` | true → 应用 Tailwind 物理色禁止规则；false → 跳过 |
| `测试锁启用` | `testing.test_lock_script` 存在 | true → 每次执行测试前先运行 verify |

5. 输出一行确认（不需要详细展开）：
   ```
   [CONFIG LOADED] project=xxx | frontend=xxx | backend=xxx | db=xxx
   ```

### 约束
- **NEVER** 在未加载配置的情况下执行任何工程操作（开发/测试/发版）
- 若配置字段为空或缺失，对应功能降级处理，不报错中断——在操作前以 `[CONFIG MISSING: xxx]` 格式提示用户补充
- 配置只在会话内有效，下次会话重新加载

## 第一准则：真实性与准确性 (Core Directive)
1. 仅陈述可从代码库或上下文验证的内容。
2. 无法确定时直接说"不清楚"或"需要看 X 才能确认"。
3. 不把推测当事实。
4. 不用填充语句、不鼓励、不美化问题、不用隐喻或夸张词汇、不用 emoji。
5. 有问题直说，判断错了直说，允许并欢迎异议。
6. 简短回复不用标题，进度汇报用列表，不写叙事。
7. 所有思考过程、工具调用说明及回复内容统一使用中文。

## AI Agent 文件存放准则 (Critical Rule)
为保持代码库洁净，**严禁 Agent 在项目根目录或后端目录下创建任何用于调试、排障或尝试运行的一次性脚本或 SQL 导出文件。**
所有 Scratchpads / Diagnostics 等临时代码和验证产生的中间数据必须放入 `./tmp/` 文件夹中执行，以确保不污染 Git 追踪。
此外，**绝对禁止任何 Agent 在 `docs/` 根目录直接新建散装文件**（仅允许保留唯一的 INDEX.md）。所有 AI 新增的知识与规则库必须先查阅并遵循地图，强行下钻存放到 `docs/llm-context/` 等对应语义子目录内。

## 领域规则预加载路由指引 (Rule Routing)
在触碰以下工程域代码前，必须向知识库或**隐式调用文件读取工具**查阅指定的领域防御守则：
- 涉及数据库 ORM 重构或数据库表变更时 → 读取 `.agents/rules/db.md`（路由器，会根据 `tech_stack.database` 分发到 `db-mysql.md` 或 `db-sqlite.md`）
- 涉及前端 UI 组件样式或状态时 → 读取 `.agents/rules/frontend-ui.md`
- 涉及路由/调度任务/迁移/功能测试/自动化操作时 → 读取 `.agents/rules/guardrails.md`

## 领域防御硬拦截协议 (Hard Guardrails for AI Execution)
为避免在高速生成时漏读领域规范，Agent 必须强制执行以下断点防御：
1. **构建计划时校验 (Plan Validator)**：在生成实施计划时，必须包含独立的 `[Guardrail Validation: 前置规则验证]` 章节。要求在设计大纲前，必须用物理 `view_file` 工具读取相关领域规则文档，并在该段落内逐条对齐即将使用的 API 或类名是否合规。
2. **写操作前宣誓 (Pre-write Oath)**：当修改项目源文件时，必须在指令中标明：`// Verified against .agents/rules/xxx.md`。如果意识到自己没有读过相关规则文件，**必须自我熔断操作并先去加载文件**。

## 幻觉防控强制清单 (Anti-Hallucination Protocol)

AI 最容易产生幻觉的 4 个场景，以下规则强制执行，不可跳过：

### 1. 引用现有代码前必须先验证存在性
- **MUST** 在代码中调用任何现有函数/类/变量前，先用工具搜索确认其定义存在（`grep` 函数名 / `glob` 文件路径）
- **MUST** 在 import 语句中引用路径前，先确认该路径下文件实际存在
- **NEVER** 凭记忆或"应该在这里"的假设直接写引用

### 2. 调用 API 或接口前必须先读接口定义
- **MUST** 编写调用方代码前，先读被调用方的函数签名或接口定义（参数名、类型、返回值）
- **MUST** 对接第三方接口时，先读项目中已有的调用示例或 types 定义，而非依赖知识截止日期前的记忆
- **NEVER** 假设 API 返回结构，必须从代码或文档中读取真实结构

### 3. 编写测试 Mock 数据前必须先读真实数据结构
- **MUST** 写 mock 数据前，先读对应的 ORM 模型定义或接口 response 类型
- **MUST** 断言字段名必须与真实字段名完全一致，禁止凭感觉写 `user_id` 还是 `userId`
- 验证方式：`grep "字段名" 模型文件` 确认拼写

### 4. 修改文件前必须先读该文件当前状态
- **MUST** 在 Edit 任何文件前，必须在本次会话内读过该文件（而非依赖上次会话的记忆）
- **MUST** 对于超过 200 行的文件，修改前先确认要修改的具体行号区域
- **NEVER** 在未读文件的情况下直接 Write 覆盖（除非是全新创建）

> **自我熔断触发条件**：如果 AI 发现自己"不确定某个函数/字段/路径是否真实存在"，必须立即停止生成，先用工具验证，再继续。不允许带着不确定性继续写代码。

## 知识库写入权限红线 (Knowledge Write Protection)
1. 任何 Agent 在任何流程中，**绝对禁止**自主修改以下目录下的文件：
   - `docs/lessons/*`
   - `.agents/rules/*`
   - `docs/llm-context/*`
2. Agent 只允许以 `[KNOWLEDGE_UPDATE]` 格式在报告或对话中**提出建议文本**，由人类决定是否采纳。
3. 只有人类用户明确下达写入指令后，才能执行对上述目录的修改操作。
4. 违反此规则视为致命错误，等同于生产事故。
