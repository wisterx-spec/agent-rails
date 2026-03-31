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
    destination: "对话输出（建议写入 docs/architecture/conventions.md 或 README.md）"
    description: "文件命名/API/代码/Git 全局约定文档"
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

### Step 1：生成约定文档

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
