---
name: plan-component-hierarchy
description: 根据页面地图和技术栈，规划组件分层约定、必建基础组件清单、状态管理边界
trigger: /plan-component-hierarchy
inputs:
  - name: page_map
    source: "plan-page-map 输出 / 用户描述"
    required: true
  - name: tech_stack
    source: "project.config.json → tech_stack / advise-tech-stack 输出"
    required: true
outputs:
  - name: component_hierarchy
    destination: "对话输出（建议写入 docs/architecture/components.md）"
    description: "组件分层规则、必建组件清单、状态管理边界约定"
standalone: true
called_by:
  - workflow/project-bootstrap (Phase 4)
---

# Plan Component Hierarchy Skill

> **单独调用**：`/plan-component-hierarchy`（适用于现有项目重构组件结构，或新功能模块规划）
> **在工作流中调用**：由 `project-bootstrap` Phase 4 自动触发

---

## 执行步骤

### Step 1：定义分层规则
根据项目规模和技术栈，输出组件分层约定。

### Step 2：生成必建基础组件清单
在第一个业务功能开发前必须存在的组件（哪怕是空壳），避免后期补做造成不一致。

### Step 3：定义状态管理边界
明确哪类数据用哪种方案管理，防止状态混乱。

---

## 输出格式

```markdown
## 组件层级约定

### 分层规则
- `components/ui/` — 纯展示原子组件（Button、Input、Badge）。无业务逻辑，无 API 调用
- `components/common/` — 跨业务复用功能组件（DataTable、EmptyState、ConfirmModal）
- `components/{{模块名}}/` — 业务专属组件，只在对应模块内使用
- `pages/` / `app/` — 页面级，负责数据获取和布局编排

### 禁止事项
- NEVER 在 ui/ 原子组件中调用 API 或访问全局 store
- NEVER 在 pages/ 中写超过 50 行的 JSX（抽为组件）
- NEVER 跨模块直接 import 业务组件（应提升到 common/）

### 状态管理边界
- 服务端数据：{{React Query / SWR / Pinia}} — 理由：{{说明}}
- 全局 UI 状态：{{Zustand / Pinia / Vuex}} — 理由：{{说明}}
- 表单状态：{{React Hook Form / VeeValidate}}

### 必建基础组件清单（开发第一个功能前完成）
- [ ] `Layout` — 全局布局框架
- [ ] `EmptyState` — 空数据占位
- [ ] `LoadingSpinner` / `Skeleton` — 加载态
- [ ] `ErrorBoundary` — 错误边界
- [ ] `ConfirmModal` — 危险操作确认弹窗
- [ ] `DataTable` — 列表表格（含分页插槽）
- [ ] `PageHeader` — 页面标题区
```

---

## 约束

- **MUST** 必建组件清单必须在 `project-bootstrap` 归档时写入项目 `README.md` 或 `docs/`
- **NEVER** 在分层规则中设计超过 4 层的目录（增加认知负担）
- 根据技术栈调整状态管理方案（Vue 项目推荐 Pinia，React 项目推荐 Zustand / React Query）
