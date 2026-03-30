---
description: PR 创建与代码评审流程。在本地 commit 完成后、发版前执行。覆盖 PR 描述生成、Review 检查清单、合并策略。
---

# PR / Code Review 工作流

当用户输入 `/pr-review` 时执行。通常在 `dev-flow` Step 8（commit）之后，`production-release` 之前触发。

---

## Step 1：生成 PR 描述

基于 `git log main..HEAD` 和 `git diff main...HEAD` 自动生成 PR 描述，格式如下：

```markdown
## 变更摘要
<!-- 1-3 句话说清楚这个 PR 做了什么，解决了什么问题 -->

## 改动范围

### 后端
- [ ] 新增/修改路由：
- [ ] 数据库变更：（如无请删除）
- [ ] 新增/修改 Service：

### 前端
- [ ] 新增/修改页面：
- [ ] 新增/修改组件：
- [ ] 状态变更：（如无请删除）

## 测试覆盖
- [ ] 已运行 run-backend-tests（快速模式），结果：PASSED / FAILED
- [ ] 已人工验证核心交互路径

## 数据库变更
<!-- 如有，粘贴 export-db-indexes 生成的 DDL；如无请删除此节 -->

## 注意事项 / Review 重点
<!-- 告诉 Reviewer 哪里需要重点看 -->

## 相关 Issue / 背景
```

---

## Step 2：Review 检查清单（自检）

提交 PR 前，AI 对本次改动执行自检，逐项确认：

### 代码质量
- [ ] 没有遗留 `TODO` / `FIXME` / `console.log`（已在 production-release 扫描，此处二次确认）
- [ ] 没有硬编码的环境地址或密钥
- [ ] 新增函数/方法有清晰的命名，不需要额外注释
- [ ] 删除的代码已确认无其他引用（全局搜索验证）

### 规范符合性
- [ ] 数据库模型变更符合 `.agents/rules/db.md` 规范
- [ ] 前端改动符合 `.agents/rules/frontend-ui.md` 规范
- [ ] Commit message 格式正确，包含必要的影响面信息

### 安全
- [ ] 无 SQL 拼接（使用 ORM 参数化查询）
- [ ] 用户输入有边界校验
- [ ] 权限检查覆盖所有新增接口

### 测试
- [ ] 新增功能有对应测试（或在 PR 描述中说明为何不需要）
- [ ] 测试覆盖了正常路径和异常路径

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
# 合并后删除本地 feature 分支
git branch -d feature/YYYYMMDD-功能简述

# 同步本地 main
git checkout main && git pull origin main
```

---

## Step 5：触发下一步

合并完成后，根据发版计划决定：

- 立刻发版 → 触发 `/production-release`
- 积攒多个 feature 后发版 → 记录在项目 changelog 或 issue 中，等待下次发版窗口

---

## Reviewer 指南（给人类 Reviewer 的提示）

如果你是本次 PR 的人工 Reviewer，重点关注：

1. **业务逻辑正确性**：AI 擅长生成符合规范的代码，但对业务语义的理解可能有偏差
2. **边界条件**：AI 容易遗漏低频但重要的异常路径
3. **性能隐患**：N+1 查询、大表全扫、循环内 I/O 等
4. **安全**：权限绕过、注入风险、敏感信息泄露

不需要重点关注：代码格式、命名风格（框架已有规范约束）。
