---
trigger: always_on
---

# 项目全局规则 (Global Rules)

> 本文件是唯一的 always-on 规则文件。只包含跨所有任务的绝对红线。
> 领域专项规则（前端、数据库）已下沉为 skill，按需加载。

---

## 一、启动协议

1. **MUST** 接入会话时，首先读取 `docs/INDEX.md`（如存在），再读取 `.agents/workflows/dev-flow.md` 获悉开发流程。
2. **MUST** 通过工具读取 `project.config.json` 构建本会话上下文快照。文件不存在则立即停止，提示用户：`cp project.config.example.json project.config.json`。
3. 从配置中提取核心变量，替换 workflow/skill 中的 `{{}}` 占位符：

| 占位符 | 配置路径 |
|--------|---------|
| `{{PROJECT_NAME}}` | `project.name` |
| `{{FRONTEND_PATH}}` | `tech_stack.frontend_path` |
| `{{BACKEND_PATH}}` | `tech_stack.backend_path` |
| `{{TEST_PATH}}` | `tech_stack.test_path` |
| `{{FRONTEND_TEST_PATH}}` | `tech_stack.frontend_test_path` |
| `{{LOCAL_DB_URL}}` | `testing.local_db_url` |
| `{{TEST_FAST_COMMAND}}` | `testing.commands.fast` |
| `{{TEST_FULL_COMMAND}}` | `testing.commands.full` |
| `{{FAST_MARK_EXPR}}` | `testing.fast_mode_exclude_marks` 转为 pytest 表达式，如 `slow,performance` → `not slow and not performance`；为空则省略 `-m` 参数 |
| `{{FULL_MARK_EXPR}}` | `testing.full_mode_exclude_marks` 转为 pytest 表达式；为空则省略 `-m` 参数 |
| `{{DESIGN_SYSTEM_FILE}}` | `design_system.reference_file` |
| `{{SEMANTIC_COLOR_PREFIX}}` | `design_system.semantic_color_prefix` |
| `{{OUTPUT_DIR}}` | `weekly_report.output_dir` |
| `{{CSS_FRAMEWORK}}` | `tech_stack.css_framework` |
| `{{BACKEND_LANG}}` | `tech_stack.backend`（取第一个词） |
| `{{AGENT_SIGNAL_DIR}}` | `agent.signal_dir` |
| `{{AGENT_DELIVERY_DIR}}` | `agent.delivery_dir` |
| `{{AGENT_MANAGEMENT_DIR}}` | `agent.management_dir` |

4. 推导行为开关：
   - `前端能力启用`：`capabilities.frontend == true` 或 `tech_stack.frontend` 非空且非 `none`
   - `后端能力启用`：`capabilities.backend == true` 或 `tech_stack.backend` 非空且非 `none`
   - `数据库能力启用`：`capabilities.database == true` 或 `tech_stack.database` 非空且非 `none`
   - `前端CSS约束启用`：`css_framework == "tailwind"`
   - `测试命令已配置`：`testing.commands.fast/full` 存在且不是占位值
   - `测试锁启用`：`testing.test_lock_script` 存在
   - `affects字段启用`：`commit.affects_field_enabled == true`
5. 输出：`[CONFIG LOADED] project=xxx | frontend=xxx | backend=xxx | db=xxx`
6. **钢印审查提醒**：读取 `tmp/.last-guardrails-review`，若文件不存在或距今超过 **3 天**，输出：`[MAINTENANCE DUE] 距上次钢印审查已 N 天，建议执行 /review-guardrails`。不阻塞，仅提醒。
7. **CRITICAL** 输出任何定稿方案后，禁止擅自进入编码模式，必须等待人类明确指令（如"开始"、"执行"）。

---

## 二、反幻觉协议

以下 4 条强制执行，不可跳过：

1. **引用前验证**：调用任何现有函数/类/变量前，先用工具搜索确认其定义存在。NEVER 凭记忆写引用。
2. **调用前读签名**：编写调用方代码前，先读被调用方的函数签名或接口定义。NEVER 假设 API 返回结构。
3. **Mock 前读真实结构**：写 mock 数据前，先读对应 ORM 模型或 response 类型。断言字段名必须与真实字段完全一致。
4. **修改前读文件**：Edit 任何文件前，必须在本会话内读过该文件。NEVER 未读就 Write 覆盖。

> **自我熔断**：不确定某函数/字段/路径是否存在时，立即停止生成，先用工具验证。

---

## 三、工程红线

### 通用
- **NEVER** 仅凭 IDE "未引用" 警告删除文件，删除前必须全库搜索确认。
- **NEVER** 使用通配符命令（如 `rm *.lock`）批量清空运行时状态。
- **NEVER** 将测试环境连接到真实计费接口。
- **NEVER** 带 FAILED/ERROR 测试结果提交或发版。
- **MUST** 代码修改后按改动域运行 `run-tests --mode=fast` 或项目显式配置的等价验证命令。

### 密钥安全
- **NEVER** 将密钥、Token、密码、证书硬编码在源代码中或提交到 git。
- **MUST** 敏感信息通过 `.env`（已 gitignore）/ CI Secrets / Vault 管理。
- **NEVER** 用 `--no-verify` 绕过 pre-commit secret 扫描。

