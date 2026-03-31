# ai-dev-workflow

一套可移植的 AI 辅助开发规范框架，基于 Claude Code。

**设计原则：放在一起是流程，单独拿出来是 skill。**

每个工作流由若干独立 skill 组成，skill 也可以单独调用。框架本身不绑定任何项目，通过 `project.config.json` 注入项目特异参数后开箱即用。

---

## 安装

```bash
# 安装到当前项目
./install.sh

# 或安装到指定路径
./install.sh /path/to/your-project
```

安装完成后，编辑 `project.config.json`，填写项目实际的路径、数据库地址、技术栈信息。

---

## 文件结构

```
.agents/
  rules/          # 硬红线规则（始终加载）
    core.md           — 全局规则：配置加载协议、幻觉防控清单、知识库写保护
    guardrails.md     — 工程红线：数据库操作、前端禁止项、密钥、依赖管理、经验总结触发
    frontend-ui.md    — 前端 UI 约定：语义色、统一组件、状态管理边界
    db.md             — 数据库路由器：根据 tech_stack.database 分发到具体规则
    db-mysql.md       — MySQL 专属规则
    db-sqlite.md      — SQLite 专属规则
    db-postgres.md    — PostgreSQL 专属规则

  workflows/      # 工作流（纯编排，调用 skill 的编排层）
    requirement-clarification.md  — 需求澄清：结构化提问 → 需求规格确认书
    project-bootstrap.md          — 0-1 新项目：架构规划 → 组件层级 → 约定锁定
    auto-dev.md                   — 全自动开发（Ralph-loop，支持 resume）
    dev-flow.md                   — 人工驱动开发（探索性场景）
    frontend-tdd.md               — 前端 Component-TDD + UX 卡点
    impact-analysis.md            — 变更影响范围分析
    hotfix.md                     — P0 生产紧急修复
    pr-review.md                  — PR 描述生成 + 代码自检
    slim.md                       — 项目瘦身（孤儿文件/死路由/依赖扫描）
    production-release.md         — 发版前检查 → 打 tag → 上线
    git-lifecycle.md              — Git 开发生命周期规范
    weekly-report.md              — 自动生成开发周报

  skills/         # 原子工具（可独立调用，也被 workflow 编排）
    项目规划类：
      advise-tech-stack/          — 技术栈选型建议
      plan-page-map/              — 页面地图规划
      plan-component-hierarchy/   — 组件层级规划
      lock-global-conventions/    — 全局约定锁定 + .slimignore 生成
    测试类：
      generate-test-skeleton/     — Test-First 测试骨架生成
      run-tests/                  — 测试路由（→ pytest 或 jest）
      generate-test-from-impact/  — 从 impact-analysis GAP 生成测试
    数据库类：
      export-db-indexes/          — 生成增量 DDL + 回滚 DDL
    提交类：
      commit-with-affects/        — 带影响面的标准化 commit
      generate-pr-description/    — 基于 git log 生成 PR 描述
      pr-self-review/             — 代码质量/规范/安全/测试四维度自检
    前端质量类：
      frontend-ux-evaluator/      — 单个组件/页面 UX 评估（5 维度）
      scan-frontend-quality/      — 全量前端质量扫描（8 维度）
    代码卫生类：
      scan-code-hygiene/          — 扫描 console.log/TODO/硬编码/密钥
    项目瘦身类：
      scan-orphan-components/     — 孤儿组件扫描
      scan-dead-routes/           — 死路由扫描
      scan-unused-exports/        — 未引用导出扫描
      scan-bundle-bloat/          — 重型依赖优化建议
    知识管理类：
      sync-llm-context/           — 刷新 AI 上下文地图

  scripts/
    test_lock.py    # 测试基线防篡改工具（lock / verify / status）

  SKILL_INDEX.md  # Skill 注册表（工作流一览 + 完整依赖图 + 快速查找）

docs/
  INDEX.md              # 项目知识地图（AI 入场必读）
  lessons/
    backend.md          # 后端踩坑记录
    frontend.md         # 前端踩坑记录
    testing.md          # 测试踩坑记录

project.config.json        # 项目特异参数（不提交到 git）
project.config.example.json
.slimignore.example        # 瘦身豁免清单模板
```

---

## 快速指令参考

### 常用工作流

| 指令 | 用途 |
|------|------|
| `/requirement-clarification` | 需求澄清（所有开发的起点） |
| `/project-bootstrap` | 全新项目架构规划 |
| `/auto-dev [规格书]` | 全自动开发（需求确认后触发） |
| `/auto-dev resume` | 从中断点恢复开发 |
| `/hotfix` | P0 生产故障紧急修复 |
| `/pr-review` | 提 PR 前的描述生成 + 自检 |
| `/production-release` | 发版前全套检查 + 打 tag |
| `/slim` | 项目瘦身（孤儿文件/死路由/依赖） |
| `/sync-llm-context` | 刷新 AI 对项目的认知地图 |

### 可单独调用的 Skill

