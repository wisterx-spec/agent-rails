---
description: 生产紧急修复流程。仅用于线上 P0 故障，需在最短时间内安全推送修复。非紧急情况禁止走此流程。
---

# Hotfix 紧急修复流程

当用户输入 `/hotfix [问题描述]` 时执行。

> ⚠️ **准入门槛**：此流程仅适用于以下场景：
> - 生产服务不可用 / 核心功能完全失效
> - 数据写入错误 / 安全漏洞已被利用
> - 预计修复代码量 ≤ 50 行
>
> 超出范围或不确定时，停止并走标准 `/dev-flow`。

---

## Step 0：确认紧急级别

先问用户两个问题（如果信息不足）：
1. 故障现象是什么？影响多少用户？
2. 是否已有明确的根因定位？

如果根因未定位，**禁止直接开始写代码**，先用 `/impact-analysis` 排查根因。

---

## Step 1：创建 Hotfix 分支

```bash
git checkout main && git pull origin main
git checkout -b hotfix/YYYYMMDD-{问题简述}
```

---

## Step 2：最小化修复（Minimal Fix）

**只改必须改的，不顺手重构，不附带优化。**

- 改动范围严格限定在根因文件
- 不允许在此次 commit 中夹带任何非故障相关的改动
- 修复完成后，人工 diff 确认改动行数符合预期

---

## Step 3：精简验证（Targeted Test — 不跑全量）

仅针对受影响的模块运行测试，而非全量：

```bash
# 示例：只跑与故障模块相关的测试文件
cd {{BACKEND_PATH}} && TEST_DATABASE_URL='{{LOCAL_DB_URL}}' \
  python -m pytest tests/test_{affected_module}.py -v
```

> 若修复涉及数据库查询，必须在测试库验证 SQL 正确性后再提交。
> 若本地无法快速验证（如依赖特定生产数据），在 commit message 中明确标注 `[UNVERIFIED_LOCALLY]`。

**跳过**：impact-analysis、测试骨架、全量测试、export-db-indexes（如无 schema 变更）

---

## Step 4：Commit 并推送

```bash
git add {具体文件}
git commit -m "hotfix({scope}): {一句话根因描述}

root-cause: {根因}
affected: {影响范围}
risk: {回滚方式}
[HOTFIX]"
```

```bash
git push origin hotfix/YYYYMMDD-{问题简述}
```

---

## Step 5：快速 PR + 合并

- 创建 PR，目标分支：`main`
- PR 描述必须包含：根因、修复方案、回滚步骤
- 至少 1 人 Review 后合并（紧急时可降为 self-merge，但须在 PR 中说明理由）
- **合并策略：`squash merge`**，保持 main 历史干净

---

## Step 6：紧急发版

直接触发 `/production-release`，但**跳过以下步骤**：
- ~~第三步：后端测试验证~~（已在 Step 3 针对性验证）
- ~~第四步：数据库差异化导出~~（如无 schema 变更）

其余步骤（代码卫生扫描、Tag、QA 冒烟确认）**必须执行**。

---

## Step 7：上线后 30 分钟观察

部署完成后，**不要立刻关闭故障单**，执行：

- [ ] 核心功能恢复正常
- [ ] 错误日志停止报警
- [ ] 受影响用户确认可用

30 分钟无异常后关闭故障单，并在 `docs/lessons/` 中记录此次事故根因与修复过程。

---

## 禁止事项

- **NEVER** 在 hotfix 分支上做与故障无关的改动
- **NEVER** 跳过 Step 7 观察期直接宣布修复完成
- **NEVER** 用 hotfix 流程处理非 P0 问题（性能优化、小 Bug 都不算）
- **NEVER** 在生产数据库执行未经验证的 SQL
