---
maintained_by: human + AI（AI 只能提议，人工确认后追加）
read_by: auto-dev Phase 0, dev-flow Step 2（必读）
---

# 项目开发约定 (Living Conventions)

> 本文件是项目全程维护的「活的约定文档」。
> bootstrap 时生成初稿，开发过程中随时追加。
>
> **AI 读取规则**：
> - Phase 0 / Step 2 **只读 `## 核心约定速查` 区块**（止于分隔线），不读完整内容
> - 完整内容仅在 Verify 阶段发现潜在违规时按需读取对应章节
> - 发现约定缺失时，以 `[CONVENTION_PROPOSAL]` 格式提议，**不得自行追加**

---

## 核心约定速查

> **此区块为 Phase 0 唯一必读区**，严格控制在 10 行以内。
> 只列最高频被违反、最容易被忽略的约定。其余约定见下方各章节。

<!-- 示例（bootstrap 后替换为项目实际内容）：
- [前端] 弹窗统一用 Modal 组件，禁止原生 dialog / window.confirm
- [前端] 颜色只用语义 token，禁止裸 hex / tailwind 物理色
- [API] 错误格式统一 { code, message, data? }，禁止散写
- [通用] 禁止硬编码 env URL，前端用 VITE_*，后端用 os.environ
-->

---

## 文件命名

<!-- bootstrap 时填写，示例如下 -->
- 组件文件：PascalCase（`UserCard.tsx`）
- 工具函数：camelCase（`formatDate.ts`）
- 页面文件：PascalCase + Page 后缀（`DashboardPage.tsx`）
- 测试文件：源文件同名 + `.test.ts` / `.spec.ts`

## API 约定

<!-- bootstrap 时填写 -->
- 所有 API 调用统一通过 `{{FRONTEND_PATH}}/api/` 或 `services/` 目录
- 错误格式：`{ code, message, data? }`
- 路径前缀：`/api/v1/`
- **NEVER** 在组件中直接使用 `fetch()`

## 前端组件约定

<!-- 随开发持续追加 -->
- 弹窗：统一使用项目 Modal 组件，禁止原生 `<dialog>` 或 `window.confirm()`
- 空状态：统一使用 `EmptyState` 组件，禁止散写 `<div>暂无记录</div>`
- Toast：统一使用项目 Toast 库，禁止 `alert()`

## 后端约定

<!-- 随开发持续追加 -->

## 环境变量

- **NEVER** 硬编码地址或密钥
- 前端：`import.meta.env.VITE_*`
- 后端：`os.environ` / `.env` 文件

## Git 约定

- 分支命名：`feature/xxx`、`fix/xxx`、`hotfix/xxx`
- Commit 格式：参照 `commit-with-affects` skill
- **NEVER** 直接 push main

---

## 增量追加区

> 开发过程中新增的约定记录在此，注明日期和来源。

<!-- 格式：- [YYYY-MM-DD] [模块] 约定内容 — 来源：需求/踩坑/讨论 -->

