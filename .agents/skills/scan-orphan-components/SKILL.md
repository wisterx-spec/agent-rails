---
name: scan-orphan-components
description: 扫描前端目录，找出无任何 import 引用的孤儿组件文件，输出候选删除清单
trigger: /scan-orphan-components
inputs:
  - name: frontend_path
    source: "project.config.json → tech_stack.frontend_path"
    required: true
  - name: slimignore
    source: ".slimignore 文件（如存在）"
    required: false
    description: "豁免路径列表，命中的文件跳过扫描"
outputs:
  - name: orphan_report
    destination: "对话输出（可追加至 tmp/slim_report_YYYYMMDD.md）"
    description: "孤儿组件列表，含文件路径、最后修改时间、删除风险级别"
standalone: true
called_by:
  - workflow/slim (Phase 1)
---

# Scan Orphan Components Skill

> **单独调用**：`/scan-orphan-components`
> **在工作流中调用**：由 `slim` 工作流 Phase 1 自动触发
> **前置要求**：必须先读取 `.slimignore`（如存在），豁免文件不参与扫描

---

## 执行步骤

### Step 1：读取豁免清单
若 `.slimignore` 存在，读取所有豁免路径。若不存在，记录 `[WARN] .slimignore 不存在，建议创建以保护动态引用文件`，继续执行（不中止）。

### Step 2：列出所有组件文件
列出 `{{FRONTEND_PATH}}/components/` 和 `{{FRONTEND_PATH}}/pages/`（及 `views/`）下所有文件，过滤掉命中 `.slimignore` 的路径。

### Step 3：全库引用搜索
对每个候选文件，在整个仓库搜索是否有其他文件 import 它：

```bash
# 搜索方式：文件名（无扩展名）作为 import 目标
grep -rn "from.*ComponentName\|import.*ComponentName" {{FRONTEND_PATH}} --include="*.{{EXT}}"
# 同时搜索动态 import / lazy 加载
grep -rn "import(.*ComponentName\|React.lazy.*ComponentName" {{FRONTEND_PATH}} --include="*.{{EXT}}"
```

**零静态引用**且未豁免 → 列为候选。
**有动态 import 引用**（字符串形式）→ 标注 🟡 中风险，需人工确认。

### Step 4：收集元数据
对每个候选文件执行 `git log --follow -1 --format="%ad %an" -- <file>` 获取最后修改信息。

---

## 输出格式

```
## 孤儿组件扫描结果

扫描路径：{{FRONTEND_PATH}}
豁免文件：N 个（来自 .slimignore）
候选文件：M 个

| 文件 | 最后修改 | 作者 | 风险 | 备注 |
|------|---------|------|------|------|
| src/components/OldWidget.tsx | 2024-01-05 | - | 🟢 低 | 零引用 |
| src/components/LegacyTable.tsx | 2024-03-10 | - | 🟡 中 | 疑似动态加载 |

⚠️ 以上文件未在 .slimignore 中声明，建议人工确认后再决定删除。
```

---

## 约束

- **NEVER** 自动删除任何文件，只输出报告
- **MUST** 同时搜索静态 import 和动态 import（字符串形式的懒加载）
- **MUST** `.slimignore` 命中的文件不出现在候选列表中
