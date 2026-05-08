---
name: record-decision
description: 将当前任务中做出的非显而易见技术决策写入 docs/decisions/，供 AI 和团队在后续接触相关代码时参考
trigger: /record-decision [topic]
inputs:
  - name: topic
    source: "用户参数 / AI 在 Ralph-loop 结束时检测到的决策点"
    required: true
    description: "决策的主题，如'认证方案'、'分页策略'"
  - name: context
    source: "当前对话上下文（规格书、实现过程中的讨论）"
    required: true
outputs:
  - name: decision_file
    destination: "docs/decisions/{{topic-slug}}.md"
    description: "符合 ADR 格式的决策记录文件"
  - name: index_update
    destination: "docs/decisions/README.md 索引表"
    description: "在索引表中追加一行指向新文件"
standalone: true
called_by:
  - workflow/auto-dev (Phase 5 收尾时，条件触发)
  - workflow/dev-flow (Step 9 前，条件触发)
---

# Record Decision Skill

> **单独调用**：`/record-decision 认证方案`
> **在工作流中调用**：当 auto-dev / dev-flow 在完成一个任务时，AI 检测到本次开发中存在非显而易见的决策，自动提议触发

---

## 触发判断条件

AI 在任务结束时，检查是否满足以下任意一条，满足则提议写决策记录：

1. 本次选择了一个有明显替代方案的技术路线（选 A 而不选 B）
2. 某个模块加了"不能随意改动"的约束（如权限检查、事务边界）
3. 故意绕开了通用模式（如某接口不走统一的错误处理中间件）
4. 依赖了一个会消失的外部约束（如"目前移动端不支持 Cookie"）
5. 用户在任务过程中说了"这里要注意"、"不要改这里"之类的话

**不需要写决策记录的情况**：
- 行业通用最佳实践（用索引、写单元测试等）
- 明显的权宜之计（临时 hack，已在代码注释里标注）
- 纯偏好选择（没有约束意义）

---

## 执行步骤

### Step 1：从上下文提取决策要素

从当前对话和代码中提取：
- 面临的背景/约束是什么
- 做了什么决定（一句话）
- 为什么（关键驱动因素）
- 选择带来了哪些代价
- 哪些改动会破坏这个决策（禁止事项）
- 涉及哪些代码路径（affects 字段）

### Step 2：生成决策文件

按 `docs/decisions/_template.md` 格式写入 `docs/decisions/{{topic-slug}}.md`。

文件名规则：全小写，空格用连字符，如 `jwt-auth-strategy.md`、`pagination-cursor-vs-offset.md`。

**必须**在 frontmatter 结束后立即生成 QUICK 摘要行（供 Phase 0 低成本读取）：

```
<!-- QUICK: NEVER [禁止事项1，≤15字] | NEVER [禁止事项2，≤15字] -->
```

规则：
- 只写禁止事项，不写原因（原因在正文）
- 每条 ≤ 15 字
- 最多 3 条，用 ` | ` 分隔
- 这是 AI 每次任务的低成本入口，必须高度精炼

### Step 3：更新 README.md 索引

在 `docs/decisions/README.md` 的索引表中追加一行：

```markdown
| [决策标题](文件名.md) | src/api/auth/, backend/app/ | NEVER 把 JWT 换成 Session Cookie |
```

### Step 4：输出确认

```
[DECISION RECORDED] docs/decisions/jwt-auth-strategy.md

核心约束已登记：
- NEVER 把 access token TTL 调长超过 2 小时
- NEVER 把 access token 存入 localStorage

下次 AI 接触 backend/app/routers/auth/ 时会先读取此决策。
```

---

## 约束

- **MUST** 写入 `docs/decisions/` 目录，不写在其他位置
- **MUST** 更新 `README.md` 索引，否则 AI 路由无法生效
- **NEVER** 把显而易见的常识写进来（浪费 token，稀释真正重要的决策）
- **NEVER** 修改 `.agents/rules/` 中的内容（知识库写保护）——决策记录属于 `docs/`，不属于规则层
- 决策文件由 AI 起草，**必须经人工确认后写入**（遵从 core.md 知识库写入权限红线的精神）
