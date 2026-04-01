# agent-rails 开发指南

> 本文件面向 Claude Code，指导如何开发和维护 agent-rails 框架本身。
> 框架使用说明见 README.md。

## 项目性质

纯 Markdown + Shell 项目，无构建步骤、无编译、无运行时依赖。
唯一的可执行文件：`install.sh`（安装脚本）和 `.agents/scripts/test_lock.py`（Python 3）。

## 验证命令

```bash
# 验证安装脚本语法
bash -n install.sh

# 验证 test_lock.py 可运行
python3 .agents/scripts/test_lock.py --help

# 检查 Markdown 链接完整性（如安装了 markdown-link-check）
find . -name "*.md" -not -path "./.git/*" | head -20 | xargs -I{} echo "TODO: {}"
```

## 目录结构约定

```
.agents/
  rules/      ← 硬约束，trigger: always_on，被 Claude Code 自动加载
  workflows/  ← 编排层，定义 skill 调用顺序和条件
  skills/     ← 原子工具，每个 skill 一个目录，内含 SKILL.md
  hooks/      ← git hook 模板
  scripts/    ← 可执行脚本
  SKILL_INDEX.md ← skill 注册表（依赖图 + 快速查找表）
docs/         ← 知识库模板（给目标项目用的）
```

## 编辑规则

### 文件格式
- Workflow 文件头部必须有 `description` frontmatter
- Rule 文件头部必须有 `trigger: always_on` frontmatter
- Skill 必须遵循 `.agents/skills/_SKILL_TEMPLATE.md` 格式
- 新增 Skill 必须同步更新 `.agents/SKILL_INDEX.md`（注册表 + 依赖图 + 快速查找表三处）

### 内容规范
- 面向用户的文档（README、CONTRIBUTING）使用英文
- 框架内部文件（rules、workflows、skills、docs 模板）使用中文
- 占位符格式：`{{VARIABLE_NAME}}`，必须在 `core.md` 的占位符映射表中注册
- `project.config.example.json` 的 key 结构是 API 契约，修改需要同步更新 `core.md` 中的映射表

### 不要做的事
- 不要在 rules/ 文件中写具体的执行逻辑，rules 只做约束声明
- 不要让 workflow 直接操作文件，workflow 只编排 skill 调用顺序
- 不要在 skill 中硬编码路径，用 `{{}}` 占位符引用 project.config.json
- 不要修改 `project.config.example.json` 的 key 名称（除非同步改 core.md 映射 + 所有引用处）

## 常用开发任务

### 新增一个 Skill
1. 复制 `.agents/skills/_SKILL_TEMPLATE.md` 到 `.agents/skills/{skill-name}/SKILL.md`
2. 填写 frontmatter（name、description）
3. 编写执行步骤
4. 更新 `.agents/SKILL_INDEX.md`（三处：workflow 一览、skill 完整清单、调用依赖图）
5. 如果被 workflow 调用，更新对应 workflow 文件

### 新增一个 Workflow
1. 在 `.agents/workflows/` 创建 `{name}.md`
2. 填写 `description` frontmatter
3. 编排 skill 调用顺序
4. 更新 `.agents/SKILL_INDEX.md`
5. 更新本文件的"可用指令"表（如果是用户可触发的）
6. 更新 README.md 的 Quick Command Reference

### 修改 project.config.example.json
1. 修改 example 文件
2. 同步更新 `core.md` 中的占位符映射表
3. 全局搜索旧的 key 名，确认所有 skill/workflow 引用已更新
4. 更新 README.md 的 Key Fields 说明

## 可用指令

以下指令在安装了 agent-rails 的目标项目中可用（不是本项目）：

| 指令 | 说明 |
|------|------|
| `/dev-flow` | 新需求开发标准流程（人工驱动，8 步闭合链） |
| `/auto-dev [TODO]` | 一站式自动开发（AI 自驱，Ralph-loop） |
| `/auto-dev resume` | 从中断点恢复 |
| `/requirement-clarification` | 需求澄清（模糊需求时强制前置） |
| `/project-bootstrap` | 新项目架构规划（0 到 1） |
| `/impact-analysis` | 变更爆炸半径分析 |
| `/pr-review` | PR 描述 + 自检清单 |
| `/hotfix [描述]` | 生产紧急修复 |
| `/production-release` | 发版上线前检查 |
| `/slim` | 项目瘦身（孤儿组件/死路由/未用导出/重型依赖） |
| `/weekly-report` | 自动生成开发周报 |

## 核心原则

1. 仅陈述可从代码库或上下文验证的内容
2. 不把推测当事实，无法确定时直接说"不清楚"
3. 框架内部文件使用中文，面向用户的文档使用英文
4. **放在一起是流程，单独拿出来是 skill** — 这是架构的核心设计原则
