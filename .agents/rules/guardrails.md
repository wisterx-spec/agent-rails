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

## 5. 密钥与凭据安全红线 (Secrets & Credentials)

- **NEVER** 将任何密钥、Token、密码、证书硬编码在源代码中，包括但不限于：
  API Key、数据库密码、JWT Secret、第三方服务凭据、私钥文件。
- **NEVER** 将含有真实凭据的文件（`.env`、`*.pem`、`*_key.json`）提交到 git，无论是公开还是私有仓库。
- **MUST** 所有环境变量必须通过以下方式管理：
  - 本地开发：`.env` 文件（**必须在 `.gitignore` 中**）
  - CI/CD：平台的 Secret 管理功能（GitHub Secrets、GitLab CI Variables 等）
  - 生产：容器环境变量注入或密钥管理服务（Vault、AWS Secrets Manager 等）
- **MUST** `git commit` 前执行心理清单（或配置 pre-commit hook）：
  - [ ] 有没有新增包含 `key`、`secret`、`password`、`token` 字样的变量赋值？
  - [ ] 有没有新增 `.env` 文件？
  - [ ] 有没有硬编码的 URL 中包含凭据（如 `mysql://user:pass@host`）？
- **MUST** `project.config.json` 中的数据库密码等敏感字段，依赖 `.gitignore` 排除，
  Agent 在任何输出或日志中不得完整打印此文件内容。

> 如项目配置了 `pre-commit` 的 secret 扫描 hook（如 `detect-secrets`、`gitleaks`），
> 触发拦截时必须认真处理，**禁止用 `--no-verify` 绕过**。

## 6. 依赖管理红线 (Dependency Management)

- **MUST** 新增第三方依赖前，确认以下三点：
  1. 该依赖有无更轻量的替代方案，或项目现有依赖能否已覆盖此需求
  2. 包的最近发布时间和维护状态（长期无人维护的包有安全风险）
  3. License 是否与项目兼容（商业项目避免 GPL 强传染性 License）
- **NEVER** 引入一个功能只为覆盖该功能一个小用法的重型依赖（如只用 `lodash.get` 时引入整个 lodash）。
- **MUST** 锁定依赖版本（`package-lock.json` / `poetry.lock` / `requirements.txt` 精确版本），不允许在锁文件存在时使用宽松版本范围（如 `^1.0.0`）而不更新锁文件。
- **MUST** 依赖变更（新增/升级/删除）必须在 commit message 中明确说明理由，不允许无说明的依赖版本变更。
- **NEVER** 在生产依赖中引入仅用于开发/测试的包（`devDependencies` / `requirements-dev.txt` 的分类必须正确）。

## 7. 经验总结强制触发 (Lessons Learned Protocol)

以下情况**必须**在完成修复/开发后立即向用户提出 `[KNOWLEDGE_UPDATE]` 建议，不推迟到"有时间再写"：

| 触发场景 | 记录目标文件 | 记录内容 |
|---------|------------|---------|
| 修复了一个非显而易见的 Bug | `docs/lessons/backend.md` 或 `frontend.md` | 现象 → 根因 → 正确做法 |
| 发现代码行为与直觉/文档不符（踩坑） | 对应领域的 lessons 文件 | 踩坑点 + 验证方法 |
| 某个规范在当前项目中不适用，需要例外 | `docs/lessons/` 对应文件 | 例外场景 + 为什么例外合理 |
| 某个 AI 自行假设后被人工纠正 | `docs/lessons/` 对应文件 | 被纠正的假设 + 正确做法 |
| 测试发现了生产代码的隐患（非功能性问题） | `docs/lessons/testing.md` | 隐患类型 + 检测方式 |

**格式要求**：
```markdown
## {{问题标题}}（{{YYYY-MM-DD}}）

**现象**：{{用一句话描述遇到了什么}}
**根因**：{{为什么会这样}}
**正确做法**：{{应该怎么做}}
**验证命令**（如适用）：{{如何确认问题已解决}}
```

**约束**：
- AI 只能提出 `[KNOWLEDGE_UPDATE]` 建议，不自动写入（遵从 `core.md` 知识库写入权限红线）
- 建议文本必须完整，用户可以直接复制后只需确认
- 不记录显而易见的常识（如"SQL 要有 WHERE 条件"），只记录**在本项目中踩过坑**的内容
