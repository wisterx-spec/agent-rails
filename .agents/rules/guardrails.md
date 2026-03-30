# 工程护栏与防错体系 (Engineering Guardrails)

**这是项目的强制红线与自检体系，违反任意一条均可能导致重大故障或返工。**

## 1. 领域操作前置阅读要求
执行任何重构或业务修改前，必须通过工具检索位于 `docs/lessons/` 的过往开发经验库：
- 修改业务路由、定时任务或执行数据库迁移前 → 查阅 `docs/lessons/backend.md`（如存在）
- 修改前端组件或调整全局状态树之前 → 查阅 `docs/lessons/frontend.md`（如存在）
- 编写带外部系统 I/O 或大模型调用的单元测试前 → 查阅 `docs/lessons/testing.md`（如存在）
- 触发或修补项目瘦身/无用代码删除的流水线前 → 完整阅读 `docs/lessons/slim-guardrails.md` 及核实 `.slimignore` 清单（如存在）

> 如上述文件不存在，跳过对应步骤，但须在报告中注明"该领域暂无经验积累"。

## 2. 全局核心禁止与红线区 (Critical Red Lines)

- **NEVER** 仅凭 IDE 静态分析的"未引用"警告删除路由或动态绑定目录下的文件。删除前必须执行全库搜索确认无隐式引用。
- **NEVER** 使用通配符命令（如 `rm *.lock`）批量清空运行时状态或锁文件。
- **NEVER** 将测试环境连接到真实外部计费接口（第三方 API、支付网关等）。
- **MUST** 对后端做完任何修补后，强制运行 `run-backend-tests` 技能验证。
- **NEVER** 带有 `FAILED` 或 `ERROR` 的测试结果进行提交或发版。

## 3. 数据库操作红线
- **NEVER** 在生产表上直接执行未经 Review 的 DDL 语句。
- **MUST** 任何 `ALTER TABLE` 必须附带真实业务场景的 Query SQL 注释，供 DBA Review。
- **NEVER** 在批量 DML（UPDATE/DELETE）中省略 WHERE 条件或分片键。

## 4. 前端操作红线
- **NEVER** 在前端源码中硬编码环境地址（如 `localhost:8000` 或生产域名），必须通过环境变量注入。
- **NEVER** 在 `git commit` 前保留 `console.log` 调试语句（`console.warn` / `console.error` 可保留）。
