---
description: 0-1 新项目初始化工作流。在写第一行业务代码前，强制完成技术栈确认、页面地图规划、组件层级设计、全局约定锁定，输出经人工确认的《架构蓝图》后才允许进入开发。
---

# Project Bootstrap 新项目初始化工作流

> **适用场景**：全新项目（空仓库或刚初始化的脚手架），或重大重构前需要重新规划架构时。
> **与 requirement-clarification 的区别**：需求澄清针对单个功能，本工作流针对整个项目的结构设计决策。
> **触发指令**：`/project-bootstrap [项目简述]`

---

## 阶段一：信息收集 (Discovery)

AI 提问，收集必要信息（一次性提问，不超过 8 个问题）：

```
## 项目初始化问卷

**基础信息**
Q1. 这个产品解决什么问题？目标用户是谁？（1-3 句话）
Q2. 预计的核心功能模块有哪些？（粗粒度列举，不用完整）

**用户与规模**
Q3. 初期预计日活/并发量级？（影响架构选型）
Q4. 是否需要多租户/多角色权限体系？有哪些角色？

**技术偏好**
Q5. 前端框架偏好？（React / Vue / 其他）
Q6. 后端语言偏好？（Python / Node.js / Go / 其他）
Q7. 是否有指定的 UI 组件库？（Ant Design / shadcn/ui / 自建 / 无要求）

**交付约束**
Q8. MVP 需要在什么时间节点可用？（影响功能优先级划分）
```

---

## 阶段二：技术栈确认 (Tech Stack Decision)

根据收集的信息，AI 输出技术栈选型建议：

```markdown
## 技术栈选型建议

### 前端
- 框架：{{框架}} — 理由：{{选择依据}}
- UI 库：{{库名}} — 理由：{{选择依据}}
- CSS 方案：{{方案}} — 理由：{{选择依据}}
- 状态管理：{{方案}} — 理由：{{适用场景}}
- 测试框架：{{框架}}

### 后端
- 语言/框架：{{框架}} — 理由：{{选择依据}}
- 数据库：{{DB}} — 理由：{{选择依据}}
- ORM：{{ORM}}
- 认证方案：{{方案}}

### 工程约定
- 代码仓库结构：monorepo / 分仓
- API 风格：RESTful / GraphQL / tRPC
- 环境管理：.env + docker-compose
- CI/CD：{{方案建议}}

### 不选择 X 的原因
- {{备选方案}} → 不选，因为：{{理由}}（透明说明，避免将来被追问）
```

**人工卡点**：确认技术栈后才进入下一阶段。

---

## 阶段三：页面地图规划 (Page Map)

基于确认的需求，输出完整页面地图：

```markdown
## 页面地图 v1.0

### 公开页（无需登录）
- `/` — 首页/落地页
- `/login` — 登录
- `/register` — 注册（如需）

### 功能页（需登录）
- `/dashboard` — 概览/仪表盘
- `/[模块A]` — {{功能描述}}
  - `/[模块A]/[子页]` — {{功能描述}}
- `/[模块B]` — {{功能描述}}

### 设置页
- `/settings/profile` — 个人信息
- `/settings/[其他]` — {{功能描述}}

### 管理页（仅 admin）
- `/admin/[...]` — {{功能描述}}

### 不在 MVP 内的页面（标注，供后续迭代）
- `/[页面]` — {{原因：推迟到 v2}}
```

---

## 阶段四：组件层级规划 (Component Hierarchy)

规划组件分层，防止后期组件混乱：

