# agent-rails

[English](README.md) | [简体中文](README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

![工作流概览](./docs/flow-overview_zh.png)

AI 辅助开发的约束框架 —— 规则、技能与护栏，让大模型在整个项目生命周期中稳定输出。

---

## 为什么需要这个

AI 编程助手写代码很快，但有三个致命问题：**健忘、自由发挥、对项目历史一无所知。**

你大概遇到过：描述了一个功能，AI 写完了，Review 时发现方向完全错了；改了个小页面，核心链路被弄坏了；项目里已经有封装好的弹窗组件，AI 又手搓了一个新的；conventions 文档写得再清楚，AI 下次会话照样无视。

根源不在 AI 的能力，而在于**没有结构化的框架约束它**。每次对话都是白纸，没有护栏、没有记忆、没有人类能介入的卡点。

agent-rails 解决这个问题：

- **Rules（规则）**：启动即加载的绝对红线，划定 AI 不可触碰的底线
- **Workflows（工作流）**：标准化开发流程，在关键节点设置人工确认卡点
- **Skills（技能）**：原子化工具，按需加载，用完释放
- **知识底座**：跨会话积累的项目约定、架构决策、踩坑经验

**设计原则：结阵为流水线（Workflow），拆解为单兵技能（Skill）。**

所有 workflow 由 skill 组成，每个 skill 也可独立调用。框架与业务解耦 —— 填写 `project.config.json` 即可适配任何项目。

---

## 解决什么问题

| 痛点 | 解决方案 |
|------|---------|
| 写到最后才发现方向错了 | `requirement-clarification` 需求确认 + `proposal-review` 方案评审，两道人工卡点 |
| 新功能破坏了旧功能 | `impact-analysis` 爆炸半径分析 + `test-lock` 测试基线锁 |
| 代码风格不统一 | `docs/conventions.md` 活的约定文档，AI 每次开工前必读 |
| 重复造轮子，无视现有组件 | 强制 grep 现有组件库，新建前必须证明没有可复用的 |
| 上线残留 console.log，项目越来越慢 | `/slim` 全方位瘦身扫描 + 提交前 `scan-code-hygiene` 拦截 |
| AI 幻觉：编造不存在的 API | 四条反幻觉协议 + 自我熔断机制 |
| 规范越积越多，过期条目没人清理 | `review-guardrails` 钢印审查 + 3 天自动提醒 + 90 天过期检测 |

---

## 三层架构

```
Rules（启动即加载，常驻 System Prompt）
  └─ 绝对红线。精简到只有一个文件（~7KB），不浪费上下文。
       ↓
Workflows（按需触发）
  └─ 编排层。定义 skill 调用顺序、条件和人工卡点。
       ↓
Skills（懒加载）
  └─ 原子工具。系统只存名称+路径索引，Agent 需要时自己读取全文，用完释放。
```

> **为什么这样设计？**
>
> 很多项目把几万字的规范塞进 System Prompt，AI 被海量指令稀释注意力，代码质量反而下降。
>
> agent-rails 利用 AI IDE 的**懒加载机制**：Rules 只保留绝对红线（~7KB），Skills 和 Workflows 只以索引形式存在（几百 Token），Agent 需要什么就去读什么。既保证了约束力，又不浪费上下文窗口。

---

## 环境要求

### 硬性前提

框架依赖 AI 的**文件读写工具（Tool Use）**，纯聊天模式无法使用。

- 支持 Function Calling / Tool Use（读文件、写文件、搜索、终端）
- 上下文窗口 ≥ 32K tokens

### 推荐模型

| 模型 | 兼容性 | 说明 |
|------|--------|------|
| 顶级商业模型（Claude 3.5+, GPT-4o） | 完全兼容 | 框架为此类模型设计，指令遵从和自我迭代能力最佳 |
| 推理专精模型 | 完全兼容 | 适合复杂任务，注意成本 |
| GPT-4o / Gemini 1.5 Pro | 基本可用 | 工具调用稳定，workflow 需手动触发 |
| 本地小模型（≤ 13B） | 不推荐 | 复杂指令遵从能力不足，Ralph-loop 不可靠 |

### 平台兼容

#### 原生 AI Agent（推荐）

Antigravity IDE、Roo Code、Cursor 等原生支持 Tool Use 的环境：

- `.agents/rules/` 下的规则自动加载
- `/skill-name` 斜杠命令直接触发
- 文件工具完全匹配框架约定

```bash
./install.sh /path/to/project
# 在 AI 助手中打开项目目录，开始使用
```

#### Cursor / Continue.dev / Windsurf

可用，需要手动适配：

1. 将 `.agents/rules/core.md` 内容复制到 System Prompt 或 `.cursorrules`
2. 用自然语言触发 workflow（如"执行 auto-dev 工作流"替代 `/auto-dev`）

#### 不适用

- 纯聊天 API（无 Tool Use）
- GitHub Copilot（无法注入自定义规则）
- 网页聊天界面（无项目文件访问）

---

## 五分钟上手

### 1. 安装

```bash
git clone https://github.com/wisterx-spec/agent-rails.git
./install.sh /path/to/your-project
```

### 2. 最小配置

编辑目标项目下的 `project.config.json`：

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

缺失字段会优雅降级，不会阻塞启动。

### 3. 开始使用

```
/requirement-clarification   ← 推荐：从需求对齐开始
```

或者直接开发：

```
/auto-dev 实现邮箱+手机号验证码登录，后端 FastAPI，前端 Tailwind
```

### 4. 预期输出

```
[CONFIG LOADED] project=your-project | frontend=react+typescript | backend=python+fastapi | db=mysql
[MAINTENANCE DUE] 距上次钢印审查已 5 天，建议执行 /review-guardrails

Phase 0: Pre-read
→ Reading conventions.md Quick Reference (2 STALE items flagged)
→ Loading frontend-dev-guide skill
→ Generating spec snapshot (14 lines)

[SPEC LOADED] layers: frontend+backend | constraints: 4 | tokens: tailwind.config.js
```

---

## 完整开发流程

```
用户提出需求
    ↓
/requirement-clarification → 需求规格确认书 → 🔴 人工确认
    ↓
选择模式：/auto-dev（AI 自驱）或 /dev-flow（人工推进）
    ↓
规范预加载 → 读取 config / conventions / decisions / 领域 skill
    ↓
方案评审 → /proposal-review（非轻量任务）→ 🔴 人工确认
    ↓
编码执行 → Ralph-loop（Assess → Act → Verify → Log）
    ├─ 全栈任务：前端 Component-TDD 先行 → 🔴 UX 人工确认 → 后端
    ├─ 自动挂载领域防线（frontend-dev-guide / db-dev-guide）
    └─ 循环直到 P0 全部解决
    ↓
人工核验 → 核验报告 → 🔴 人工确认
    ↓
/commit-with-affects → 带影响面的标准化提交
    ↓
/pr-review → PR 描述 + 四维自检
    ↓
/production-release → 卫生扫描 → 测试 → DDL Review → 🔴 发布确认
    ↓
上线完成
```

详细流程图见 [`docs/flow-overview_zh.md`](docs/flow-overview_zh.md)（含 Mermaid 源码）和 [`docs/flow-overview_zh.png`](docs/flow-overview_zh.png)。

### 人工卡点一览

| 卡点 | 位置 | 通过条件 |
|------|------|----------|
| 需求确认 | requirement-clarification 输出后 | 用户确认规格书 |
| 方案评审 | auto-dev Phase 2 / dev-flow Step 3 | 用户回复"确认，继续执行" |
| UX 评估 | 前端每个组件完成后 | 用户确认所有问题已修复 |
| 改动核验 | auto-dev Phase 4 | 用户确认核验报告 |
| 发布确认 | production-release | QA + DBA + 部署审批 |

### 轻量路径

以下场景跳过方案评审，减少确认疲劳：
- Bug fix 且改动文件 ≤ 2 个
- 纯样式 / 纯文案调整

---

## 文件结构

```
.agents/
  rules/
    core.md               — 唯一的全局规则文件（~7KB），包含启动协议、
                            反幻觉协议、工程红线、域路由指令、
                            知识库保护、经验总结触发、钢印保鲜机制

  workflows/              — 编排层（12 个工作流）
    requirement-clarification.md  — 需求对齐 → 规格签收
    project-bootstrap.md          — 0→1：技术栈 → 页面地图 → 组件层级 → 约定锁定
    auto-dev.md                   — 全自动开发（Ralph-loop，支持断点恢复）
    dev-flow.md                   — 人工驱动开发
    frontend-tdd.md               — 组件 TDD + UX 评估卡点
    impact-analysis.md            — 变更爆炸半径分析
    hotfix.md                     — P0 线上紧急修复
    pr-review.md                  — PR 描述 + 自审
    slim.md                       — 项目瘦身（含钢印审查）
    production-release.md         — 发布前检查 → 打标签 → 部署
    git-lifecycle.md              — Git 分支与提交约定
    weekly-report.md              — 自动周报

  skills/                 — 原子工具（25+ 个技能）
    方案评审：  proposal-review/
    领域规范：  frontend-dev-guide/、db-dev-guide/
    规范治理：  review-guardrails/
    项目规划：  advise-tech-stack/、plan-page-map/、plan-component-hierarchy/、
               lock-global-conventions/
    测试：     generate-test-skeleton/、run-tests/、generate-test-from-impact/
    数据库：   export-db-indexes/
    提交：     commit-with-affects/、generate-pr-description/、pr-self-review/
    前端质量： frontend-ux-evaluator/、scan-frontend-quality/
    代码卫生： scan-code-hygiene/
    项目瘦身： scan-orphan-components/、scan-dead-routes/、scan-unused-exports/、
               scan-bundle-bloat/
    知识管理： sync-llm-context/、record-decision/

  hooks/
    pre-commit.sh         — 密钥检测 hook

  scripts/
    test_lock.py          — 测试基线防篡改

docs/
  INDEX.md                — 项目知识地图（AI 首读）
  conventions.md          — 活的项目约定（持续维护）
  decisions/              — 架构决策记录（ADR）
  lessons/                — 项目踩坑经验（backend / frontend / testing）
  flow-overview_zh.md     — 完整流程图（Mermaid 源码）
  flow-overview_zh.png    — 完整流程图（图片）

project.config.json       — 项目配置（不提交）
```

---

## 指令速查

### 工作流

| 指令 | 用途 |
|------|------|
| `/requirement-clarification` | 需求对齐（推荐起点） |
| `/project-bootstrap` | 新项目架构规划 |
| `/auto-dev [规格书]` | 全自动开发 |
| `/auto-dev resume` | 从断点恢复 |
| `/hotfix` | P0 线上紧急修复 |
| `/pr-review` | PR 描述 + 自审 |
| `/production-release` | 发布前检查 + 部署 |
| `/slim` | 项目瘦身 |

### 独立技能

| 指令 | 用途 |
|------|------|
| `/proposal-review` | 方案评审（人工卡点） |
| `/review-guardrails` | 审查规范健康度 |
| `/frontend-dev-guide` | 查看前端开发规范 |
| `/db-dev-guide` | 查看数据库开发规范 |
| `/generate-test-skeleton --type=api\|service\|db\|frontend` | 测试骨架 |
| `/export-db-indexes` | 数据库迁移 DDL |
| `/scan-frontend-quality` | 前端质量全量扫描 |
| `/scan-code-hygiene` | 代码卫生扫描 |
| `/scan-orphan-components` | 孤儿组件扫描 |
| `/scan-dead-routes` | 死路由扫描 |
| `/scan-unused-exports` | 未引用导出扫描 |
| `/scan-bundle-bloat` | 重型依赖扫描 |
| `/sync-llm-context` | 刷新 AI 上下文 |
| `/record-decision` | 记录架构决策 |

---

## 典型场景

### 新项目

```
/project-bootstrap 用户管理系统，React + FastAPI
→ 确认技术栈 → 页面地图 → 组件层级 → 锁定约定
→ /requirement-clarification [第一个功能]
→ /auto-dev [确认后的规格书]
```

### 接手现有项目

```bash
./install.sh /path/to/existing-project
# 填写 project.config.json
```
```
/sync-llm-context          # AI 扫描代码库，建立上下文
/scan-frontend-quality     # 建立前端质量基线
# 然后正常开发
```

### 全栈功能

```
/requirement-clarification           # 最多 6 个澄清问题
→ 确认规格书
→ /auto-dev [规格书]
  → /proposal-review → 人工确认方案
  → 前端 Component-TDD（测试 → 锁定 → 实现 → UX 评估 → 人工确认）
  → 在浏览器验证 UI
  → 后端（从已确认的 UI 反推 API 契约）
→ /pr-review
→ /production-release
```

### 开发中断后恢复

```bash
git stash && git checkout -b feature/B
# 处理 feature B
git checkout feature/A && git stash pop
```
```
/auto-dev resume    # 从 tmp/.agent-session.md 恢复断点
```

### 定期维护

```
/slim                      # 代码瘦身 + 钢印健康审查
/review-guardrails         # 单独审查规范（过期/冲突/冗余/缺口）
```

---

## project.config.json 关键字段

```jsonc
{
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",
    "backend": "python+fastapi",
    "backend_path": "backend/app",
    "test_path": "backend/tests",
    "database": "mysql",                   // mysql | sqlite | postgres
    "css_framework": "tailwind",           // 影响颜色约束执行
    "frontend_test_path": "frontend/src/__tests__",
    "frontend_extensions": ["tsx", "ts"]
  },
  "testing": {
    "local_db_url": "...",
    "test_lock_script": ".agents/scripts/test_lock.py"
  },
  "deploy": {
    "tag_format": "v{YYYYMMDD-HHMM}-{description}",
    "rollback_required": true
  }
}
```

完整字段参考：`project.config.example.json`

---

## 钢印保鲜机制

规范只增不减会导致过期条目积累。框架内置了保鲜循环：

```
写入时 → 每条必须带日期（YYYY-MM-DD）
读取时 → 自动检测 > 90 天的条目，标注 [STALE]
收口时 → 输出审查提议，人工决定保留/更新/删除
启动时 → 距上次审查 > 3 天，自动提醒 /review-guardrails
```

正面经验也会被记录。不只是"什么不该做"，也包括"什么值得重复做"。

---

## 实际效果示例

**AI 准备新建一个 Modal 组件：**

```
[组件复用检查]
grep frontend/src/components/ Modal Dialog...
找到候选：
  - components/common/Modal.tsx（已有，支持 title/footer/width props）
  - components/common/DeleteConfirmModal.tsx（扩展自 Modal）

→ 复用 Modal.tsx，扩展 onConfirm prop。未创建新组件。
```

**AI 准备提交代码：**

```
[scan-code-hygiene --scope=staged]
P0: 0
P1: 2
  - frontend/src/pages/UserPage.tsx:47  console.log("debug user data")
  - backend/app/routers/auth.py:23      # TODO: add rate limiting

→ 允许提交。commit message 附注：known-issues: console.log×1, TODO×1
```

**AI 触碰了有架构决策保护的模块：**

```
[决策预读] docs/decisions/README.md
命中 1 条：jwt-auth-strategy.md（affects: backend/app/routers/auth/）
QUICK: NEVER 换成 Session Cookie | NEVER 存 localStorage | NEVER TTL > 2h

→ NEVER 约束加入规范快照，应用于所有 auth 模块改动。
```
