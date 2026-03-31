---
name: scan-unused-exports
description: 扫描工具/类型/常量目录中有导出但从未被 import 的函数、类型、常量，输出候选清单
trigger: /scan-unused-exports
inputs:
  - name: scan_dirs
    source: "project.config.json → tech_stack.frontend_path 下的 utils/helpers/constants/types 目录"
    required: true
  - name: slimignore
    source: ".slimignore 文件（如存在）"
    required: false
outputs:
  - name: unused_exports_report
    destination: "对话输出（可追加至 tmp/slim_report_YYYYMMDD.md）"
    description: "未引用导出列表，含文件路径、导出名、删除风险"
standalone: true
called_by:
  - workflow/slim (Phase 3)
---

# Scan Unused Exports Skill

> **单独调用**：`/scan-unused-exports`
> **在工作流中调用**：由 `slim` 工作流 Phase 3 自动触发
> **可跳过条件**：项目已集成 ESLint `no-unused-vars` + `import/no-unused-modules` 规则时，可跳过此 skill，直接用 lint 结果

---

## 执行步骤

### Step 1：确定扫描目录
扫描以下目录（存在哪个扫哪个）：
- `utils/`、`helpers/`、`lib/`
- `constants/`、`config/`
- `types/`、`interfaces/`、`models/`（仅 .ts 类型文件）

过滤 `.slimignore` 豁免路径。

### Step 2：提取所有 export 声明
```bash
grep -rn "^export\|^export default\| export " {{SCAN_DIRS}} --include="*.{{EXT}}"
```
提取每个 `export` 的名称（函数名、类名、类型名、常量名）。

### Step 3：全库搜索 import 引用
对每个导出名，在整个仓库搜索：
```bash
grep -rn "import.*{.*ExportName.*}" {{PROJECT_ROOT}} --include="*.{{EXT}}"
```
零引用 → 候选。有引用 → 跳过。

> ⚠️ 注意：以下情况不能标为"未引用"：
> - `export default`（被 `import Xxx from` 动态路径导入时难以静态追踪）
> - 被字符串形式动态 require/import 的导出
> - `.d.ts` 类型声明文件（可能被 IDE 工具链使用）

### Step 4：风险分级
- 🟢 低：工具函数，名称唯一，确认无引用
- 🟡 中：类型/interface，可能被运行时反射或泛型引用
- 🔴 高：不建议删除（export default / 类型声明文件）

---

## 输出格式

```
## 未引用导出扫描结果

| 文件 | 导出名 | 类型 | 风险 |
|------|--------|------|------|
| src/utils/legacyFormat.ts | formatOldDate | function | 🟢 低 |
| src/types/deprecated.ts | OldUserType | type | 🟡 中 |

无问题时输出：✅ 未发现明显未引用的导出
```

---

## 约束

- **NEVER** 删除任何导出，只输出报告
- **NEVER** 将 `export default` 标为未引用（静态分析不可靠）
- **MUST** 将 🔴 高风险项排除在删除建议之外
