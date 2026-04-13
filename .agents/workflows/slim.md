---
description: 项目瘦身工作流。串联 4 个独立扫描 skill，生成可审查的删除提案，人工确认后执行删除并验证。
---

# Slim 项目瘦身工作流

> **触发指令**：`/slim [--scope=frontend|backend|all]`
> **核心原则**：AI 只生成《删除提案》，不自动执行任何删除。所有删除操作必须经人工确认。
>
> **单步调用**：工作流内每个扫描阶段也可独立触发：
> - `/scan-orphan-components` — 仅扫孤儿组件
> - `/scan-dead-routes` — 仅扫死路由
> - `/scan-unused-exports` — 仅扫未引用导出
> - `/scan-bundle-bloat` — 仅扫依赖体积

---

## 前置：读取豁免清单

若 `.slimignore` 不存在，**立即停止**，提示用户先创建（参考 `.slimignore.example`）。

---

## Phase 1：孤儿组件扫描

调用 `scan-orphan-components` skill。
→ 输出：孤儿组件候选列表。

---

## Phase 2：死路由扫描

调用 `scan-dead-routes` skill。
→ 输出：幽灵路由 + 孤儿页面列表。

---

## Phase 3：未引用导出扫描

调用 `scan-unused-exports` skill。
→ 输出：未引用导出候选列表。

---

## Phase 4：依赖体积扫描

调用 `scan-bundle-bloat` skill。
→ 输出：重型依赖优化建议。

---

## Phase 5：钢印健康审查（可选）

调用 `review-guardrails` skill，审查 conventions/lessons/decisions/guide skills 的健康度。
→ 输出：过期/冲突/冗余/覆盖缺口审查报告。
**跳过条件**：用户指定 `--skip-guardrails` 或明确只做代码瘦身时可跳过。

---

## Phase 6：生成《删除提案》

汇总 Phase 1-4 的所有输出，生成结构化提案：

```markdown
# 项目瘦身提案 {{date}}

## 执行前提醒
- 基于静态分析，动态引用可能被误判
- .slimignore 中的豁免项已排除

## P0 — 确认可删除（零静态引用，非豁免）
- [ ] `{{文件路径}}`

## P1 — 需人工判断（可能有动态引用）
- [ ] `{{文件路径}}` — 原因：{{疑似动态加载}}

## P2 — 依赖优化（替换依赖，不删文件）
- [ ] moment → dayjs（估算节省 65KB gzip）

## 豁免项（不处理）
- `{{路径}}` — .slimignore 声明原因
```

**强制挂起**，等待人工回复"执行 P0"/"执行全部"后才进入 Phase 6。

---

## Phase 7：执行删除（仅在人工确认后）

1. 创建专用分支：`git checkout -b slim/{{date}}`
2. 逐文件删除（不批量 rm），每删一个记录日志
3. 调用 `run-tests --mode=full` 执行全量测试
4. 测试全通过 → 调用 `commit-with-affects` 提交
5. 测试有失败 → **立即回滚该文件** + 更新 `.slimignore`

```
## 误删记录（自动追加到 .slimignore）
# 误删于 {{date}}，动态引用：{{路径}}
src/components/{{误删文件}}
```

---

## 约束

- **NEVER** 在未读 `.slimignore` 的情况下开始任何扫描 skill
- **NEVER** 批量 `rm -rf`，只允许逐文件删除
- **MUST** 删除后调用 `run-tests --mode=full`，失败必须回滚
