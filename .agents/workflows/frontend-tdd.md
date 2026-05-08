---
description: 前端 TDD + UX 卡点流程。以组件为单位：先写行为测试锁定契约，实现后跑测试，通过后触发 UX 评估，人工确认后才进入下一个组件。
---

# Frontend TDD + UX Gate 工作流

> **适用场景**：开发新页面、复杂交互组件，或需要交付高质量 UX 的功能迭代。
> **与普通前端开发的区别**：普通前端是 Code-First（先写组件再补测试）；本流程是 Component-TDD（每个组件必须先锁定行为测试，UX 评估通过后才进入下一个）。

---

## 核心节拍（Component Cadence）

每个组件/页面区块严格经历一个完整节拍后，才允许开始下一个：

```
[写测试] → [锁定基线] → [实现组件] → [跑测试] → [UX 评估] → [人工卡点] → ✅ 进入下一个
```

---

## 阶段零：前置拆解 (Component Breakdown)

在写任何代码之前，将本次需求拆解为**组件工作单元列表**：

1. 列出所有需要开发的组件/页面区块，例如：
   ```
   - [ ] SearchBar（含防抖、清空按钮、加载态）
   - [ ] ResultList（含空态、错误态、分页）
   - [ ] ItemCard（含操作菜单、危险操作二次确认）
   ```

2. 标注组件间依赖顺序（上游先做）。

3. **人工确认列表后**，按序逐一进入节拍。

---

## 节拍详述

### Step 1 — 写行为测试 (Behavior Test)

> 目标：用测试代码描述组件"应该做什么"，而非"长什么样"。

**测试文件位置**：`{{FRONTEND_TEST_PATH}}`（见 `project.config.json`）

**必须覆盖的测试维度**（与 UX Evaluator 维度对齐）：

| UX 维度 | 测试用例示例 |
|---------|-------------|
| 交互反馈 | `点击提交按钮后，按钮变为禁用状态` |
| 交互反馈 | `异步请求期间，显示 Loading 指示器` |
| 空态处理 | `数据为空时，渲染 EmptyState 组件` |
| 空态处理 | `请求失败时，显示错误态和重试按钮` |
| 危险操作 | `点击删除时，弹出确认对话框` |
| 危险操作 | `确认对话框取消时，不触发删除请求` |

**测试框架参考**：优先使用 `project.config.json → testing.commands.frontend_fast`；未配置时按项目现有测试脚本执行。下方仅为示例，不代表框架默认技术栈。

```typescript
// React + Testing Library 示例
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

describe('ItemCard', () => {
  it('点击删除时弹出确认对话框', async () => {
    render(<ItemCard item={mockItem} onDelete={mockDelete} />)
    await userEvent.click(screen.getByRole('button', { name: /删除/ }))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(mockDelete).not.toHaveBeenCalled()
  })

  it('确认删除后调用 onDelete', async () => {
    render(<ItemCard item={mockItem} onDelete={mockDelete} />)
    await userEvent.click(screen.getByRole('button', { name: /删除/ }))
    await userEvent.click(screen.getByRole('button', { name: /确认/ }))
    expect(mockDelete).toHaveBeenCalledWith(mockItem.id)
  })

  it('数据加载中时按钮禁用', () => {
    render(<ItemCard item={mockItem} loading={true} />)
    expect(screen.getByRole('button', { name: /删除/ })).toBeDisabled()
  })
})
```

> ⚠️ 此时**不写组件实现代码**，测试必然全部红色（FAIL），这是正确状态。

---

### Step 2 — 锁定测试基线 (Test Lock)

测试写完、人工 Review 测试用例合理后，立即锁定：

```bash
python .agents/scripts/test_lock.py lock
```

锁定后**严禁修改测试断言**。如果实现遇到困难，只能修改实现代码，不允许修改测试预期。

---

### Step 3 — 实现组件 (Implement)

目标：让 Step 1 写的测试从红色变绿色。

**实现过程中必须遵守的约束**（来自 `frontend-dev-guide` 与本次规范快照）：
- 仅当 `css_framework == "tailwind"` → 禁止物理色（`bg-blue-500`），只用语义 token
- 所有框架均适用 → 禁止裸 hex/rgb 硬编码颜色
- 使用项目统一组件库（弹窗、图标、EmptyState 等）

**开发循环**：
```
写代码 → 跑测试 → 看哪个用例变绿 → 继续 → 全部绿色 → 进入 Step 4
```

> 不要等所有组件都写完再跑测试，每次小改动就跑一次。

