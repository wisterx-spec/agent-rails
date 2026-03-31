---
name: scan-dead-routes
description: 扫描路由配置与页面文件的一致性，找出幽灵路由（配置有文件不存在）和孤儿页面（文件存在配置无注册）
trigger: /scan-dead-routes
inputs:
  - name: frontend_path
    source: "project.config.json → tech_stack.frontend_path"
    required: true
  - name: router_file_hint
    source: "用户参数（可选）"
    required: false
    description: "路由配置文件路径，未指定时自动探测"
outputs:
  - name: dead_routes_report
    destination: "对话输出（可追加至 tmp/slim_report_YYYYMMDD.md）"
    description: "幽灵路由列表 + 孤儿页面列表"
standalone: true
called_by:
  - workflow/slim (Phase 2)
---

# Scan Dead Routes Skill

> **单独调用**：`/scan-dead-routes`
> **在工作流中调用**：由 `slim` 工作流 Phase 2 自动触发

---

## 执行步骤

### Step 1：探测路由配置文件
按优先级自动探测：
1. `{{FRONTEND_PATH}}/router.tsx` / `router.ts`
2. `{{FRONTEND_PATH}}/routes.tsx` / `routes.ts`
3. `{{FRONTEND_PATH}}/App.tsx`（React Router inline 定义）
4. `app/` 目录（Next.js / Remix 文件路由）
5. `src/router/index.ts`（Vue Router）

若用户提供 `router_file_hint` 参数则直接使用。

### Step 2：提取路由 → 组件映射
从路由配置中提取所有 `component: XxxPage` 或 `import('./pages/XxxPage')` 引用，建立 `路由路径 → 组件文件` 映射表。

### Step 3：检查幽灵路由（路由有，文件不存在）
对每个路由的组件引用，检查对应文件是否存在。

### Step 4：检查孤儿页面（文件有，路由无注册）
列出 `pages/`（`views/`）目录下所有文件，检查是否被任何路由引用。排除：
- `_layout.tsx`、`_app.tsx` 等框架约定文件
- `.slimignore` 中豁免的路径
- `index.tsx`（通常是目录入口）

---

## 输出格式

```
## 死路由扫描结果

### 幽灵路由（路由配置存在，但组件文件不存在）
| 路由路径 | 引用的组件 | 建议操作 |
|---------|---------|---------|
| /old-feature | OldFeaturePage | 从路由配置中移除 |

### 孤儿页面（页面文件存在，但未注册到路由）
| 文件路径 | 最后修改 | 建议操作 |
|---------|---------|---------|
| src/pages/ExperimentPage.tsx | 2024-02-10 | 确认是否废弃 |

无问题时输出：✅ 路由配置与页面文件一致，无死路由
```

---

## 约束

- **NEVER** 自动修改路由配置或删除页面文件
- **MUST** 排除框架约定文件（_layout, _app 等）
- 对于文件路由（Next.js/Nuxt）项目，路由由目录结构决定，无需对比配置文件——跳过 Step 2，仅执行 Step 4 的孤儿页面检测
