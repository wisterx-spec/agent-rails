---
name: scan-frontend-quality
description: 对项目所有前端页面进行系统性质量扫描，输出可直接转为 issue 的结构化报告。覆盖规范合规、空状态、交互反馈、布局、导航、易用性、响应式、文案共 8 个维度。
---

# Scan Frontend Quality Skill

## 触发时机
- 大版本发版前的全面质量扫描
- 用户提及"全面扫描前端"、"前端质量报告"、"batch 评估所有页面"

---

## 扫描范围
全量扫描 `project.config.json → tech_stack.frontend_path` 下的所有页面组件（`pages/`、`views/` 目录）。

---

## 扫描维度

### 维度 1：规范合规 (Compliance)
- 检测 Tailwind 物理色使用（`bg-blue-`, `text-red-` 等）
- 检测裸 hex / rgb 颜色值
- 检测浏览器原生弹窗（`alert`, `confirm`, `prompt`）
- 检测文字 Emoji 充当图标

### 维度 2：空状态 (Empty States)
- 检测列表组件是否有条件性的空态渲染
- 检测是否使用了统一 EmptyState 组件
- 检测搜索/过滤无结果的处理

### 维度 3：交互反馈 (Interaction Feedback)
- 检测异步操作（API 调用）是否有 Loading 态
- 检测 CRUD 操作后是否有 Toast 反馈
- 检测危险操作是否有二次确认

### 维度 4：错误处理 (Error Handling)
- 检测 API 调用是否有 catch 错误处理
- 检测是否有全局错误边界

### 维度 5：布局与溢出 (Layout)
- 检测长文本截断处理
- 检测弹窗/抽屉是否有滚动保护

### 维度 6：文案规范 (Copy)
- 检测中英文混用、标点不规范（如中文后用英文逗号）
- 检测按钮/操作文案是否清晰（避免"确定"/"取消"模糊匹配）

### 维度 7：导航一致性 (Navigation)
- 检测面包屑/返回按钮的一致性
- 检测页面标题的一致性

### 维度 8：可访问性基础 (Accessibility)
- 检测 `<img>` 是否有 alt 属性
- 检测表单字段是否有关联 label

---

## 执行方式

采用静态分析 + 代码搜索的方式扫描，不依赖运行时。

**文件扩展名**从 `project.config.json → tech_stack.frontend_extensions` 读取，默认值为 `["tsx", "vue", "jsx"]`。以下命令中的 `{{EXT}}` 由配置注入，不硬编码。

```bash
# 示例：检测 Tailwind 物理色（{{EXT}} 由配置注入，如 tsx / vue）
grep -rn "bg-blue-\|bg-red-\|bg-green-\|bg-gray-\|text-blue-" {{FRONTEND_PATH}} --include="*.{{EXT}}"

# 示例：检测裸 hex（同时扫描样式文件）
grep -rn "#[0-9a-fA-F]\{3,6\}" {{FRONTEND_PATH}} --include="*.{{EXT}}" --include="*.css" --include="*.scss"

# 示例：检测 alert
grep -rn "window\.confirm\|window\.alert\|^\s*alert(" {{FRONTEND_PATH}} --include="*.{{EXT}}"

# 示例：检测 img 缺少 alt（Vue 和 React 均适用）
grep -rn "<img[^>]*>" {{FRONTEND_PATH}} --include="*.{{EXT}}" | grep -v "alt="
```

> 若 `tech_stack.frontend_extensions` 未配置，记录 `[CONFIG MISSING: frontend_extensions]` 并使用默认值 `tsx`。

---

## 输出格式

```
## 前端质量扫描报告

**扫描范围**：{{N}} 个页面文件
**扫描时间**：{{YYYY-MM-DD}}

### 问题汇总

| 维度 | 🔴 高优 | 🟡 中优 | 🟢 低优 |
|------|--------|--------|--------|
| 规范合规 | 3 | 7 | 2 |
| 空状态处理 | 1 | 4 | 0 |
| ...合计 | X | Y | Z |

### 详细问题清单（可直接转 issue）

#### 🔴 高优先级（建议本次修复）

**[COMP-001]** `pages/UserListPage.tsx:45`
- 问题：使用了 `window.confirm()` 执行删除确认
- 建议：替换为 `DeleteConfirmModal` 组件

#### 🟡 中优先级（下次迭代处理）

**[COMP-002]** `pages/Dashboard.tsx:120`
- 问题：列表为空时使用 `<div>暂无数据</div>`
- 建议：替换为 `<EmptyState message="暂无数据" />`

### 规范符合度评分

| 维度 | 通过率 |
|------|--------|
| 规范合规 | 78% |
| 空状态处理 | 85% |
| ...整体 | XX% |
```

---

## 约束

- **NEVER** 自动修改任何源文件，只输出报告
- 输出的问题编号格式为 `[COMP-XXX]`，方便追踪
- 报告写入 `tmp/frontend_quality_scan_{YYYYMMDD}.md`
