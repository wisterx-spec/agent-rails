---
name: scan-bundle-bloat
description: 扫描依赖中的重复包、重型依赖的轻量替代方案、可用原生 API 替代的 polyfill，输出体积优化建议
trigger: /scan-bundle-bloat
inputs:
  - name: package_file
    source: "项目根目录 package.json / requirements.txt"
    required: true
outputs:
  - name: bloat_report
    destination: "对话输出（可追加至 tmp/slim_report_YYYYMMDD.md）"
    description: "依赖优化建议表，含估算体积节省"
standalone: true
called_by:
  - workflow/slim (Phase 4)
---

# Scan Bundle Bloat Skill

> **单独调用**：`/scan-bundle-bloat`
> **在工作流中调用**：由 `slim` 工作流 Phase 4 自动触发

---

## 执行步骤

### Step 1：读取依赖清单
读取 `package.json`（前端）或 `requirements.txt` / `pyproject.toml`（后端）。

### Step 2：检测重型依赖的局部使用
对以下已知重型库，搜索实际使用的函数数量：

**前端**：
```bash
# 检测 lodash 使用情况
grep -rn "from 'lodash'\|require('lodash')" {{FRONTEND_PATH}} --include="*.{{EXT}}"
grep -rn "from 'lodash/\|_.'" {{FRONTEND_PATH}} --include="*.{{EXT}}"

# 检测 moment 使用情况（建议替换为 dayjs / date-fns）
grep -rn "from 'moment'" {{FRONTEND_PATH}} --include="*.{{EXT}}"
```

**后判断规则**：
- lodash 仅用 1-3 个函数 → 建议按需引入或使用原生
- moment → 建议替换为 dayjs（API 兼容）或 date-fns（tree-shaking 友好）
- 整个库仅用了一个方法 → 标记

### Step 3：检测可替换为原生 API 的依赖
常见可替换场景：
| 依赖 | 可替换为 | 条件 |
|------|---------|------|
| `lodash.get` | `?.` 可选链 | TypeScript / ES2020+ |
| `lodash.cloneDeep` | `structuredClone()` | Node 17+ / 现代浏览器 |
| `moment` | `Intl.DateTimeFormat` | 简单格式化场景 |
| `axios` | `fetch` | 若项目已有封装层 |
| `uuid` | `crypto.randomUUID()` | Node 14.17+ / 现代浏览器 |

### Step 4：检测重复安装的包（不同版本）
```bash
npm ls --depth=0 2>/dev/null | grep "deduped\|invalid"
# 或
cat package-lock.json | grep '"version"' | sort | uniq -d
```

---

## 输出格式

```
## 依赖体积优化建议

| 当前依赖 | 问题 | 建议替换 | 估算体积节省 |
|---------|------|---------|------------|
| moment@2.29 | 仅用 format() | dayjs（API 兼容，按需引入） | ~65KB gzip |
| lodash@4.17 | 仅用 _.get | 可选链 `?.` | ~25KB gzip |

无问题时输出：✅ 未发现明显可优化的重型依赖
```

---

## 约束

- **NEVER** 自动修改 package.json 或替换依赖
- 估算体积节省基于公开数据（bundlephobia 数据），标注"估算"不作保证
- **MUST** 在建议替换时，注明替换的兼容性前提（如浏览器版本、Node 版本）
