# Skill 注册表 (Skill Index)

> **架构原则**：放在一起是流程，单独拿出来是 skill。
> 所有工作流均由 skill 组成，每个 skill 也可通过 `/skill-name` 独立触发。

---

## 工作流一览（纯编排层）

| 工作流 | 触发指令 | 组成的 skill |
|--------|---------|-------------|
| `requirement-clarification` | `/requirement-clarification` | 内置问答逻辑（无可分拆 skill） |
| `project-bootstrap` | `/project-bootstrap` | advise-tech-stack → plan-page-map → plan-component-hierarchy → lock-global-conventions |
| `auto-dev` | `/auto-dev [规格书]` | requirement-clarification → dev-flow |
| `dev-flow` | `/dev-flow` | sync-llm-context → impact-analysis → generate-test-skeleton → run-tests → export-db-indexes → commit-with-affects |
| `frontend-tdd` | 由 dev-flow/auto-dev 触发 | generate-test-skeleton → run-tests → frontend-ux-evaluator |
| `slim` | `/slim` | scan-orphan-components → scan-dead-routes → scan-unused-exports → scan-bundle-bloat → run-tests |
| `pr-review` | `/pr-review` | generate-pr-description → pr-self-review |
| `hotfix` | `/hotfix` | run-tests → commit-with-affects → production-release |
| `production-release` | `/production-release` | scan-code-hygiene → run-tests → export-db-indexes → scan-frontend-quality（可选） |
| `impact-analysis` | 由 dev-flow 触发 | generate-test-from-impact |
| `weekly-report` | `/weekly-report` | 内置 git 查询逻辑 |

---

## Skill 完整清单

### 项目规划类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `advise-tech-stack` | `/advise-tech-stack` | 根据需求给出技术栈选型建议 + project.config.json 草稿 | project-bootstrap Phase 2 |
| `plan-page-map` | `/plan-page-map` | 规划页面路由树（标注 MVP/推迟） | project-bootstrap Phase 3 |
| `plan-component-hierarchy` | `/plan-component-hierarchy` | 规划组件分层规则 + 必建组件清单 + 状态管理边界 | project-bootstrap Phase 4 |
| `lock-global-conventions` | `/lock-global-conventions` | 生成全局开发约定文档 + .slimignore 初始内容 | project-bootstrap Phase 5-6 |

### 测试类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `generate-test-skeleton` | `/generate-test-skeleton --type=api\|service\|db\|frontend` | 根据接口定义生成测试骨架（Test-First） | dev-flow Step 4, frontend-tdd Step 1 |
| `run-tests` | `/run-tests [--mode=fast\|full]` | 路由到 pytest 或 jest | dev-flow Step 7, production-release Step 3 |
| `run-tests/pytest` | 由 run-tests 路由 | Python pytest 执行规范 | run-tests |
| `run-tests/jest` | 由 run-tests 路由 | Node.js Jest/Vitest 执行规范 | run-tests |
| `run-backend-tests` *(旧)* | `/run-backend-tests` | 同 run-tests/pytest，向后兼容 | — |
| `generate-test-from-impact` | 由 impact-analysis 触发 | 从 GAP 清单自动生成测试代码 | impact-analysis |

### 数据库类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `export-db-indexes` | `/export-db-indexes` | 生成增量 ALTER TABLE DDL + 回滚 DDL | dev-flow Step 6, production-release Step 4 |

### 提交类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `commit-with-affects` | `/commit-with-affects` | 生成带影响面的标准化 commit message | dev-flow Step 8, auto-dev Phase 5 |
| `generate-pr-description` | `/generate-pr-description [--base=main]` | 基于 git log 生成 PR 描述 | pr-review Step 1 |
| `pr-self-review` | `/pr-self-review` | 代码质量/规范/安全/测试四维度自检 | pr-review Step 2 |

### 前端质量类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `frontend-ux-evaluator` | `/frontend-ux-evaluator` | 单个页面/组件 UX 评估（5 维度） | frontend-tdd Step 5 |
| `scan-frontend-quality` | `/scan-frontend-quality` | 全量扫描所有页面（8 维度） | production-release（可选） |

