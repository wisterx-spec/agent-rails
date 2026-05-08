---
description: PR 创建与代码评审流程。在本地 commit 完成后、发版前执行。串联 PR 描述生成和自检两个独立 skill。
---

# PR / Code Review 工作流

> **触发指令**：`/pr-review`
> **触发时机**：`dev-flow` Step 9（commit）之后，`production-release` 之前
>
> **单步调用**：工作流内每个步骤也可独立触发：
> - `/generate-pr-description` — 仅生成 PR 描述
> - `/pr-self-review` — 仅执行自检清单

---

## Step 1：生成 PR 描述

调用 `generate-pr-description` skill。
→ 输出：完整 PR 描述 Markdown，供复制到 PR 描述框。

---

## Step 2：Review 检查清单（自检）

调用 `pr-self-review` skill。
→ 输出：代码质量 / 规范符合性 / 安全 / 测试 四维度逐项结果。

有 ⚠️ 项 → 告知用户，由用户决定是否修复后重新提交，或在 PR 描述中说明。

---

## Step 3：确定合并策略

根据 PR 类型选择合并方式：

| PR 类型 | 推荐策略 | 原因 |
|--------|---------|------|
| Feature（多 commit） | **Squash merge** | 保持 main 历史线性干净 |
| Hotfix（1-2 commit） | **Merge commit** | 保留 hotfix 时间点，便于回滚定位 |
| 重构（需保留细节） | **Rebase merge** | 保留完整提交历史但不产生 merge 节点 |

> 默认使用 **Squash merge**，除非有明确理由。

---

## Step 4：合并后清理

```bash
git branch -d feature/YYYYMMDD-功能简述
git checkout main && git pull origin main
```

---

## Step 5：触发下一步

- 立刻发版 → 触发 `/production-release`
- 积攒多个 feature 后发版 → 记录 changelog，等待发版窗口

---

## Reviewer 指南（给人类 Reviewer 的提示）

重点关注（AI 容易盲区）：
1. **业务逻辑正确性**：AI 对业务语义的理解可能有偏差
2. **边界条件**：低频但重要的异常路径
3. **性能隐患**：N+1 查询、大表全扫、循环内 I/O
4. **安全**：权限绕过、注入风险、敏感信息泄露

不需要重点关注：代码格式、命名风格（规范已约束）。
