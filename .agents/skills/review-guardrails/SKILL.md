---
name: review-guardrails
description: 审查脑部钢印健康度。扫描 conventions、lessons、decisions、guide skills，检测过期、冲突、冗余条目，输出结构化清理方案。
trigger: /review-guardrails
standalone: true
called_by:
  - workflow/slim（可选步骤）
  - workflow/auto-dev Phase 5（存在 STALE 标注时自动触发简化版）
---

# 脑部钢印审查 (Guardrails Review)

> **目的**：规范只增不减会导致过期条目积累、注意力稀释、新旧矛盾。本 skill 对所有"钢印"内容做一次全面体检。
> **独立使用**：随时 `/review-guardrails` 主动审查。
> **集成使用**：`/slim` 工作流可在清理阶段调用本 skill。

---

## 审查范围

| 文件 | 检查内容 |
|------|---------|
| `docs/conventions.md` | 约定条目的时效性、与实际代码的一致性 |
| `docs/lessons/backend.md` | 经验条目的时效性、是否已被 conventions 吸收 |
| `docs/lessons/frontend.md` | 同上 |
| `docs/lessons/testing.md` | 同上 |
| `docs/decisions/` | 决策的时效性、affects 路径是否仍然有效 |
| `.agents/skills/frontend-dev-guide/SKILL.md` | 与 lessons/frontend.md 的一致性 |
| `.agents/skills/db-dev-guide/SKILL.md` | 与 lessons/backend.md 中 DB 相关条目的一致性 |

---

## 执行步骤

### Step 1：读取所有钢印文件

按顺序读取上述所有文件。若某文件不存在，标注"缺失"并继续。

### Step 2：逐维度检测

#### 2.1 时效性检测（Staleness）

扫描每个条目的日期标注：
- **> 90 天**：标记为 `[STALE]`，需要人工确认是否仍然有效
- **无日期**：标记为 `[NO_DATE]`，需要补充日期或审查后标注
- **≤ 90 天**：正常，不标记

#### 2.2 冲突检测（Conflict）

交叉比对以下来源，检查是否存在矛盾：
- `lessons/*.md` 中的踩坑记录 vs `conventions.md` 中的约定（lessons 说"别这么做"，但 conventions 没有反映）
- `lessons/*.md` 中的经验 vs `guide skills` 中的规范（lessons 说了新做法，但 guide 还是旧规范）
- `decisions/` 中的决策 vs 当前代码实际做法（决策说用 A 方案，但代码已经改成了 B）

每发现一处冲突，输出：
```
[CONFLICT] {{来源A}} vs {{来源B}}
  来源A 说：{{内容摘要}}
  来源B 说：{{内容摘要}}
  建议：{{统一为哪个 / 需要人工判断}}
```

#### 2.3 冗余检测（Redundancy）

检查是否存在同一条规则在多个地方重复：
- conventions.md 和 guide skill 说了同一件事
- lessons 中的踩坑已被 conventions 吸收但 lessons 条目未标注"已归档"
- 多个 lessons 文件中记录了同一个问题

每发现一处冗余，输出：
```
[REDUNDANT] {{内容摘要}}
  出现在：{{文件1 行号}}、{{文件2 行号}}
  建议：保留 {{推荐位置}}，其他位置删除或改为引用
```

#### 2.4 覆盖度检测（Gap）

检查是否存在应该有但没有的规范：
- lessons 中反复出现同类踩坑（≥ 2 次），但 conventions 中没有对应约定
- guide skill 中的某个章节从未被 lessons 中的经验触及（可能过于理论化，也可能运气好没踩坑）

每发现一处缺口，输出：
```
[GAP] {{描述}}
  证据：{{来源文件和条目}}
  建议：{{补充到哪里}}
```

### Step 3：输出审查报告

汇总所有检测结果，按优先级排序输出：

```markdown
## 脑部钢印审查报告（{{YYYY-MM-DD}}）

### 📊 概览
- 扫描文件：{{N}} 个
- 总条目数：{{N}} 条
- 过期条目：{{N}} 条（STALE）
- 无日期条目：{{N}} 条（NO_DATE）
- 冲突：{{N}} 处
- 冗余：{{N}} 处
- 覆盖缺口：{{N}} 处

### 🔴 需要立即处理（冲突）
{{逐条列出 CONFLICT}}

### 🟡 需要审查确认（过期 + 无日期）
{{逐条列出，每条附 → 保留 / 更新 / 删除 选项}}

### 🟢 建议优化（冗余 + 覆盖缺口）
{{逐条列出 REDUNDANT 和 GAP}}
```

### Step 4：等待人工逐条处理

输出报告后停止，等待人工对每条标注做出决定。
人工确认后，Agent 按指令执行修改（更新日期 / 修改内容 / 删除条目 / 补充新条目）。

### Step 5：更新审查时间戳

所有修改完成后，将当前日期写入 `tmp/.last-guardrails-review`：
```
{{YYYY-MM-DD}}
```
此文件供启动协议读取，用于计算距上次审查的天数（超过 3 天触发提醒）。

---

## 约束

- **MUST** 读取所有审查范围内的文件，不允许跳过
- **MUST** 冲突检测必须交叉比对，不允许只看单个文件
- **MUST** 输出报告后等待人工确认，不允许自动执行修改
- **NEVER** 自动删除任何条目，即使明显过期
- **NEVER** 自动修改 guide skill 内容，只输出建议