| 指令 | 用途 |
|------|------|
| `/advise-tech-stack` | 仅做技术栈选型 |
| `/plan-page-map` | 仅规划页面路由结构 |
| `/plan-component-hierarchy` | 仅规划组件分层 |
| `/generate-test-skeleton --type=api\|service\|db\|frontend` | 生成 Test-First 测试骨架 |
| `/export-db-indexes` | 生成数据库迁移 DDL + 回滚 DDL |
| `/generate-pr-description` | 仅生成 PR 描述 |
| `/pr-self-review` | 仅执行 PR 代码自检 |
| `/frontend-ux-evaluator` | 评估单个组件/页面的 UX 质量 |
| `/scan-frontend-quality` | 全量扫描前端质量 |
| `/scan-code-hygiene [--scope=staged\|all]` | 扫描代码卫生问题 |
| `/scan-orphan-components` | 仅扫孤儿组件 |
| `/scan-dead-routes` | 仅扫死路由 |
| `/scan-unused-exports` | 仅扫未引用导出 |
| `/scan-bundle-bloat` | 仅扫重型依赖 |

---

## 典型使用场景

### 全新项目

```
/project-bootstrap 用户管理系统，React + FastAPI
→ 技术栈确认 → 页面地图 → 组件层级 → 约定锁定 → 你确认《架构蓝图》
→ /requirement-clarification [第一个功能]
→ /auto-dev [确认后的规格书]
```

### 接手存量项目

```bash
./install.sh /path/to/existing-project
# 填写 project.config.json
```
```
/sync-llm-context        # AI 扫描仓库，生成上下文地图
/scan-frontend-quality   # 了解现有前端质量基线
# 然后按正常流程开发新需求
```

### 正常全栈需求

```
/requirement-clarification     # 最多 6 个问题澄清需求
→ 你确认《需求规格确认书》
→ /auto-dev [规格书]
  → 前端 Component-TDD（写测试→锁定→实现→验绿→UX评估→你确认）
  → 你在浏览器确认 UI
  → 后端开发（从已确认 UI 反推 API 契约）
→ /pr-review
→ /production-release
```

### 被打断后恢复

```bash
git stash                # 暂存当前工作
git checkout -b feature/B
# 处理 B 需求
git checkout feature/A
git stash pop
/auto-dev resume         # 从 tmp/.agent-session.md 恢复现场
```

### 生产 P0 故障

```bash
git stash                # 先保存当前工作
git checkout main && git checkout -b hotfix/xxx
/hotfix                  # P0 专用流程（最小化修复，跳过大部分步骤）
# 修复上线稳定后
git checkout feature/xxx
git stash pop
/auto-dev resume
```

### 定期项目瘦身

```
/slim
→ scan-orphan-components + scan-dead-routes + scan-unused-exports + scan-bundle-bloat
→ 生成《删除提案》（P0/P1/P2 分级）
→ 你确认 → AI 逐文件删除 → 全量测试验证
```

---

## project.config.json 关键字段

```jsonc
{
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",       // 前端源码根目录
    "backend": "python+fastapi",
    "backend_path": "backend/app",         // 后端源码根目录
    "test_path": "backend/tests",
    "database": "mysql",                   // mysql | sqlite | postgres
    "css_framework": "tailwind",           // 影响颜色规范的开关
    "frontend_test_path": "frontend/src/__tests__",
    "frontend_extensions": ["tsx", "ts"]   // scan-frontend-quality 用
  },
  "testing": {
    "local_db_url": "...",                 // 本地测试数据库
    "test_lock_script": ".agents/scripts/test_lock.py"
  },
  "deploy": {
    "tag_format": "v{YYYYMMDD-HHMM}-{description}",
    "rollback_required": true
  }
}
```

完整字段说明见 `project.config.example.json`。

---

## 三层架构说明

```
Rules（始终加载）
  └─ 硬红线，所有操作的底层约束
       ↓
Workflows（按需触发）
  └─ 纯编排层，定义 skill 的调用顺序和条件
       ↓
Skills（原子工具）
  └─ 每个 skill 有独立的触发指令，也被 workflow 编排调用
```

- **Rules** 不需要手动触发，AI 接手会话时自动加载
- **Workflows** 通过 `/workflow-name` 触发，内部调用 skill 的顺序
- **Skills** 通过 `/skill-name` 独立调用，也可以由 workflow 串联

详见 `.agents/SKILL_INDEX.md`（完整依赖图 + 快速查找表）。

---

## 测试基线保护

```bash
# 锁定（Test-First 阶段，人工确认测试骨架后执行）
python .agents/scripts/test_lock.py lock

# 验证（每次跑测试前自动触发，防止断言被篡改）
python .agents/scripts/test_lock.py verify

# 查看当前基线状态
python .agents/scripts/test_lock.py status
```

锁定后，测试断言不允许修改。实现出问题只能改实现代码，不允许改预期。

---

## 经验沉淀

项目开发过程中的踩坑，AI 会在 Ralph-loop 每轮结束时检测并提出 `[KNOWLEDGE_UPDATE]` 建议文本，由你决定是否写入 `docs/lessons/`。

这些文件是 AI 下次接手任务时的"入场背景"，不记录常识，只记录**在本项目踩过的坑**。
