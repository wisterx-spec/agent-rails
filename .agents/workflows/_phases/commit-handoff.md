# 合规收口入库 (Commit Handoff)

> 本文件被 auto-dev Phase 5 和 dev-flow Step 9 引用。

---

## Step 1：强制复习规范

- 重新读 `commit-with-affects/SKILL.md` 原文（不跳过）
- 对照《规范快照》做最终检查

---

## Step 2：代码卫生扫描

```bash
/scan-code-hygiene --scope=staged
```

P0 问题 → 阻断提交，必须修复。
P1 问题 → 允许提交，commit message 附注 known-issues。

---

## Step 3：组装 commit

调用 `commit-with-affects` skill，逆向扫描 `git diff`，计算影响面，生成标准化 commit message。

commit message 包含：
- 影响面评估和优先级标度
- 本次解决的问题清单摘要
- P1 遗留问题（如有）

---

## Step 4：推入分支

推入 Feature 分支完成入库。

---

## 以下仅 auto-dev 执行（dev-flow 跳过）

### Step A：钢印保鲜审查（条件触发）

若规范预加载阶段标注了 `[STALE]` 条目，输出审查提议：

```
[CONVENTION_REVIEW] 以下条目已超过 90 天，请确认是否仍然有效：
- [ ] {{条目标题}}（{{日期}}）→ 保留 / 更新 / 删除
```

人工确认后：保留→更新日期为当天；更新→修改内容并更新日期；删除→移除条目。

若无 `[STALE]` 条目 → 跳过。

### Step B：决策兜底检测（条件触发，捕漏用）

检查实现过程中是否出现阶段二未能预见的决策点：
- 实现中才暴露的隐性约束（如第三方 SDK 限制、并发边界）
- 用户在本次任务中说了"这里要注意"、"不要改这里"之类的话
- 某个假设被推翻后，选择了与原方案不同的路线

若存在且阶段二未已记录，输出提议草稿并等待人工确认后写入。
若阶段二已记录所有决策 → 跳过，不重复提示。

### Step C：输出《本次开发完整报告》

- 执行了几轮 Execute 循环
- 最终交付的业务能力汇总
- 解决的问题清单（P0/P1）
- 遗留的 P2 清单
- 对《规范快照》的补充建议
- 建议沉淀为新 SKILL.md 的最佳实践

### Step D：清理会话存档

删除 `tmp/.agent-session.md`（任务已完成，存档不再需要）。

### Step E：交接

退出自动控制流，提示用户触发 `/production-release`。
