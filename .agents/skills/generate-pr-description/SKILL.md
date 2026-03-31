---
name: generate-pr-description
description: 基于 git log 和 diff 自动生成标准 PR 描述，包含变更摘要、改动范围、测试覆盖、数据库变更等节
trigger: /generate-pr-description [--base=main]
inputs:
  - name: base_branch
    source: "用户参数 --base，默认 main"
    required: false
    description: "对比的目标分支"
outputs:
  - name: pr_description
    destination: "对话输出（供用户复制到 PR 描述框）"
    description: "Markdown 格式的完整 PR 描述"
standalone: true
called_by:
  - workflow/pr-review (Step 1)
---

# Generate PR Description Skill

> **单独调用**：`/generate-pr-description` 或 `/generate-pr-description --base=main`
> **在工作流中调用**：由 `pr-review` 工作流 Step 1 自动触发

---

## 执行步骤

### Step 1：提取变更信息
```bash
git log main..HEAD --oneline
git diff main...HEAD --stat
```

### Step 2：分析变更范围
根据 diff 路径判断涉及哪些层：
- `backend/` 路径 → 后端改动（路由、服务、模型）
- `frontend/` 路径 → 前端改动（页面、组件、状态）
- `alembic/` / `migrations/` 路径 → 数据库变更
- `tests/` 路径 → 测试覆盖

### Step 3：生成 PR 描述

```markdown
## 变更摘要
{{1-3 句话描述这个 PR 做了什么，解决了什么问题}}

## 改动范围

### 后端（如有）
- 新增/修改路由：{{列表}}
- 数据库变更：{{如无请删除此行}}
- 新增/修改 Service：{{列表}}

### 前端（如有）
- 新增/修改页面：{{列表}}
- 新增/修改组件：{{列表}}

## 测试覆盖
- [ ] 已运行 run-tests（快速模式），结果：PASSED / FAILED
- [ ] 已人工验证核心交互路径

## 数据库变更（如有）
{{粘贴 export-db-indexes 生成的 DDL；如无请删除此节}}

## Review 重点
{{告诉 Reviewer 哪里需要重点看，哪里是非显而易见的决策}}

## 相关背景
{{Issue 链接、需求规格确认书版本、或背景说明}}
```

---

## 约束

- **MUST** 变更摘要用用户语言（业务语言）而非技术语言
- **NEVER** 在描述中夸大变更范围或使用不确定的措辞
- 若涉及数据库变更但未见 `tmp/db_migration_*.sql`，提示用户先执行 `export-db-indexes`