### 数据库
- **NEVER** 在生产表上执行未经 Review 的 DDL。
- **MUST** ALTER TABLE 必须附带真实业务 Query SQL 注释。
- **NEVER** 批量 DML 省略 WHERE 条件。

### 前端
- **NEVER** 硬编码环境地址（localhost / 生产域名），必须通过环境变量注入。
- **NEVER** 提交前保留 `console.log`（`console.warn`/`console.error` 可保留）。

### 依赖
- **NEVER** 为单一用途引入重型依赖。
- **MUST** 锁定依赖版本，变更须在 commit message 中说明。
- **NEVER** 将 dev 依赖混入生产依赖。

---

## 四、域路由指令

触碰以下领域代码前，**必须先通过工具读取对应 skill 全文**：

| 改动领域 | 必读 skill |
|---------|-----------|
| 前端 UI 组件/样式/状态 | 读取 `frontend-dev-guide`（`.agents/skills/frontend-dev-guide/SKILL.md`） |
| 数据库 ORM / 表结构 / 迁移 | 读取 `db-dev-guide`（`.agents/skills/db-dev-guide/SKILL.md`） |
| 任何代码模块 | 先查 `docs/decisions/README.md` 索引，命中则读对应决策文件 |

触碰以下领域前，查阅经验库（如存在）：
- 修改业务路由/任务/迁移 → `docs/lessons/backend.md`
- 修改前端组件/全局状态 → `docs/lessons/frontend.md`
- 编写含外部 I/O 的测试 → `docs/lessons/testing.md`

---

## 五、文件与知识库保护

- **MUST** 临时代码/诊断脚本/中间数据放入 `./tmp/`，不污染 Git。
- **NEVER** 在 `docs/` 根目录直接新建散装文件，新增知识按语义下钻到子目录。
- **NEVER** 普通开发流程自主修改 `docs/lessons/*`、`.agents/rules/*`、`docs/llm-context/*`。普通 Agent 只允许以 `[KNOWLEDGE_UPDATE]` 格式提出建议。
- **MAY** `/dream` 工作流在通过 evidence gate 后更新 `docs/lessons/*` 与 `docs/llm-context/*`。
- **NEVER** 任何自动流程修改 `.agents/rules/*`；规则文件只能由人类直接编辑。
- 代码开发必须严格套接标准流（`/auto-dev`、`/dev-flow`），禁止自造流程。

---

## 六、经验总结触发

### 负面经验（踩坑记录）

修复非显而易见 Bug、踩坑、规范需例外、AI 假设被纠正、测试发现隐患时，**必须**立即提出 `[KNOWLEDGE_UPDATE]` 建议：

```markdown
## [踩坑] {{问题标题}}（{{YYYY-MM-DD}}）
**现象**：{{一句话描述}}
**根因**：{{为什么}}
**正确做法**：{{怎么做}}
**验证命令**（如适用）：{{如何确认}}
```

### 正面经验（有效实践）

发现某个实现方式效果特别好、某个模式显著提升了效率或质量时，同样**必须**提出 `[KNOWLEDGE_UPDATE]` 建议：

```markdown
## [有效实践] {{实践标题}}（{{YYYY-MM-DD}}）
**场景**：{{什么情况下用}}
**做法**：{{具体怎么做}}
**效果**：{{带来了什么好处}}
**适用条件**：{{什么条件下推荐使用，什么条件下不适用}}
```

### Guide Skill 同步提醒

当 `[KNOWLEDGE_UPDATE]` 的内容属于 `frontend-dev-guide` 或 `db-dev-guide` 的覆盖范围时，必须额外标注：
```
[GUIDE_UPDATE] 本条经验建议同步更新 {{skill 名称}}，涉及章节：{{章节标题}}
```
提醒人工将经验固化到对应的 guide skill 中，避免 lessons 与 guide 长期不同步。

---

## 七、钢印保鲜机制

> 规范只增不减会导致过期条目积累、注意力稀释。以下机制确保钢印内容保持有效。

### 条目时间戳要求

`docs/conventions.md` 和 `docs/lessons/*.md` 中的每个条目**必须**包含日期标注（`YYYY-MM-DD`）。无日期的历史条目视为需要审查。

### 自动过期检测

auto-dev Phase 0（规范预加载）和 dev-flow Step 2（脑部钢印读取）在读取规范文件时，如果发现条目日期超过 **90 天**，必须在快照中标注 `[STALE: {{条目标题}}]`，提醒人工在本次开发结束后审查。

### 过期条目处理

在 auto-dev Phase 5（合规收口）或 `/slim` 工作流中，如果存在 `[STALE]` 标注的条目，输出以下审查提议：

```markdown
[CONVENTION_REVIEW] 以下条目已超过 90 天，请确认是否仍然有效：
- [ ] {{条目标题}}（{{日期}}）→ 保留 / 更新 / 删除
```

人工确认后：
- **保留**：更新日期为当天，表示已审查确认仍有效
- **更新**：修改内容并更新日期
- **删除**：移除条目，必要时在 `docs/decisions/` 中记录删除原因