```markdown
## 组件层级约定

### 分层规则
- `components/ui/` — 纯展示型原子组件（Button、Input、Badge）。无业务逻辑，无 API 调用
- `components/common/` — 跨业务复用的功能组件（DataTable、EmptyState、ConfirmModal）
- `components/[模块名]/` — 业务专属组件，只在对应模块内使用
- `pages/` / `app/` — 页面级组件，负责数据获取和布局编排

### 禁止事项
- **NEVER** 在 ui/ 原子组件中调用 API 或访问全局 store
- **NEVER** 在 pages/ 中写复杂 UI 逻辑（超过 50 行的 JSX 抽为组件）
- **NEVER** 跨模块直接 import 业务组件（应提升到 common/）

### 状态管理边界
- 服务端数据：{{方案，如 React Query / SWR / Zustand}}
- 全局 UI 状态：{{方案，如 Zustand / Context}}
- 表单状态：{{方案，如 React Hook Form}}
- **NEVER** 将服务端数据与 UI 状态混入同一个 store

### 初始必建组件清单
以下组件在开发第一个功能前必须建好，避免后期重复造轮子：
- [ ] `Layout` — 全局布局（Sidebar + Header + Content）
- [ ] `EmptyState` — 空数据占位
- [ ] `LoadingSpinner` / `Skeleton` — 加载态
- [ ] `ErrorBoundary` — 错误边界
- [ ] `ConfirmModal` — 危险操作确认弹窗
- [ ] `DataTable` — 列表表格（含分页、排序、筛选插槽）
- [ ] `PageHeader` — 页面标题区
```

---

## 阶段五：全局约定锁定 (Global Conventions)

```markdown
## 全局开发约定

### 文件命名
- 组件文件：PascalCase（`UserCard.tsx`）
- 工具函数：camelCase（`formatDate.ts`）
- 页面文件：PascalCase + Page 后缀（`DashboardPage.tsx`）
- 测试文件：与源文件同名 + `.test.ts` / `.spec.ts`
- 常量文件：UPPER_SNAKE_CASE（`API_ENDPOINTS.ts`）

### API 约定
- 请求封装：所有 API 调用统一通过 `src/api/` 或 `src/services/` 目录的函数
- 错误格式：`{ code: string, message: string, data?: T }`
- 认证方式：{{JWT Bearer / Cookie Session / 其他}}
- 路径前缀：`/api/v1/`

### 代码约定
- 组件 props 必须有 TypeScript 类型定义
- 禁止 `any` 类型（需要时用 `unknown` + 类型守卫）
- 异步函数统一用 `async/await`，禁止混用 `.then()` 链
- 颜色：{{如果 Tailwind → 只用语义 token；否则 → CSS 变量}}

### Git 约定
- 分支命名：`feature/xxx`、`fix/xxx`、`hotfix/xxx`
- commit 格式：参照 `commit-with-affects` SKILL
- 禁止直接 push main，必须 PR + review
```

---

## 阶段六：项目围栏生成 (Project Guardrails)

基于上述决策，自动生成项目专属 `.slimignore` 和补充护栏：

```markdown
## 项目专属护栏

### 不可删除的关键路径（写入 .slimignore）
- `src/components/ui/` — 基础组件库，IDE 静态分析可能误报未引用
- `src/api/` — API 封装层，动态调用不易被静态分析发现
- `{{其他项目特定路径}}`

### 额外禁止事项（追加到 guardrails.md）
- NEVER 在组件中直接使用 `fetch()`，必须通过 `src/api/` 封装
- NEVER 在前端硬编码后端域名，统一用 `import.meta.env.VITE_API_URL`
- {{其他基于技术栈决策生成的项目特定规则}}
```

---

## 阶段七：人工确认与归档 (Sign-off & Archive)

输出完整《架构蓝图》摘要：

```markdown
## 架构蓝图确认书 v1.0

项目：{{名称}}
日期：{{today}}

✅ 技术栈：{{前端框架}} + {{后端框架}} + {{数据库}}
✅ 页面数量：{{N}} 个（MVP），{{M}} 个推迟
✅ 组件分层：ui / common / 模块专属 / pages
✅ 全局约定：已锁定命名、API、状态管理边界
✅ 项目围栏：.slimignore 已生成，额外护栏已追加

**确认后将执行**：
1. 创建 `project.config.json`（基于本次决策）
2. 初始化必建组件清单（空壳，无业务逻辑）
3. 创建页面路由骨架（空页面）
4. 写入项目专属 guardrails 追加内容
5. 进入 `/auto-dev` 开始第一个功能开发
```

**强制挂起**，等待用户回复"确认"后执行上述动作。

---

## 约束

- **NEVER** 在《架构蓝图》确认前创建任何业务代码文件
- **NEVER** 在技术栈未确认时就开始规划组件（顺序不可颠倒）
- **MUST** 组件层级约定必须写入项目的 `README.md` 或 `docs/` 供团队共用
- **MUST** 初始必建组件在第一个功能开发前全部完成（哪怕是空壳），避免后期补做造成不一致
