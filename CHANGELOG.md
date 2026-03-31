# Changelog

## v1.0.0 — 2026-03-31

### 初始发布

**三层架构**
- Rules（始终加载）：core、guardrails、frontend-ui、db 系列
- Workflows（按需触发）：11 个工作流，覆盖全栈开发全生命周期
- Skills（原子工具）：14 个可独立调用的 skill

**核心工作流**
- `requirement-clarification`：需求澄清 → 规格确认书
- `auto-dev`：全自动开发，内置 Ralph-loop 自优化，支持 resume
- `dev-flow`：人工驱动开发
- `frontend-tdd`：Component-TDD + UX 评估卡点
- `project-bootstrap`：0-1 项目架构规划
- `slim`：项目瘦身（孤儿组件/死路由/未引用导出/重型依赖）
- `production-release`：发版前检查 + 打 tag

**质量保障机制**
- 测试基线保护（test_lock.py）
- 提交前双重门禁（scan-code-hygiene + pre-commit hook）
- 幻觉防控强制清单（4 场景硬约束）
- 增量组件复用检查

**知识管理**
- `docs/conventions.md`：活的约定文档，全程维护
- `docs/decisions/`：架构决策记录（ADR）
- `docs/lessons/`：踩坑经验积累
- `[KNOWLEDGE_UPDATE]` / `[CONVENTION_PROPOSAL]` 机制

**Token 优化**
- 规范快照封存协议（Phase 0 一次加载，全程引用）
- SKILL.md 按需路由加载
- conventions.md 分区读取（只读核心约定速查区块）
- ADR QUICK 行（单行禁止事项摘要）
- Session 文件滚动保留（最近 3 轮）
