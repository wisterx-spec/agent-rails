# AI Dev Workflow — Claude Code 集成说明

本项目是一套可移植的 AI 辅助开发规范框架，基于三层架构运作：

```
.agents/
  rules/      ← 硬红线（始终加载）
  workflows/  ← 执行流（按需触发）
  skills/     ← 原子工具（被 workflows 调用）
```

## 快速上手

1. 复制整个 `.agents/` 目录到目标项目根目录
2. 复制 `project.config.json`（从 `project.config.example.json`）并填入项目特异值
3. 将 `CLAUDE.md` 内容合并到目标项目的 CLAUDE.md

## 可用指令

| 指令 | 说明 |
|------|------|
| `/dev-flow` | 新需求开发标准流程（8步闭合链） |
| `/auto-dev [TODO内容]` | 一站式自动开发（Ralph-loop 模式） |
| `/impact-analysis` | 变更爆炸半径排雷（Step 0-8 推演） |
| `/production-release` | 发版上线前检查 |
| `/git-lifecycle` | Git 开发生命周期规范 |
| `/weekly-report` | 自动生成开发周报 |

## 规则加载路由

- 涉及数据库表变更 → `.agents/rules/db.md`
- 涉及前端 UI 组件 → `.agents/rules/frontend-ui.md`
- 涉及路由/定时任务/迁移 → `.agents/rules/guardrails.md`

## 核心原则

1. 仅陈述可从代码库或上下文验证的内容
2. 不把推测当事实，无法确定时直接说"不清楚"
3. 所有思考过程和回复统一使用中文
4. 代码开发必须套接系统内置标准流程，严禁脱轨自造操作

## 配置说明

项目特异的参数（部署平台、数据库地址、前端路径等）统一在 `project.config.json` 中管理。
Workflow 和 Skill 文件通过读取此配置动态适配，无需修改框架文件本身。
