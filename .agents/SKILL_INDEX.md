# Skill 注册表 (Skill Index)

所有可用技能的一览表。Agent 需要了解有哪些工具可用时，先读此文件，按需物理读取对应 SKILL.md。

---

## 工作流一览

| 工作流 | 路径 | 触发指令 | 用途 |
|--------|------|---------|------|
| `requirement-clarification` | `workflows/requirement-clarification.md` | 自动（模糊需求时）/ `/requirement-clarification` | 需求澄清 → 输出《需求规格确认书》，auto-dev 的前置 |
| `project-bootstrap` | `workflows/project-bootstrap.md` | `/project-bootstrap [描述]` | 0-1 新项目：技术栈选型 → 页面地图 → 组件规划 → 约定锁定 |
| `auto-dev` | `workflows/auto-dev.md` | `/auto-dev [规格书]` | 全自动开发（需求澄清后的主干流程） |
| `dev-flow` | `workflows/dev-flow.md` | `/dev-flow` | 人工驱动开发（探索性/边做边改场景） |
| `frontend-tdd` | `workflows/frontend-tdd.md` | 由 dev-flow/auto-dev 触发 | 前端 Component-TDD + UX 卡点 |
| `hotfix` | `workflows/hotfix.md` | `/hotfix` | P0 生产紧急修复 |
| `pr-review` | `workflows/pr-review.md` | `/pr-review` | PR 描述生成 + 代码自审 |
| `slim` | `workflows/slim.md` | `/slim` | 项目瘦身：孤儿组件/死路由/未引用导出扫描 |
| `production-release` | `workflows/production-release.md` | `/production-release` | 发版前检查 → 打 tag → 上线 → 验证 |
| `impact-analysis` | `workflows/impact-analysis.md` | 由 dev-flow 触发 | 变更影响范围分析 |
| `weekly-report` | `workflows/weekly-report.md` | `/weekly-report` | 自动生成周报 |

---

## 测试类

| 技能 | 路径 | 触发时机 | 被谁调用 |
|------|------|---------|---------|
| `run-tests` | `skills/run-tests/SKILL.md` | 提交前/发版前/用户要求跑测试 | dev-flow Step7, production-release Step3, commit-with-affects Step0 |
| `run-tests/pytest` | `skills/run-tests/pytest.md` | Python 项目，由 run-tests 路由 | run-tests |
| `run-tests/jest` | `skills/run-tests/jest.md` | Node.js 项目，由 run-tests 路由 | run-tests |
| `run-backend-tests` *(旧)* | `skills/run-backend-tests/SKILL.md` | 同 run-tests/pytest，向后兼容 | — |
| `generate-test-from-impact` | `skills/generate-test-from-impact/SKILL.md` | impact-analysis 后，从 GAP 清单自动生成测试代码 | impact-analysis (可选) |

---

## 数据库类

| 技能 | 路径 | 触发时机 | 被谁调用 |
|------|------|---------|---------|
| `export-db-indexes` | `skills/export-db-indexes/SKILL.md` | 修改 ORM 模型后，生成增量 DDL + 回滚 DDL | dev-flow Step6, production-release Step4 |

---

## 提交类

| 技能 | 路径 | 触发时机 | 被谁调用 |
|------|------|---------|---------|
| `commit-with-affects` | `skills/commit-with-affects/SKILL.md` | 准备 git commit 时 | dev-flow Step8, auto-dev Phase5 |

---

## 前端质量类

| 技能 | 路径 | 触发时机 | 被谁调用 |
|------|------|---------|---------|
| `frontend-ux-evaluator` | `skills/frontend-ux-evaluator/SKILL.md` | Component-TDD 每个组件验绿后的 UX 卡点；产品评审前自检 | frontend-tdd Step5, auto-dev Phase4 |
| `scan-frontend-quality` | `skills/scan-frontend-quality/SKILL.md` | 大版本发版前全量扫描所有页面 | production-release (可选) |

---

## 知识管理类

| 技能 | 路径 | 触发时机 | 被谁调用 |
|------|------|---------|---------|
| `sync-llm-context` | `skills/sync-llm-context/SKILL.md` | 大重构/新建路由后，刷新 LLM 上下文地图 | dev-flow Step1 (条件触发) |

---

## 调用依赖图

```
requirement-clarification          (模糊需求时强制前置)
  └─► [输出《需求规格确认书》]

project-bootstrap                  (0-1 新项目专用)
  └─► [输出《架构蓝图》→ 生成 project.config.json + 路由骨架]

auto-dev
  ├─► requirement-clarification    (前置: 模糊需求时)
  └─► dev-flow
        ├─► sync-llm-context      (条件: 新路由/大重构)
        ├─► impact-analysis        (条件: API/DB/跨组件)
        │     └─► generate-test-from-impact
        ├─► frontend-tdd           (条件: 前端组件有 UX 质量要求)
        │     └─► frontend-ux-evaluator  (每个组件验绿后触发)
        ├─► run-tests              (Step7)
        │     ├─► run-tests/pytest (Python)
        │     └─► run-tests/jest   (Node.js)
        ├─► export-db-indexes      (条件: 修改了 ORM 模型)
        │     └─► [同时生成回滚 DDL]
        └─► commit-with-affects    (Step8)
              └─► run-tests        (pre-commit 验证)

production-release
  ├─► run-tests
  ├─► export-db-indexes
  └─► scan-frontend-quality (可选)

slim                               (独立，按需触发)
  └─► run-tests (删除后全量验证)

pr-review                          (独立，commit 后调用)
hotfix
  └─► run-tests (针对性)
```

---

## 快速查找

- 收到新需求，需求不明确 → `requirement-clarification`
- 全新项目要做架构规划 → `project-bootstrap`
- 需求已确认，开始开发 → `auto-dev`
- 前端组件开发含 UX 验证 → `frontend-tdd`
- 要跑测试 → `run-tests`
- 要提交代码 → `commit-with-affects`
- 要检查单个页面/组件 UX → `frontend-ux-evaluator`
- 要全量扫描前端质量 → `scan-frontend-quality`
- 要生成 DB 迁移 DDL（含回滚） → `export-db-indexes`
- 要刷新 AI 上下文 → `sync-llm-context`
- 要清理孤儿文件/瘦身项目 → `slim`
- 要从 GAP 生成测试 → `generate-test-from-impact`
- 生产 P0 故障 → `hotfix`
