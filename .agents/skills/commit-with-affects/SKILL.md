---
name: commit-with-affects
description: 生成结构化 git commit message，自动分析 diff 计算影响面并附带影响评估。在每次准备提交代码时执行。
---

# Commit-with-Affects Skill

## 触发时机
每次准备提交代码时执行，尤其是修改了 API 接口、Service 层、核心业务逻辑时。

---

## 执行步骤

### Step 0：代码卫生强制门禁 (Pre-commit Gate)

在分析改动并生成 commit message 之前，**必须按顺序执行以下两项检查**：

**0-A：规范扫描（强制，不可跳过）**

调用 `scan-code-hygiene --scope=staged`：
- **P0 问题**（hardcoded secrets、hardcoded env URL）：**立即中断**，必须修复后重新提交，不可绕过
- **P1 问题**（console.log、TODO、调试代码）：允许提交，但必须在 commit message body 中以 `known-issues:` 字段列出

**0-B：测试验证（强制，不可跳过）**

调用 `run-tests --mode=fast` 验证核心逻辑：
- 测试失败 → **立即中断**，必须修复后重新执行
- 测试通过 → 继续

### Step 1：分析本次改动

```bash
git diff HEAD --stat          # 查看变更文件列表
git diff HEAD                 # 查看详细 diff
git log -1 --pretty=full      # 查看上次 commit 内容（作为参考）
```

### Step 2：判断 commit 类型

根据改动内容，从以下类型中选择最准确的一个：

| 类型 | 触发场景 |
|------|---------|
| `feat` | 新增业务功能 |
| `fix` | 修复 Bug |
| `refactor` | 重构（不改变行为）|
| `perf` | 性能优化 |
| `test` | 新增或修改测试 |
| `chore` | 构建/脚本/依赖等维护性改动 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响逻辑）|

### Step 3：计算影响面（仅当 project.config.json 中 affects_field_enabled = true）

基于 diff 内容分析本次改动涉及的业务模块：
- 检查修改的路由、API 路径、页面组件
- 识别受影响的业务模块名称（如 `auth`, `dashboard`, `settings`）
- 评估测试优先级：`high`（核心流程）/ `medium`（辅助功能）/ `low`（纯样式/文案）

### Step 4：组装 Commit Message

**基础格式**（所有项目适用）：
```
{type}({scope}): {description}

{body}（可选，多行说明）
```

**扩展格式**（当 `affects_field_enabled = true`）：
```
{type}({scope}): {description}

affects: {module-a},{module-b}
changed-interfaces: {/api/v1/xxx}
test-priority: {high|medium|low}
```

**约束规则**：
- 标题行不超过 72 个字符
- 描述使用中文，动词开头（"新增"、"修复"、"重构"）
- scope 为受影响的最小模块名
- 不写"优化了一些东西"之类的模糊描述

### Step 5：执行提交

```bash
git add {具体文件路径}   # 禁止使用 git add . 或 git add -A（防止误提交敏感文件）
git commit -m "{组装好的 commit message}"
```

---

## 示例输出

**基础格式（affects_field_enabled = false）**：
```
feat(user-auth): 新增第三方 OAuth 登录支持

支持 GitHub / Google OAuth 回调，新增 /auth/oauth/callback 路由。
```

**扩展格式（affects_field_enabled = true）**：
```
feat(user-auth): 新增第三方 OAuth 登录支持

affects: auth,dashboard
changed-interfaces: /api/v1/auth/oauth/callback
test-priority: high
```
