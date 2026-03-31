---
name: lock-global-conventions
description: 根据技术栈和组件规划，生成并锁定项目全局开发约定（文件命名/API 风格/代码约定/Git 约定），同时生成 .slimignore 初始内容
trigger: /lock-global-conventions
inputs:
  - name: tech_stack
    source: "project.config.json → tech_stack / advise-tech-stack 输出"
    required: true
  - name: component_hierarchy
    source: "plan-component-hierarchy 输出（可选）"
    required: false
outputs:
  - name: conventions_doc
    destination: "docs/conventions.md（固定路径，bootstrap 时创建，后续持续追加）"
    description: "文件命名/API/代码/Git 全局约定文档，项目全程维护"
  - name: slimignore_content
    destination: ".slimignore 初始内容（供用户确认后写入）"
    description: "基于组件层级规划生成的初始豁免清单"
standalone: true
called_by:
  - workflow/project-bootstrap (Phase 5 + 6)
---

# Lock Global Conventions Skill

> **单独调用**：`/lock-global-conventions`（适用于现有项目补充全局约定文档，或多人协作前统一规范）
> **在工作流中调用**：由 `project-bootstrap` Phase 5-6 合并触发

---

## 执行步骤

### Step 1：生成或追加约定文档

**首次运行（bootstrap）**：按模板生成 `docs/conventions.md` 初稿，写入各分类初始约定。

**增量追加（mid-project）**：在 `docs/conventions.md` 的「增量追加区」末尾添加新约定，格式：
```
- [YYYY-MM-DD] [模块] 约定内容 — 来源：需求/踩坑/讨论
```
**NEVER** 修改已有约定（只能追加），若需覆盖旧约定，在旧条目后注明 `→ 已被 [日期] 条目取代`。

### Step 1-A：生成约定文档内容

```markdown
## 全局开发约定

### 文件命名
- 组件文件：PascalCase（`UserCard.tsx`）
- 工具函数：camelCase（`formatDate.ts`）
- 页面文件：PascalCase + Page 后缀（`DashboardPage.tsx`）
- 测试文件：源文件同名 + `.test.ts` / `.spec.ts`
- 常量文件：UPPER_SNAKE_CASE

### API 约定
- 所有 API 调用统一通过 `src/api/` 或 `src/services/` 目录
- 错误格式：`{ code: string, message: string, data?: T }`
- 认证方式：{{JWT Bearer / Cookie Session}}
- 路径前缀：`/api/v1/`
- **NEVER** 在组件中直接使用 `fetch()`

### 代码约定
- 组件 props 必须有 TypeScript 类型定义
- 禁止 `any` 类型（需要时用 `unknown` + 类型守卫）
- 异步函数统一 `async/await`，禁止混用 `.then()` 链
- 颜色：{{Tailwind → 只用语义 token；其他 → CSS 变量}}

### 环境变量约定
- **NEVER** 硬编码环境地址，统一用 `import.meta.env.VITE_API_URL`（前端）或 `os.environ`（后端）

### Git 约定
- 分支命名：`feature/xxx`、`fix/xxx`、`hotfix/xxx`
- Commit 格式：参照 `commit-with-affects` skill
- 禁止直接 push main，必须 PR + review
```

### Step 2：生成 .slimignore 初始内容

基于组件层级规划，自动声明动态加载路径为豁免：

```
# 自动生成的初始豁免清单（基于 project-bootstrap 规划）
# 请根据项目实际情况补充

# 动态路由目录（框架自动扫描）
{{frontend_path}}/pages/dynamic/

# 插件/扩展点（运行时注册）
# {{frontend_path}}/plugins/

# 测试 fixture（测试框架自动加载）
# {{frontend_path}}/__fixtures__/
```

---

## 约束

- **MUST** 约定文档必须写入项目可见位置（README.md 或 docs/），不只存在于对话中
- **NEVER** 在约定中加入模糊条款（如"尽量保持一致"），每条约定必须可执行
- 约定确认后即为项目红线，后续开发均须遵守
