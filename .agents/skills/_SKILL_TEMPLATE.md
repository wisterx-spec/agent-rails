---
name: skill-name
description: 一句话描述技能的作用，用于 SKILL_INDEX.md 索引和 AI 路由决策
trigger: /skill-name [可选参数]
inputs:
  - name: input_field
    source: "project.config.json → xxx / 上游 skill 输出 / 用户参数"
    required: true
    description: "说明这个输入是什么"
outputs:
  - name: output_field
    destination: "tmp/xxx.md / 对话输出 / 写入文件"
    description: "说明输出是什么格式、在哪里"
standalone: true        # 是否可单独调用（不依赖上游 skill 的输出）
called_by:
  - workflow/dev-flow (Step N)
  - workflow/auto-dev (Phase N)
---

# Skill 名称

> **单独调用**：`/skill-name [参数]`
> **在工作流中调用**：由 `workflow/xxx` 第 N 步自动触发，输入来自上游步骤
> **可跳过条件**：（说明何时可以不执行此 skill）

---

## 执行步骤

### Step 1: ...

### Step 2: ...

---

## 输出格式

```
（具体输出模板）
```

---

## 约束

- **MUST** ...
- **NEVER** ...