---

### Step 4 — 跑测试验绿 (Test Green)

```bash
# 只跑当前组件的测试，快速验证；实际命令以 project.config.json 或项目脚本为准。
npx vitest run src/components/ItemCard.test.tsx
# 或
npx jest --testPathPattern="ItemCard"
```

验证 test_lock 基线未被篡改：

```bash
python .agents/scripts/test_lock.py verify
```

**全部通过后**才进入 Step 5。若有失败，打回 Step 3 继续修改实现。

---

### Step 5 — UX 评估卡点 (UX Gate)

触发 `frontend-ux-evaluator` 对当前组件进行评估：

> 用户指令示例：`/frontend-ux-evaluator 评估 ItemCard 组件`

评估器输出结构化报告：

```
## UX 评估报告：ItemCard

| 严重性 | 维度 | 问题描述 | 建议修复 |
|--------|------|---------|---------|
| 🔴 高  | 危险操作 | 删除无二次确认 | 接入 DeleteConfirmModal |
| 🟡 中  | 空态处理 | loading=true 时图标闪烁 | 增加 transition 过渡 |
```

**评估维度**（完整定义见 `frontend-ux-evaluator/SKILL.md`）：
1. 交互反馈完整性（Loading / 成功 / 失败）
2. 空态与边界处理
3. 组件规范符合性（弹窗、图标、颜色）
4. 可用性与可访问性
5. 布局与响应式

---

### Step 6 — 人工确认卡点 (Human Gate)

**强制挂起**，等待人工决策：

```
🔴 高优先级问题（N 个）：本次 PR 内必须修复，否则不得进入下一个组件
🟡 中优先级问题（N 个）：在本次节拍内修复，或登记入 P2 问题队列
🟢 低优先级问题（N 个）：登记入 P2 问题队列，下次迭代处理
```

**决策规则**：
- 有 🔴 高优先级未修复 → 返回 Step 3 修复，修复后重新触发 Step 5
- 🔴 全部通过 → 人工回复"通过"/"可以"后，才进入下一个组件

> P2 问题自动追加到当前任务的《问题全量清单》队列，不插队，不遗漏。

---

## 完整一轮示例

```
需求：开发 ResultList 组件（含空态、错误态、分页）

Step 1：写 3 个测试用例
  - 数据为空时渲染 EmptyState
  - 请求失败时显示错误态 + 重试按钮
  - 点击分页时滚动至顶部

Step 2：锁定基线（test_lock.py lock）

Step 3：实现 ResultList 组件
  → 测试 1 变绿：加了 EmptyState 判断
  → 测试 2 变绿：加了 error state
  → 测试 3 变绿：加了 scrollTo 逻辑

Step 4：全部绿色 ✅，verify 基线未篡改 ✅

Step 5：UX 评估 → 报告：
  🔴 高：loading 态缺失（未覆盖网络慢场景）
  🟡 中：分页组件用了裸 div，建议换统一 Pagination

Step 6：人工确认
  → 🔴 loading 态必须补，返回 Step 3
  → 同时补充 测试用例 4：loading=true 时显示 Spinner
  → 重新锁定基线，实现，测试绿，重新 UX 评估
  → 🔴 全部消除，人工回复"通过"
  → 🟡 登记为 P2，进入下一个组件
```

---

## 与 dev-flow 的关系

本流程是 `dev-flow.md` Step 5（测试骨架优先）、Step 6（开发）和 Step 8（测试门禁）在**前端 TDD 场景**下的展开版本：

```
dev-flow Step 5 → 本流程 Step 1~2（按组件逐一写测试 + 锁定）
dev-flow Step 6 → 本流程 Step 3~4（实现 + 验绿）
dev-flow Step 6 → 本流程 Step 5~6（UX 评估 + 人工卡点）
dev-flow Step 8 → 全部组件通过后，再跑全量测试
```

**触发条件**：在 `dev-flow` 或 `auto-dev` 中，当前任务涉及前端组件且有 UX 质量要求时，dev-flow Step 5 改为触发本流程。

---

## 约束汇总

- **NEVER** 跳过 Step 2 锁定直接开始实现
- **NEVER** 用修改测试断言来让测试变绿
- **NEVER** 跳过 UX 评估直接进入下一个组件（即使测试全绿）
- **NEVER** 在有未消除的 🔴 问题时进入下一组件
- **MUST** 每次修复 🔴 问题后重新触发 UX 评估（不能凭感觉判断修好了）
