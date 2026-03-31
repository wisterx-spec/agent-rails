---
description: 项目瘦身工作流。安全扫描孤儿组件、未引用导出、死路由，生成可审查的删除提案后由人工确认执行，避免误删动态引用。
---

# Slim 项目瘦身工作流

> **触发指令**：`/slim [--scope=frontend|backend|all]`
> **核心原则**：AI 只生成《删除提案》，不自动执行任何删除。所有删除操作必须经人工确认。
> **前置要求**：执行前必须读取 `.slimignore`，其中列出的路径和模式绝对豁免扫描。

---

## 前置：读取豁免清单

```bash
# 必须先读取 .slimignore，其中的路径不参与任何删除扫描
cat .slimignore
```

若 `.slimignore` 不存在，**立即停止**，提示用户先创建：

```
.slimignore 不存在。动态引用、运行时加载的文件若被误删将导致生产事故。
请先创建 .slimignore 并声明豁免路径，再执行 /slim。
参考模板：.slimignore.example
```

---

## 阶段一：孤儿组件扫描 (Orphan Components)

> 扫描有文件但没有任何其他文件 import 它的组件。

**执行步骤**：

1. 列出 `{{FRONTEND_PATH}}/components/` 下所有组件文件
2. 对每个文件，在全仓库搜索 `import.*文件名`（不含该文件自身）
3. 零引用 → 列为候选删除项

**输出格式**：

```
## 孤儿组件（无任何 import 引用）

| 文件 | 最后修改时间 | 原始创建者（git log） | 删除风险 |
|------|------------|---------------------|--------|
| src/components/OldWidget.tsx | 2024-01-05 | - | 🟢 低（无引用） |
| src/components/LegacyTable.tsx | 2024-03-10 | - | 🟡 中（检查动态加载） |

⚠️ 注意：以下文件虽无静态 import，但因在 .slimignore 中声明，跳过扫描：
- src/components/DynamicLoader.tsx（运行时按需加载）
```

---

## 阶段二：死路由扫描 (Dead Routes)

> 扫描路由配置中存在但对应页面文件已不存在，或页面存在但路由配置中没有的文件。

**执行步骤**：

1. 读取路由配置文件（`router.tsx` / `routes.ts` / `app/` 目录等，根据项目结构判断）
2. 提取所有路由路径和对应组件
3. 检查每个组件文件是否存在
4. 检查 `pages/` 目录下是否有未被路由引用的页面文件

**输出格式**：

```
## 路由不一致项

### 路由有注册，但文件不存在（幽灵路由）
- `/old-feature` → `OldFeaturePage`（文件已删除）→ 建议从路由配置中移除

### 页面文件存在，但未注册路由（孤儿页面）
- `src/pages/ExperimentPage.tsx` → 未在任何路由中注册 → 确认是否废弃
```

---

## 阶段三：未引用导出扫描 (Unused Exports)

> 扫描有导出但从未被 import 的函数/类型/常量。

**执行步骤**：

1. 扫描 `utils/`、`helpers/`、`constants/`、`types/` 等工具目录
2. 对每个 `export` 声明，全库搜索是否有对应的 `import { xxx }`
3. 零引用且不在 `.slimignore` 中 → 列为候选项

**输出格式**：

```
## 未引用导出

| 文件 | 导出名 | 删除风险 |
|------|--------|--------|
| src/utils/legacyFormat.ts | `formatOldDate` | 🟢 低 |
| src/types/deprecated.ts | `OldUserType` | 🟡 中（确认无运行时反射） |
```

---

## 阶段四：大文件 / 重复依赖扫描 (Bundle Bloat)

> 检测可能影响包体积的问题。

**扫描项**：

1. `node_modules` 中是否有重复安装的相同包（不同版本）
2. 是否有只用到少量功能却引入整个库的情况（如 `import _ from 'lodash'`）
3. 是否有可替换为原生 API 的 polyfill 依赖（如 `moment` → `dayjs` / `date-fns`）

**输出格式**：

```
## 依赖优化建议

| 当前依赖 | 问题 | 建议 | 体积节省估算 |
|---------|------|------|------------|
| moment@2.29 | 仅用 format() | 替换为 dayjs（按需引入） | ~70KB gzip |
| lodash@4.17 | 仅用 _.get | 改为原生 `?.` 可选链 | ~25KB gzip |
```

---

## 阶段五：生成《删除提案》(Deletion Proposal)

汇总以上所有扫描结果，生成结构化提案：

```markdown
# 项目瘦身提案 v{{date}}

## 执行前提醒
- 本提案基于静态分析，动态引用（懒加载、字符串拼接路径、反射）可能被误判
- .slimignore 中的豁免项已排除
- 建议在独立分支执行，并在删除后运行完整测试套件

## P0 — 确认可删除（零引用，非豁免）
- [ ] `src/components/OldWidget.tsx`
- [ ] `/old-feature` 路由配置

## P1 — 需人工判断（可能有动态引用）
- [ ] `src/components/LegacyTable.tsx`（检查是否有字符串动态加载）
- [ ] `src/types/deprecated.ts`（确认无运行时类型检查）

## P2 — 依赖优化（不删文件，替换依赖）
- [ ] moment → dayjs
- [ ] lodash 全量引入 → 按需引入

## 不处理项（人工标注原因）
- `src/components/DynamicLoader.tsx` — .slimignore 豁免（运行时按需加载）
```

**强制挂起**，等待人工回复后才执行任何删除操作。

---

## 阶段六：执行删除（仅在人工确认后）

人工回复"执行 P0"或"执行全部"后：

1. 创建专用分支：`git checkout -b slim/{{date}}`
2. 逐文件删除（不批量 rm），每删一个文件记录一条日志
3. 删除完成后立即运行测试：`/run-tests --mode=full`
4. 测试全通过 → 提交，使用 `commit-with-affects` 生成 commit message
5. 测试有失败 → **立即回滚该文件**，加入《误删记录》，更新 `.slimignore`

```
## 误删记录（自动追加到 .slimignore）
# 曾被 /slim 误判为孤儿，实际有动态引用
src/components/{{误删文件}}  # 误删于 {{date}}，原因：{{动态加载路径}}
```

---

## 约束

- **NEVER** 在未读 `.slimignore` 的情况下开始扫描
- **NEVER** 仅凭 IDE 静态分析结果直接删除文件，必须全库搜索确认
- **NEVER** 批量 `rm -rf`，只允许逐文件有记录地删除
- **MUST** 删除后立即跑全量测试，有失败必须回滚对应文件
- **MUST** 误删的文件必须加入 `.slimignore` 防止下次再误判
