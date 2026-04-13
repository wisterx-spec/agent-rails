---
name: pr-self-review
description: 对本次 PR 改动执行结构化自检，覆盖代码质量、规范符合性、安全、测试四个维度，输出通过/失败逐项清单
trigger: /pr-self-review
inputs:
  - name: diff
    source: "git diff main...HEAD（自动获取）"
    required: true
outputs:
  - name: review_checklist
    destination: "对话输出"
    description: "逐项自检结果，标注通过/失败/需人工确认"
standalone: true
called_by:
  - workflow/pr-review (Step 2)
---

# PR Self-Review Skill

> **单独调用**：`/pr-self-review`
> **在工作流中调用**：由 `pr-review` 工作流 Step 2 自动触发

---

## 执行步骤

### Step 1：获取变更文件清单
```bash
git diff main...HEAD --name-only
```

### Step 2：逐维度自检

**代码质量**（搜索验证）：
```bash
grep -rn "console\.log\|TODO\|FIXME\|HACK" 变更文件列表
grep -rn "localhost:\|127\.0\.0\.1\|硬编码域名" 变更文件列表
```

**规范符合性**（条件执行）：
- 有数据库文件变更 → 读取 `db-dev-guide` skill（`.agents/skills/db-dev-guide/SKILL.md`）并逐条验证
- 有前端文件变更 → 检查 Tailwind 物理色、裸 hex（若 css_framework=tailwind）
- 有 commit message → 验证格式是否符合 `commit-with-affects` 规范

**安全**（搜索验证）：
```bash
grep -rn "f\".*{.*}\|f'.*{.*}'\|%s.*%" 变更文件  # Python SQL 拼接风险
grep -rn "\.query\(.*\+\|\.execute\(.*\+" 变更文件  # SQL 拼接风险
```

**测试**：
- 检查新增的业务文件是否有对应的测试文件
- 检查测试文件中是否有断言（非空测试）

### Step 3：输出结构化结果

---

## 输出格式

```
## PR 自检报告

### 代码质量
- [x] 无 console.log 调试语句
- [x] 无硬编码地址
- [ ] ⚠️ 发现 TODO 注释：backend/app/service.py:45 — 建议处理或转为 issue

### 规范符合性
- [x] 数据库变更符合 db.md 规范
- [x] 前端无 Tailwind 物理色
- [x] Commit message 格式正确

### 安全
- [x] 无 SQL 拼接
- [ ] ⚠️ 需人工确认：新增 API /api/admin/xxx 是否有权限校验

### 测试
- [x] 新增 Service 有对应测试文件
- [ ] ⚠️ src/services/NewFeature.ts 无对应测试文件，请说明原因

---
自检完成：3 项通过，3 项需关注（标注 ⚠️）
```

---

## 约束

- **MUST** 每一项检查都通过工具验证（grep / 文件读取），不凭感觉判断
- **NEVER** 将"需人工确认"项标为通过
- 输出的 ⚠️ 项必须给出具体文件路径和行号（便于定位）
