---
name: advise-tech-stack
description: 根据项目需求问卷，输出技术栈选型建议（前端/后端/数据库/工程约定），并说明不选方案的理由
trigger: /advise-tech-stack
inputs:
  - name: discovery_answers
    source: "用户对 project-bootstrap Phase 1 问卷的回答 / 用户参数描述"
    required: true
    description: "项目类型、用户规模、技术偏好、交付约束"
outputs:
  - name: tech_stack_proposal
    destination: "对话输出"
    description: "前端/后端/数据库/工程约定选型表，含选择理由和不选方案说明"
standalone: true
called_by:
  - workflow/project-bootstrap (Phase 2)
---

# Advise Tech Stack Skill

> **单独调用**：`/advise-tech-stack`（适用于已有项目做技术栈评估，或重构前的技术决策）
> **在工作流中调用**：由 `project-bootstrap` Phase 2 自动触发，输入来自 Phase 1 问卷

---

## 执行步骤

### Step 1：理解约束
从输入中提取关键决策因子：
- 用户规模/并发（影响架构复杂度）
- 团队技术偏好（影响选型可行性）
- 交付时间（影响成熟度 vs 新技术取舍）
- 多租户/权限（影响框架选择）

### Step 2：生成选型建议

输出以下格式：

```markdown
## 技术栈选型建议

### 前端
- 框架：{{框架}} — 理由：{{选择依据}}
- UI 库：{{库名}} — 理由：{{选择依据}}
- CSS 方案：{{方案}} — 理由：{{选择依据}}
- 状态管理：{{方案}} — 适用场景：{{说明}}
- 测试框架：{{框架}}

### 后端
- 语言/框架：{{框架}} — 理由：{{选择依据}}
- 数据库：{{DB}} — 理由：{{选择依据}}
- ORM：{{ORM}}
- 认证方案：{{方案}}

### 工程约定
- 代码仓库结构：monorepo / 分仓 — 理由：{{说明}}
- API 风格：RESTful / GraphQL / tRPC — 理由：{{说明}}

### 不选择 X 的原因（透明说明）
- {{备选方案}} → 不选，因为：{{理由}}
```

### Step 3：生成 project.config.json 草稿
基于选型结果，输出对应的 `project.config.json` 配置草稿供用户填写确认。

---

## 约束

- **MUST** 所有选型建议必须说明理由，不允许只给结论
- **MUST** 明确说明不选备选方案的原因（避免将来被追问）
- **NEVER** 推荐长期无人维护或 license 不兼容的库
- 若输入信息不足以做出合理判断，列出需要用户补充的问题，而非强行给出建议
