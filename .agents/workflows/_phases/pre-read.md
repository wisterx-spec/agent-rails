# 规范预加载 (Pre-read)

> 本文件被 auto-dev Phase 0 和 dev-flow Step 2 引用。
> 所有开发开始前必须执行，不可跳过。

---

## 步骤

### 1. 读取项目约定文档

读取 `docs/conventions.md` 的 `## 核心约定速查` 区块（止于第一条分隔线 `---`），将其中约定加入本次《规范快照》。

- **过期检测**：条目日期超过 90 天的，在快照中标注 `[STALE: {{条目标题}}]`，留至收口阶段统一审查
- **NEVER 读取分隔线之后的完整内容**（Verify 阶段发现潜在违规时按需读取对应章节）
- 若文件不存在 → 跳过，不报错

### 2. 按需路由加载 SKILL.md

只读命中项，未命中跳过：

| 任务涉及 | 加载目标 |
|---------|---------|
| 前端 | `frontend-dev-guide/SKILL.md` + `generate-test-skeleton/SKILL.md` + `frontend-ux-evaluator/SKILL.md` |
| 数据库 | `db-dev-guide/SKILL.md` + `export-db-indexes/SKILL.md` |
| 权限 | `project.config.json` 中 `auth.docs_path` 指向的文档 |
| 任何任务 | `commit-with-affects/SKILL.md` |

**NEVER 加载未在上表命中的 SKILL.md**。

### 3. 决策记录预读

- 读取 `docs/decisions/README.md` 索引表
- 对照本次任务涉及的模块路径，找出命中 `affects` 字段的决策文件
- **只读每个命中文件的 `<!-- QUICK: -->` 行**（frontmatter 之后第一行），提取 NEVER 条目加入快照禁止清单
- 需要完整 ADR 上下文时（如大幅重构相关模块）才读全文
- 若索引表为空或不存在 → 跳过，不报错

### 4. 经验库预读

触碰以下领域前，查阅经验库（如存在）：
- 修改业务路由/任务/迁移 → `docs/lessons/backend.md`
- 修改前端组件/全局状态 → `docs/lessons/frontend.md`
- 编写含外部 I/O 的测试 → `docs/lessons/testing.md`

### 5. 生成《本次任务规范快照》

格式约束：
- 本次涉及的技术层（前端 / 后端 / DB / 权限）
- 每层强制约束：**最多 5 条**，每条不超过 20 字，只写本任务特有的
- 禁止事项清单：只列本任务相关的，通用红线不重复（已在规则文件）
- token / 设计系统定义位置：**只记文件路径**，不复制内容
- **快照总长度控制在 30 行以内**

### 6. 封存快照

快照生成后即封存。**NEVER 在后续步骤中重新读取规则文件或 SKILL.md**。所有规范引用必须来自本快照。唯一例外：Verify 阶段需核查源文件具体实现时，可只读目标文件，不更新快照。
