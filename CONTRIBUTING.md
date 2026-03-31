# 贡献指南

欢迎提交 Issue 和 PR。框架的核心是 Markdown 文件，贡献门槛很低。

---

## 贡献方式

### 报告问题

发现某个 workflow 或 skill 的行为不符合预期，或规则描述有歧义，请提 [Bug report](https://github.com/wisterx-spec/agent-rails/issues/new?template=bug_report.md)。

### 建议新 Skill 或 Workflow

有新的使用场景需要覆盖，请提 [Feature request](https://github.com/wisterx-spec/agent-rails/issues/new?template=feature_request.md)。

### 直接提 PR

---

## 新增 Skill

每个 skill 是一个独立目录，包含一个 `SKILL.md` 文件。

**目录结构：**

```
.agents/skills/your-skill-name/
  SKILL.md
```

**SKILL.md 必须包含的 frontmatter：**

```yaml
---
name: skill-name
description: 一句话描述这个 skill 做什么
trigger: /skill-name [参数]
inputs:
  - name: 参数名
    source: 来源描述
    required: true/false
outputs:
  - name: 输出名
    destination: 输出位置
standalone: true/false      # 是否可以独立调用
called_by:
  - workflow/xxx             # 被哪些工作流调用
---
```

**约束：**
- Skill 必须是原子的，做一件事
- 输入输出必须明确
- 执行步骤里的每个 Step 必须可验证
- NEVER 在 skill 里直接修改 `.agents/rules/` 或 `docs/lessons/`

新增 skill 后，同步更新 `.agents/SKILL_INDEX.md` 的注册表和依赖图。

---

## 新增 Workflow

Workflow 是纯编排层，只调用 skill，不直接实现逻辑。

**原则：**
- 每个步骤要么调用一个 skill，要么是人工卡点（等待用户确认）
- 不在 workflow 里写具体的 grep 命令或文件操作——那是 skill 的职责
- 新工作流触发指令必须在 README 快速指令表中注册

---

## 修改现有规则（`.agents/rules/`）

规则文件改动影响所有使用此框架的项目，请在 PR 描述中说明：
- 改动的动机（什么场景下现有规则不够用或有歧义）
- 是否会破坏现有项目的行为（breaking change）

---

## PR 规范

- 标题格式：`feat(skill): 新增 xxx skill` / `fix(workflow): 修复 auto-dev xxx 步骤`
- 描述中说明改动动机，不只说"做了什么"
- 如果新增了 skill，附上一个使用示例
