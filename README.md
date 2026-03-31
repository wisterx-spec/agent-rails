# ai-dev-workflow

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Claude Code](https://img.shields.io/badge/Platform-Claude_Code-blue)](https://claude.ai/code)
[![Works with: GPT-4o](https://img.shields.io/badge/Works_with-GPT--4o-green)]()

一套可移植的 AI 辅助开发规范框架。给 AI 套上约束和流程，让它在项目里持续可靠地工作。

**设计原则：放在一起是流程，单独拿出来是 skill。**

每个工作流由若干独立 skill 组成，skill 也可以单独调用。框架本身不绑定任何项目，通过 `project.config.json` 注入项目特异参数后开箱即用。

---

## 解决什么问题

| 痛点 | 框架如何解决 |
|------|------------|
| 开发完才看到，和预期不符 | requirement-clarification 需求澄清 + Frontend-First，UI 确认后再开发后端 |
| 新需求把老功能改坏 | impact-analysis 影响分析 + test-lock 测试基线保护 |
| 项目没有规范，一个接口一套写法 | `docs/conventions.md` 活的约定文档，AI 每次任务前必读 |
| 没有抽组件、重复造轮子 | 新建组件前强制 grep 现有同类，有候选必须说明为何不复用 |
| 越改越乱，屎山越堆越大 | `/slim` 定期瘦身 + commit 前双重门禁 |
| AI 产生幻觉，引用不存在的函数 | 4 场景幻觉防控强制清单，自我熔断机制 |

---

## 运行环境与模型要求

### 硬性前提

框架依赖 AI 的**文件读写工具（tool use）**，纯对话模式无法运行。最低要求：

- 支持 tool use / function calling
- 上下文窗口 ≥ 32K tokens

### 推荐模型

| 模型 | 适配程度 | 备注 |
|------|---------|------|
| Claude Sonnet 3.5 / 4+ | 完全适配 | 框架基于此设计，指令遵循与自我评估质量最佳 |
| Claude Opus | 完全适配 | 适合更复杂任务，成本更高 |
| GPT-4o | 基本可用 | 工具调用稳定，但需手动触发工作流（见平台适配） |
| Gemini 1.5 Pro+ | 基本可用 | 类似 GPT-4o，需适配触发方式 |
| 本地小模型（≤ 13B） | 不推荐 | 复杂指令遵循质量不足，Ralph-loop 可靠性低 |

### 平台适配说明

#### Claude Code（原生，推荐）

框架为 Claude Code 设计，开箱即用：

- `.agents/rules/` 中标注 `trigger: always_on` 的规则自动加载，无需手动触发
- `/skill-name` slash command 直接触发对应 skill
- 文件读写工具（Read / Edit / Grep / Glob / Bash）与框架约定完全匹配

```bash
./install.sh /path/to/project   # 安装
# 在 Claude Code 中打开项目目录即可使用
```

#### Cursor / Continue.dev / Windsurf

可用，但需手动适配：

1. 将 `.agents/rules/` 中的核心规则内容复制到平台的 System Prompt 或 `.cursorrules`
2. 触发工作流时，直接在对话中输入工作流名称（如"执行 auto-dev 工作流"），而非 `/auto-dev`
3. Skill 的 slash command 需替换为自然语言指令（如"执行 commit-with-affects skill"）
4. 文件工具名称不同，AI 会自行映射，但建议验证 Read/Edit/Bash 是否可用

```
# 在 .cursorrules 或 system prompt 中添加：
请在每次任务开始前读取 .agents/rules/core.md 中的规则。
```

#### 直接 API 调用（程序化使用）

适合将框架嵌入自动化流水线：

1. 将 `core.md`、`guardrails.md` 内容作为 system prompt
2. 将目标 workflow 的 `.md` 内容作为 user prompt 的前置上下文
3. 确保 API 调用启用了 tool use，并挂载文件读写工具
4. 每次对话需重新加载规则（无 always_on 机制）

#### 不适用的场景

- 无 tool use 的纯对话 API 调用
- GitHub Copilot（不支持自定义工作流规则注入）
- 网页版 ChatGPT / Claude.ai（无项目级文件读取能力）

---

## 5 分钟快速上手

### 1. 安装

```bash
git clone https://github.com/wisterx-spec/agent-rails.git
cd ai-dev-workflow
./install.sh /path/to/your-project
```

### 2. 最小配置

编辑目标项目的 `project.config.json`，至少填写以下字段：

```jsonc
{
  "project": { "name": "your-project" },
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",
    "backend": "python+fastapi",
    "backend_path": "backend/app",
    "test_path": "backend/tests",
    "database": "mysql"          // mysql | sqlite | postgres
  },
  "testing": {
    "local_db_url": "mysql+pymysql://user:pass@localhost:3306/test_db"
  }
}
```

其余字段可按需补充，缺失字段会降级处理，不影响启动。

### 3. 在 Claude Code 中使用

用 Claude Code 打开项目目录，输入第一个指令：

```
/requirement-clarification  ← 从需求澄清开始（推荐）
```

或直接开始开发：

```
/auto-dev 实现用户登录功能，支持邮箱+密码
```

### 4. 预期看到什么

```
[CONFIG LOADED] project=your-project | frontend=react+typescript | backend=python+fastapi | db=mysql

阶段零：规范预加载
→ 读取 docs/conventions.md 核心约定速查区块
→ 读取 docs/decisions/README.md 索引（命中 0 条决策）
→ 路由加载：commit-with-affects/SKILL.md
→ 生成《规范快照》（共 12 行）

[SPEC LOADED] 技术层: 前端+后端 | 禁止项: 3 条 | token定义: tailwind.config.js
```

---

## 文件结构

```
.agents/
  rules/          # 硬红线规则（始终加载）
    core.md           — 全局规则：配置加载协议、幻觉防控清单、知识库写保护
    guardrails.md     — 工程红线：数据库操作、前端禁止项、密钥、依赖管理、经验总结触发
    frontend-ui.md    — 前端 UI 约定：语义色、统一组件、状态管理边界
    db.md             — 数据库路由器：根据 tech_stack.database 分发到具体规则
    db-mysql.md       — MySQL 专属规则
    db-sqlite.md      — SQLite 专属规则
    db-postgres.md    — PostgreSQL 专属规则

  workflows/      # 工作流（纯编排，调用 skill 的编排层）
    requirement-clarification.md  — 需求澄清：结构化提问 → 需求规格确认书
    project-bootstrap.md          — 0-1 新项目：架构规划 → 组件层级 → 约定锁定
    auto-dev.md                   — 全自动开发（Ralph-loop，支持 resume）
    dev-flow.md                   — 人工驱动开发（探索性场景）
    frontend-tdd.md               — 前端 Component-TDD + UX 卡点
    impact-analysis.md            — 变更影响范围分析
    hotfix.md                     — P0 生产紧急修复
    pr-review.md                  — PR 描述生成 + 代码自检
    slim.md                       — 项目瘦身（孤儿文件/死路由/依赖扫描）
    production-release.md         — 发版前检查 → 打 tag → 上线
    git-lifecycle.md              — Git 开发生命周期规范
    weekly-report.md              — 自动生成开发周报

  skills/         # 原子工具（可独立调用，也被 workflow 编排）
    项目规划类：
      advise-tech-stack/          — 技术栈选型建议
      plan-page-map/              — 页面地图规划
      plan-component-hierarchy/   — 组件层级规划
      lock-global-conventions/    — 全局约定锁定 + .slimignore 生成
    测试类：
      generate-test-skeleton/     — Test-First 测试骨架生成
      run-tests/                  — 测试路由（→ pytest 或 jest）
      generate-test-from-impact/  — 从 impact-analysis GAP 生成测试
    数据库类：
      export-db-indexes/          — 生成增量 DDL + 回滚 DDL
    提交类：
      commit-with-affects/        — 带影响面的标准化 commit
      generate-pr-description/    — 基于 git log 生成 PR 描述
      pr-self-review/             — 代码质量/规范/安全/测试四维度自检
    前端质量类：
      frontend-ux-evaluator/      — 单个组件/页面 UX 评估（5 维度）
      scan-frontend-quality/      — 全量前端质量扫描（8 维度）
    代码卫生类：
      scan-code-hygiene/          — 扫描 console.log/TODO/硬编码/密钥
    项目瘦身类：
      scan-orphan-components/     — 孤儿组件扫描
      scan-dead-routes/           — 死路由扫描
      scan-unused-exports/        — 未引用导出扫描
      scan-bundle-bloat/          — 重型依赖优化建议
    知识管理类：
      sync-llm-context/           — 刷新 AI 上下文地图
      record-decision/            — 写入架构决策记录（ADR）

  hooks/
    pre-commit.sh   # git pre-commit hook 模板（install.sh 自动写入 .git/hooks/）

  scripts/
    test_lock.py    # 测试基线防篡改工具（lock / verify / status）

  SKILL_INDEX.md  # Skill 注册表（工作流一览 + 完整依赖图 + 快速查找）

docs/
  INDEX.md              # 项目知识地图（AI 入场必读）
  conventions.md        # 活的约定文档（bootstrap 生成，全程追加，AI 每次必读）
  decisions/
    README.md           # ADR 索引表（AI 路由用）
    _template.md        # 决策记录模板
  lessons/
    backend.md          # 后端踩坑记录
    frontend.md         # 前端踩坑记录
    testing.md          # 测试踩坑记录

project.config.json        # 项目特异参数（不提交到 git）
project.config.example.json
.slimignore.example        # 瘦身豁免清单模板
```

---

## 快速指令参考

### 常用工作流

| 指令 | 用途 |
|------|------|
| `/requirement-clarification` | 需求澄清（所有开发的起点） |
| `/project-bootstrap` | 全新项目架构规划 |
| `/auto-dev [规格书]` | 全自动开发（需求确认后触发） |
| `/auto-dev resume` | 从中断点恢复开发 |
| `/hotfix` | P0 生产故障紧急修复 |
| `/pr-review` | 提 PR 前的描述生成 + 自检 |
| `/production-release` | 发版前全套检查 + 打 tag |
| `/slim` | 项目瘦身（孤儿文件/死路由/依赖） |
| `/sync-llm-context` | 刷新 AI 对项目的认知地图 |

### 可单独调用的 Skill

| 指令 | 用途 |
|------|------|
| `/advise-tech-stack` | 仅做技术栈选型 |
| `/plan-page-map` | 仅规划页面路由结构 |
| `/plan-component-hierarchy` | 仅规划组件分层 |
| `/generate-test-skeleton --type=api\|service\|db\|frontend` | 生成 Test-First 测试骨架 |
| `/export-db-indexes` | 生成数据库迁移 DDL + 回滚 DDL |
| `/generate-pr-description` | 仅生成 PR 描述 |
| `/pr-self-review` | 仅执行 PR 代码自检 |
| `/frontend-ux-evaluator` | 评估单个组件/页面的 UX 质量 |
| `/scan-frontend-quality` | 全量扫描前端质量 |
| `/scan-code-hygiene [--scope=staged\|all]` | 扫描代码卫生问题 |
| `/scan-orphan-components` | 仅扫孤儿组件 |
| `/scan-dead-routes` | 仅扫死路由 |
| `/scan-unused-exports` | 仅扫未引用导出 |
| `/scan-bundle-bloat` | 仅扫重型依赖 |

---

## 框架如何约束 AI（示例）

以下是 `auto-dev` 工作流中，框架拦截 AI 行为的真实例子：

**场景：AI 准备新建一个 Modal 组件**

没有框架时，AI 直接写新组件。有框架后：

```
[组件复用检查]
grep {{FRONTEND_PATH}}/components/ Modal Dialog...
找到候选：
  - components/common/Modal.tsx（已有，支持 title/footer/width props）
  - components/common/DeleteConfirmModal.tsx（继承自 Modal）

→ 本次任务复用 Modal.tsx，扩展 onConfirm prop，不新建组件。
```

**场景：AI 准备提交代码**

```
[Step 0-A] scan-code-hygiene --scope=staged
P0 问题：0 个
P1 问题：2 个
  - frontend/src/pages/UserPage.tsx:47  console.log("debug user data")
  - backend/app/routers/auth.py:23      # TODO: 添加速率限制

→ 允许提交，commit message 附加 known-issues: console.log×1, TODO×1
```

**场景：AI 发现决策记录**

```
[决策预读] docs/decisions/README.md
命中 1 条决策：jwt-auth-strategy.md（affects: backend/app/routers/auth/）
QUICK: NEVER 换成 Session Cookie | NEVER token 存 localStorage | NEVER TTL 超 2 小时

→ 禁止事项已加入规范快照，后续修改 auth 模块时自动约束。
```

---

## 典型使用场景

### 全新项目

```
/project-bootstrap 用户管理系统，React + FastAPI
→ 技术栈确认 → 页面地图 → 组件层级 → 约定锁定 → 你确认《架构蓝图》
→ /requirement-clarification [第一个功能]
→ /auto-dev [确认后的规格书]
```

### 接手存量项目

```bash
./install.sh /path/to/existing-project
# 填写 project.config.json
```
```
/sync-llm-context        # AI 扫描仓库，生成上下文地图
/scan-frontend-quality   # 了解现有前端质量基线
# 然后按正常流程开发新需求
```

### 正常全栈需求

```
/requirement-clarification     # 最多 6 个问题澄清需求
→ 你确认《需求规格确认书》
→ /auto-dev [规格书]
  → 前端 Component-TDD（写测试→锁定→实现→验绿→UX评估→你确认）
  → 你在浏览器确认 UI
  → 后端开发（从已确认 UI 反推 API 契约）
→ /pr-review
→ /production-release
```

### 被打断后恢复

```bash
git stash                # 暂存当前工作
git checkout -b feature/B
# 处理 B 需求
git checkout feature/A
git stash pop
/auto-dev resume         # 从 tmp/.agent-session.md 恢复现场
```

### 生产 P0 故障

```bash
git stash                # 先保存当前工作
git checkout main && git checkout -b hotfix/xxx
/hotfix                  # P0 专用流程（最小化修复，跳过大部分步骤）
# 修复上线稳定后
git checkout feature/xxx
git stash pop
/auto-dev resume
```

### 定期项目瘦身

```
/slim
→ scan-orphan-components + scan-dead-routes + scan-unused-exports + scan-bundle-bloat
→ 生成《删除提案》（P0/P1/P2 分级）
→ 你确认 → AI 逐文件删除 → 全量测试验证
```

---

## project.config.json 关键字段

```jsonc
{
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",       // 前端源码根目录
    "backend": "python+fastapi",
    "backend_path": "backend/app",         // 后端源码根目录
    "test_path": "backend/tests",
    "database": "mysql",                   // mysql | sqlite | postgres
    "css_framework": "tailwind",           // 影响颜色规范的开关
    "frontend_test_path": "frontend/src/__tests__",
    "frontend_extensions": ["tsx", "ts"]   // scan-frontend-quality 用
  },
  "testing": {
    "local_db_url": "...",                 // 本地测试数据库
    "test_lock_script": ".agents/scripts/test_lock.py"
  },
  "deploy": {
    "tag_format": "v{YYYYMMDD-HHMM}-{description}",
    "rollback_required": true
  }
}
```

完整字段说明见 `project.config.example.json`。

---

## 三层架构说明

```
Rules（始终加载）
  └─ 硬红线，所有操作的底层约束
       ↓
Workflows（按需触发）
  └─ 纯编排层，定义 skill 的调用顺序和条件
       ↓
Skills（原子工具）
  └─ 每个 skill 有独立的触发指令，也被 workflow 编排调用
```

- **Rules** 不需要手动触发，AI 接手会话时自动加载
- **Workflows** 通过 `/workflow-name` 触发，内部调用 skill 的顺序
- **Skills** 通过 `/skill-name` 独立调用，也可以由 workflow 串联

详见 `.agents/SKILL_INDEX.md`（完整依赖图 + 快速查找表）。

---

## 测试基线保护

```bash
# 锁定（Test-First 阶段，人工确认测试骨架后执行）
python .agents/scripts/test_lock.py lock

# 验证（每次跑测试前自动触发，防止断言被篡改）
python .agents/scripts/test_lock.py verify

# 查看当前基线状态
python .agents/scripts/test_lock.py status
```

锁定后，测试断言不允许修改。实现出问题只能改实现代码，不允许改预期。

---

## 经验沉淀

项目开发过程中的踩坑，AI 会在 Ralph-loop 每轮结束时检测并提出 `[KNOWLEDGE_UPDATE]` 建议文本，由你决定是否写入 `docs/lessons/`。

这些文件是 AI 下次接手任务时的"入场背景"，不记录常识，只记录**在本项目踩过的坑**。
