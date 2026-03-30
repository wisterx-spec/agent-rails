# 前端 UI 开发规范 (Frontend UI Rules)

编写或修改前端 `{{FRONTEND_PATH}}` 中的 TSX 或 CSS 样式代码时，严禁散写硬编码类名。

> 适配提示：将 `{{FRONTEND_PATH}}` 替换为 `project.config.json` 中的 `tech_stack.frontend_path`。
> 将 `{{DESIGN_SYSTEM_FILE}}` 替换为 `design_system.reference_file`。
> 将 `{{SEMANTIC_COLOR_PREFIX}}` 替换为 `design_system.semantic_color_prefix`。

---

### 1. UI 组件唯一真理集 (Single Source of Truth)
- **MUST** 任何 UI 组件或色盘涉及结构变动前，**绝对禁止盲写**。
- **MUST** 必须先检索项目的设计系统参考文件（`{{DESIGN_SYSTEM_FILE}}`）中的约束字典，或全局搜索存量 UI 模块复用其 `className` 组合。
- **MUST** 禁止使用 Tailwind 物理原子色（如 `bg-blue-500`, `bg-slate-300` 等），只允许使用项目语义变量（如 `{{SEMANTIC_COLOR_PREFIX}}primary`）。
- **MUST** 新增 CSS token 必须同步写入 `tailwind.config.js`（含暗色值）。

### 2. 用户交互与弹窗挂载 (Interactions & Modals)
- **MUST** 严禁调用浏览器破坏行为接口（如 `alert()` 或 `window.confirm()`）。业务确认弹窗必须使用项目内置的确认弹窗组件。
- **MUST** 轻量事件提示必须引用项目统一的 Toast 库（如 `react-hot-toast`），不允许散写。
- **MUST** 严禁以文本 Emoji 充当矢量图标，必须导入项目统一的图标库（如 `lucide-react`）。
- **MUST** 前端列表渲染空窗期禁止用散写 `<div>暂无记录</div>`，必须使用项目统一的空状态组件（`EmptyState` 或同等组件）。

### 3. 状态管理约束
- **MUST** 修改全局状态（如 Zustand store）之前，必须全局搜索该 store 的所有引用点，确认解构路径无隐式断裂。
- **MUST** 删除 store 中的字段前，必须用全局搜索确认无任何组件依赖此字段。

### 4. 禁止事项速查
- 禁止裸 hex / rgb 颜色值（如 `color: #3b82f6`）
- 禁止在组件内直接 `fetch`，必须走统一的 API 请求层
- 禁止在非 `useEffect` 内发起副作用
- 禁止直接操作 DOM（除非封装在自定义 Hook 内）
