---
name: scan-code-hygiene
description: 扫描代码库中的卫生问题：console.log 调试语句、TODO/FIXME、硬编码地址/密钥、中文注释中的敏感词
trigger: /scan-code-hygiene [--scope=staged|all]
inputs:
  - name: scope
    source: "用户参数 --scope，默认 staged（仅扫描 git diff 变更文件）"
    required: false
  - name: frontend_path
    source: "project.config.json → tech_stack.frontend_path"
    required: false
  - name: backend_path
    source: "project.config.json → tech_stack.backend_path"
    required: false
outputs:
  - name: hygiene_report
    destination: "对话输出"
    description: "按严重性分级的卫生问题清单，含文件路径和行号"
standalone: true
called_by:
  - workflow/production-release (Step 2)
  - workflow/pr-review (Step 2，由 pr-self-review 内部调用)
---

# Scan Code Hygiene Skill

> **单独调用**：`/scan-code-hygiene`（发版前自查）或 `/scan-code-hygiene --scope=all`（全量扫描）
> **在工作流中调用**：由 `production-release` Step 2 自动触发
> **默认 scope**：`staged`（只扫本次变更），发版前建议用 `all`

---

## 执行步骤

### Step 1：确定扫描范围
- `--scope=staged`：`git diff HEAD --name-only` 获取变更文件列表
- `--scope=all`：扫描 `{{FRONTEND_PATH}}` 和 `{{BACKEND_PATH}}` 下所有源文件

### Step 2：执行扫描检测

**调试语句（🔴 发版前必须清除）**：
```bash
# 前端
grep -rn "console\.log(" 变更文件 --include="*.{{EXT}}"
# 后端
grep -rn "print(" 变更文件 --include="*.py"
grep -rn "pprint\|pp\(" 变更文件 --include="*.py"
```

**未完成标记（🟡 建议处理）**：
```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|TEMP\|临时\|TODO:" 变更文件
```

**硬编码环境地址（🔴 必须修复）**：
```bash
grep -rn "localhost:\|127\.0\.0\.1:\|http://.*\.com\|https://.*\.com" 变更文件
# 排除测试文件和注释
```

**潜在密钥（🔴 必须修复）**：
```bash
grep -rn "password\s*=\s*['\"].\|api_key\s*=\s*['\"].\|secret\s*=\s*['\"]." 变更文件
```

### Step 3：输出报告

---

## 输出格式

```
## 代码卫生扫描报告

扫描范围：staged / all
扫描文件数：N

### 🔴 必须修复（发版阻断）
- `frontend/src/api/client.ts:23` — console.log("response:", data)
- `backend/app/config.py:5` — password = "hardcoded_pass"

### 🟡 建议处理
- `backend/app/service.py:45` — TODO: 优化批量查询性能

### ✅ 未发现问题
- 硬编码地址：无
- 潜在密钥：无

---
结论：发现 🔴 2 项（需修复后再发版）/ ✅ 全部通过
```

---

## 约束

- **NEVER** 自动修改任何文件，只输出报告
- **MUST** 对 `console.warn` / `console.error` 不报告（这些可以保留）
- 硬编码地址扫描需排除测试文件（`*.test.ts`、`conftest.py`）和注释中的示例
- 若发现 🔴 项，在 `production-release` 流程中这是强制阻断条件
