---
name: plan-page-map
description: 根据需求描述和技术栈，规划完整的页面地图（路由结构），标注 MVP 范围和推迟页面
trigger: /plan-page-map
inputs:
  - name: feature_requirements
    source: "需求规格确认书 / 用户描述 / project-bootstrap Phase 1 答案"
    required: true
  - name: auth_roles
    source: "用户输入或 project-bootstrap 问卷"
    required: false
    description: "有哪些角色，影响权限页划分"
outputs:
  - name: page_map
    destination: "对话输出（建议写入 docs/architecture/page-map.md）"
    description: "完整页面路由树，含 MVP/推迟标注"
standalone: true
called_by:
  - workflow/project-bootstrap (Phase 3)
---

# Plan Page Map Skill

> **单独调用**：`/plan-page-map`（适用于现有项目新增功能模块时规划页面结构）
> **在工作流中调用**：由 `project-bootstrap` Phase 3 自动触发

---

## 执行步骤

### Step 1：分析功能模块
从需求描述中提取独立功能模块，每个模块对应一组页面。

### Step 2：规划路由层级
按以下维度分组：
- 公开页（无需登录）
- 功能页（登录后可见）
- 管理页（特定角色可见）
- 设置页

### Step 3：标注 MVP 与推迟范围
明确哪些页面是当前迭代必须交付的，哪些推迟到后续版本。

---

## 输出格式

```markdown
## 页面地图 v1.0

### 公开页（无需登录）
- `/` — 首页
- `/login` — 登录
- `/register` — 注册（如需）

### 功能页（需登录）
- `/dashboard` — 概览
- `/{{模块A}}` — {{功能描述}}
  - `/{{模块A}}/{{子页}}` — {{功能描述}} [MVP]
  - `/{{模块A}}/{{子页2}}` — {{功能描述}} [推迟 v2]

### 设置页
- `/settings/profile` — 个人信息

### 管理页（仅 admin）
- `/admin/{{...}}` — {{功能描述}}

### 不在 MVP 内（推迟原因）
- `/{{页面}}` — {{原因：功能复杂/优先级低/依赖未就绪}}
```

---

## 约束

- **MUST** 每个页面标注 [MVP] 或 [推迟 vN]，不允许模糊
- **NEVER** 规划超出当前需求范围的页面（不做需求扩展）
- 页面路由风格与技术栈一致（Next.js 用文件路由约定，Vue Router 用配置路由）