### 代码卫生类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `scan-code-hygiene` | `/scan-code-hygiene [--scope=staged\|all]` | 扫描 console.log/TODO/硬编码地址/潜在密钥 | production-release Step 2, pr-self-review |

### 项目瘦身类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `scan-orphan-components` | `/scan-orphan-components` | 扫描无 import 引用的孤儿组件 | slim Phase 1 |
| `scan-dead-routes` | `/scan-dead-routes` | 扫描路由配置与页面文件不一致问题 | slim Phase 2 |
| `scan-unused-exports` | `/scan-unused-exports` | 扫描未被 import 的导出 | slim Phase 3 |
| `scan-bundle-bloat` | `/scan-bundle-bloat` | 扫描重型依赖和可替代方案 | slim Phase 4 |

### 知识管理类

| Skill | 触发指令 | 作用 | 被哪些工作流调用 |
|-------|---------|------|----------------|
| `sync-llm-context` | `/sync-llm-context` | 刷新 LLM 上下文地图 | dev-flow Step 1（条件触发） |
| `record-decision` | `/record-decision [topic]` | 将非显而易见的技术决策写入 `docs/decisions/` | auto-dev Phase 5（条件触发）、dev-flow Step 8 前（条件触发） |

---

## 调用依赖图

```
requirement-clarification          (模糊需求时强制前置)

project-bootstrap
  ├─► advise-tech-stack
  ├─► plan-page-map
  ├─► plan-component-hierarchy
  └─► lock-global-conventions

auto-dev
  ├─► requirement-clarification    (前置: 模糊需求时)
  └─► dev-flow
        ├─► sync-llm-context        (条件: 新路由/大重构)
        ├─► impact-analysis
        │     └─► generate-test-from-impact
        ├─► generate-test-skeleton (条件: Test-First 场景)
        ├─► frontend-tdd           (条件: 前端 UX 质量要求)
        │     ├─► generate-test-skeleton
        │     ├─► run-tests
        │     └─► frontend-ux-evaluator
        ├─► run-tests
        ├─► export-db-indexes      (条件: 修改了 ORM 模型)
        └─► commit-with-affects

pr-review
  ├─► generate-pr-description
  └─► pr-self-review
        └─► scan-code-hygiene (staged)

production-release
  ├─► scan-code-hygiene (all)
  ├─► run-tests (fast)
  ├─► export-db-indexes
  └─► scan-frontend-quality (可选)

slim
  ├─► scan-orphan-components
  ├─► scan-dead-routes
  ├─► scan-unused-exports
  ├─► scan-bundle-bloat
  └─► run-tests (full，删除后验证)

hotfix
  ├─► run-tests (targeted)
  ├─► commit-with-affects
  └─► production-release
```

---

## 快速查找

| 我想要... | 用这个 |
|---------|-------|
| 讨论并澄清需求 | `requirement-clarification` |
| 全新项目架构规划 | `project-bootstrap` |
| 只做技术栈选型 | `/advise-tech-stack` |
| 只规划页面结构 | `/plan-page-map` |
| 只规划组件层级 | `/plan-component-hierarchy` |
| 需求确认后开始开发 | `auto-dev` |
| 前端组件 TDD + UX 验证 | `frontend-tdd` |
| 生成测试骨架 | `/generate-test-skeleton` |
| 跑测试 | `/run-tests` |
| 提交代码 | `/commit-with-affects` |
| 生成 PR 描述 | `/generate-pr-description` |
| PR 代码自检 | `/pr-self-review` |
| 检查单个组件 UX | `/frontend-ux-evaluator` |
| 全量扫描前端质量 | `/scan-frontend-quality` |
| 扫描代码卫生问题 | `/scan-code-hygiene` |
| 生成数据库迁移 DDL | `/export-db-indexes` |
| 清理孤儿组件 | `/scan-orphan-components` |
| 扫描死路由 | `/scan-dead-routes` |
| 扫描未引用导出 | `/scan-unused-exports` |
| 扫描重型依赖 | `/scan-bundle-bloat` |
| 一键项目瘦身 | `/slim` |
| 刷新 AI 上下文 | `/sync-llm-context` |
| 记录技术决策（ADR） | `/record-decision [topic]` |
| 生产 P0 故障 | `/hotfix` |
| 发版上线 | `/production-release` |
