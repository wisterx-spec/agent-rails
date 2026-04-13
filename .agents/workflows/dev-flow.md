---
description: 新需求开发标准流程。开始开发新功能前串联系统内各个隔离的防御、开发与代码查验模块。
---

# Dev-Flow: Unified Feature Development Pipeline

> **与 `/auto-dev` 的区别**：
> - `/dev-flow`：**人工驱动**。每步由人类主动推进，适合需要深度介入或边做边决策的场景。
> - `/auto-dev`：**AI 自驱**。AI 自动串联所有步骤（内部调用 dev-flow），适合需求明确、可交给 AI 全程执行的场景。
>
> **通常选 `/auto-dev`。** 只有在以下情况选 `/dev-flow`：探索性开发、需求模糊边做边改、或 auto-dev 中断后手动接续某个步骤。

当要开始一项全新的业务开发时，必须触发此标准全量工作流，执行绝对无损的开发闭合链：

### 1. 🌍 探测与预研 (Context Sync - Conditional)
**条件触发**：仅当本次需求涉及【新建后端路由 / 全局大重构】时执行 `sync-llm-context` 技能。
**目的**：对于破坏性极强或易牵连全局的动作，此步骤强迫 AI 在开工前动态全盘刷新当前最新雷达地图。如果是普通的修 Bug 或调 UI 等单点局部开发，**必须直接跳过此步**，避免无谓的算力开销。

### 2. 🛑 脑部钢印读取 (Guardrails Enforcement)
在真正写入代码前，强制根据改动域加载规则护栏：
- **任何开发** → 读取 `docs/conventions.md` 的 `## 核心约定速查` 区块（止于第一条 `---` 分隔线），完整内容按需读取。**过期检测**：条目日期超过 90 天的标注 `[STALE]`，在 Step 9 提交前统一审查。
- **开发后端** → 强制通过工具只读 `docs/lessons/backend.md`（如存在）
- **开发前端** → 强制阅读 `frontend-dev-guide` skill（`.agents/skills/frontend-dev-guide/SKILL.md`）中关于禁用色彩和组件约束的规定
- **修改数据库表** → 强制阅读 `db-dev-guide` skill（`.agents/skills/db-dev-guide/SKILL.md`）中的建模规范

### 3. 📋 方案评审卡点 (Proposal Review - Conditional)
**条件触发**：当本次需求为新功能开发、涉及 API/DB/跨组件改动、或预计改动文件超过 2 个时，调用 `proposal-review` skill（`/proposal-review`），将实现方案翻译成人类可判断的语言，生成方案评审文档。
**跳过条件**：单文件局部修改（修文案、调样式）或 ≤ 2 文件的 bug fix 可直接跳过。
**强制卡点**：Agent 必须停下来等待人工逐字段检查方案评审文档。只有在用户回复"确认，继续执行"后，才允许进入下一步。
**红线**：需要执行 proposal-review 但未经人工确认时，不允许执行 impact-analysis，不允许生成测试骨架，不允许写任何业务代码。

### 4. 🔍 变更影响预判 (Impact Analysis - Conditional)
**条件触发**：当本次需求涉及 API 接口 / 数据库表结构 / 跨组件共享状态、或预计改动文件超过 3 个时，执行 `/impact-analysis` 工作流。
**目的**：在动手写代码之前，先扫描预期改动范围，输出爆炸半径与测试盲区（GAP 清单）。
**跳过条件**：单文件局部修改（如修文案、调样式）可直接跳过。

### 5. 📝 测试骨架优先 (Test-First Skeleton - Layered)
根据改动类型，决定是否先写测试骨架：

| 改动类型 | 策略 | 说明 |
|---|---|---|
| 后端 API / Service 层 | **Test-First** | 先写测试骨架锁定接口契约（请求参数/响应字段/状态码），再写实现 |
| 数据库迁移 / 批处理 | **Test-First** | 先写边界防御断言（分片正确性/事务回滚/锁保护） |
| 前端 UI（有 UX 质量要求） | **Component-TDD** | 触发 `frontend-tdd` 流程：按组件逐一写行为测试 → 锁定 → 实现 → UX 评估卡点 → 人工确认 → 进入下一个 |
| 前端 UI（纯样式微调） | **Code-First** | 先实现效果，稳定后补关键交互的 E2E |
| 探索性 / Prototype | **Code-First** | 先跑通再说，稳定后补测试 |

**测试骨架生成**：对于 Test-First / Component-TDD 场景，调用 `generate-test-skeleton` skill（`/generate-test-skeleton --type=api|service|db|frontend`）生成测试骨架。
> 单独调用：`/generate-test-skeleton --type=api`

**核心约束**：测试骨架一旦由人类确认，在整个编码周期内**严禁修改测试断言**。测试就是"不可更改的验收合同"。
> 🔒 **基线锁定**：人类确认测试骨架完毕后，必须立即执行 `python .agents/scripts/test_lock.py lock` 建立防篡改存档。此后如果测试失败，严禁修改预期断言。

> **Component-TDD 详细节拍** → 见 `.agents/workflows/frontend-tdd.md`：
> 写行为测试 → 锁定基线 → 实现组件 → 验绿 → UX 评估（`frontend-ux-evaluator`）→ 人工卡点（🔴 必须修复）→ 进入下一个组件

### 6. ⌨️ 原生开发阻击 (Isolate Execution)
在这个阶段尽情新建文件、编写逻辑。所有报错、排障生成的残次文件必须全部关在根目录下的 `tmp/` 里，不要污染 Git 运行池。
**Test-First 场景约束**：编码目标是"让步骤 5 锁定的测试变绿"，不允许为了绿灯而修改测试断言。

### 7. 🗄️ 数据库切片审计 (DB Validation - Optional)
如果第六步中修改了数据库模型，强制唤起 `export-db-indexes` 技能。
**目的**：为每一个字段、每一个新索引自动对比线上表生成增量 DDL 脚本片段 `ALTER TABLE...`，并带上真实 Query SQL 业务逻辑供 DBA Review。

### 8. 🛡️ 测试阻断网 (Test Gates)
一切功能写完准备提交前，调用 `run-backend-tests` 扫描（使用 `--mode fast` 选项跳过耗时的集成测试）。
**红线约束**：如果有抛错，打回修改代码直至全 Pass 为止，决不允许带 Bug 的逃逸提交。

### 9. 📦 包装及移交 CI/CD (Smart Commit Handoff)
最终合库！调用 `commit-with-affects` 技能，逆向扫描 `git diff`，计算出牵扯到哪些具体业务模块，生成带有影响面评估的标准化 Commit message。
