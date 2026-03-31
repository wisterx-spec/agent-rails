---
description: 上线发布标准流程（上线前检查 + 部署）。适配不同部署平台，通过 project.config.json 注入平台特异操作。
---

# 上线发布标准流程

用户触发 `/production-release` 时，按以下步骤执行。每步完成后报告结果，遇到 🔴 Blocker 必须暂停并告知用户修复后再继续。

> 平台特异配置项（部署平台名称、环境名、容器名等）见 `project.config.json` 中的 `deploy` 字段。

---

## 第一步：代码状态检查

```bash
git status
git log --oneline origin/main..HEAD
```

- 确认无未提交文件（`git status` 输出 `nothing to commit`）
- 确认本地主干与远端同步
- 全局扫描未解决的 `TODO` 注释，列出潜在风险
- **前置质检提醒**：如果最近的 commit 记录包含大范围或核心组件变更，必须高亮拦截询问：`[🔔 发版防呆]：本次部署包含核心重构，请确认是否已执行 "/sync-llm-context" 更新过系统规则上下文？若不需要请放行。`

🔴 **Blocker**：有未提交文件 → 提示用户先 commit 或 stash

---

## 第二步：代码卫生扫描

调用 `scan-code-hygiene` skill（`--scope=all`）。
→ 输出：调试语句 / TODO / 硬编码地址 / 潜在密钥 问题报告。

> 单独执行：`/scan-code-hygiene --scope=all`

🔴 **Blocker**：任何 🔴 高严重性问题（硬编码地址、密钥、console.log）→ 必须修复后才能继续
🟡 **警告**：TODO/FIXME → 询问用户是否豁免

---

## 第三步：后端测试验证

读取并执行 `.agents/skills/run-backend-tests/SKILL.md`，使用**快速子集模式**。

🔴 **Blocker**：任何 `FAILED` 或 `ERROR` → 必须修复后才能继续

---

## 第四步：数据库差异化导出 (Incremental DB Export)

读取并执行 `.agents/skills/export-db-indexes/SKILL.md`，使用内置的对比脚本提取最新数据库结构差异，强制生成 `ALTER TABLE` DDL 并附带真实查询场景（Query SQL）的完整注释。

🔴 **Blocker**：脚本执行报错，或未能提供含真实业务查询的注释说明 → 必须补充并交给 DBA Review。

---

## 第五步：基础设施检查

提示用户确认以下纯架构事项：

- [ ] `models.py`（或对应 ORM 文件）变更是否符合 `db.md` 规范？
- [ ] 缓存配置是否配置或清除到位？
- [ ] 环境变量是否已在目标环境注入？

---

## 第六步：QA 冒烟确认

**冒烟检查点**：
- [ ] 登录流程走通
- [ ] 核心页面正常加载
- [ ] 本次数据库差异化脚本（DDL）是否已在 QA 库过审并执行？
- [ ] 本次新功能主流程可用（具体由用户确认）

> 部署操作详见 `project.config.json` → `deploy` 配置，或参考项目内部部署文档。

🔴 **Blocker**：QA 有功能或数据映射异常 → 修复后重新从第一步开始

---

## 第七步：打 Tag 并发布生产

**1. 打 Tag**
```bash
# 格式见 project.config.json → deploy.tag_format
# 示例：v{YYYYMMDD-HHMM}-{描述}
git tag v$(date +%Y%m%d-%H%M)-<描述>
git push origin --tags
```

**2. 生产部署**
参考 `project.config.json` → `deploy` 配置中的平台和环境说明执行。
- **必须基于 tag 构建，禁止分支直上生产**
- **发布计划中回滚版本字段必填**，选上一次稳定 Tag，确保出问题可秒级回退

**3. 确认 CI/CD 流水线自检**
部署完成后，等待后置 CI 流水线执行自检巡检。
- 如果流水线在巡检节点失败，说明生产环境渲染出的内容与期望不符，必须立即排查！

---

## 预检报告输出格式

```
## 🚀 生产发布预检报告

| 检查项          | 状态 |
|----------------|------|
| 代码状态        | ✅ / 🔴 |
| 代码卫生扫描    | ✅ / 🟡 / 🔴 |
| 后端测试        | ✅ / 🔴 |
| 数据库增量导出  | ✅ / 🔴 (须带注释且为 ALTER 语法) |
| 基础设施确认    | ✅ / 待确认 |
| QA 冒烟        | ✅ / 🔴 |

**结论**：✅ 可发布 / 🔴 存在 Blocker，请先修复
```

---

## 核心防错原则

- **强制检查**：任何发布必须先通过测试，严禁带 `FAILED` 发布
- **实事求是**：遇到报错如实反馈，不夸大稳定性
- **回滚版本必选**：每次创建发布计划必须指定回滚版本，出问题秒级回退
- **Tag 上线**：禁止分支直接发布生产，无 Tag 不上线
