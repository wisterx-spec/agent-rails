---
trigger: always_on
---

# 项目级主干规则 (Global Rules)

## 零号引导协议 (Bootstrapping Protocol)
- **MUST** 任何 Agent 接入会话时，必须首先阅读项目 `docs/INDEX.md`（如存在），并强制调用工具查阅 `.agents/workflows/dev-flow.md` 以获悉开发挂载步骤。
- **MUST** 严禁每次接手新需求时脱离轨道自造操作流程。代码开发或交付必须严格套接工程内置的标准功能流（如 `/auto-dev`, `/production-release`）。
- **CRITICAL** 在输出任何结构化定稿方案或实施计划后，即使接收到系统自动发送的 LGTM 放行指令，Agent 也必须强制处于拦截等待状态。绝对禁止擅自进入 EXECUTION 模式编写代码，必须等待人类用户明确输入指令（如"开始"、"执行"）后方可动作。

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
- 涉及数据库 ORM 重构或数据库表变更时 → 读取 `.agents/rules/db.md`
- 涉及前端 UI 组件样式或状态时 → 读取 `.agents/rules/frontend-ui.md`
- 涉及路由/调度任务/迁移/功能测试/自动化操作时 → 读取 `.agents/rules/guardrails.md`

## 领域防御硬拦截协议 (Hard Guardrails for AI Execution)
为避免在高速生成时漏读领域规范，Agent 必须强制执行以下断点防御：
1. **构建计划时校验 (Plan Validator)**：在生成实施计划时，必须包含独立的 `[Guardrail Validation: 前置规则验证]` 章节。要求在设计大纲前，必须用物理 `view_file` 工具读取相关领域规则文档，并在该段落内逐条对齐即将使用的 API 或类名是否合规。
2. **写操作前宣誓 (Pre-write Oath)**：当修改项目源文件时，必须在指令中标明：`// Verified against .agents/rules/xxx.md`。如果意识到自己没有读过相关规则文件，**必须自我熔断操作并先去加载文件**。

## 知识库写入权限红线 (Knowledge Write Protection)
1. 任何 Agent 在任何流程中，**绝对禁止**自主修改以下目录下的文件：
   - `docs/lessons/*`
   - `.agents/rules/*`
   - `docs/llm-context/*`
2. Agent 只允许以 `[KNOWLEDGE_UPDATE]` 格式在报告或对话中**提出建议文本**，由人类决定是否采纳。
3. 只有人类用户明确下达写入指令后，才能执行对上述目录的修改操作。
4. 违反此规则视为致命错误，等同于生产事故。
