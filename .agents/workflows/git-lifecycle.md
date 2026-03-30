---
description: 全栈 Git 开发与发布生命周期规范（涵盖开发、提交、QA、线上全流程）
---

# 全栈 Git 开发与发版生命周期

为保证代码质量与部署安全，所有开发者与 AI Agent 必须严格遵循以下四个生命周期的标准化 Git 与部署工作流。

---

## 1. 开发阶段 (Development)

**核心：保持代码池纯净，隔离开发风险**

- **基线同步**：始终基于最新的 `main` 分支进行开发。
- **特性分支**（推荐）：开发新功能或大重构时，切出独立分支：
  ```bash
  git checkout -b feature/YYYYMMDD-功能简述
  ```
- **工作区隔离**：所有本地生成的测试脚本、诊断日志、一次性排障文件，**必须**放入根目录下的 `tmp/` 文件夹中执行，绝对禁止散落在项目主干目录中污染 Git 追踪。
- **遵循开发流**：若涉及核心架构修改，开发前必须挂载 `/dev-flow` 工作流以读取安全护栏（Guardrails）。

---

## 2. 代码提交阶段 (Commit)

**核心：无损回归与结构化影响分析**

- **前置本地验证**：在执行 `git commit` 之前，必须在本地跑通测试。调用 `run-backend-tests` 技能（快速模式跑通基础逻辑）。**测试不通过，严禁提交（Blocker）**。
- **按规范组装 Commit**：强制使用 `commit-with-affects` 技能。提交信息必须包含传统的 `feat/fix/chore` 类型，以及影响面评估。示例格式：
  ```text
  feat(module-name): 功能描述

  affects: module-a,module-b
  changed-interfaces: /api/v1/xxx
  test-priority: high
  ```
  > 如项目未启用 `affects` 字段（见 `project.config.json → commit.affects_field_enabled`），可省略 `affects` 行。
- **推送远端**：确认无误后执行 `git push origin <分支名>`。

---

## 3. QA 测试部署阶段 (Pre-QA)

**核心：以主干分支作为测试基准**

- **触发防线检查**：在正式动手部署 QA 之前，按需执行 `/production-release` 的前置红线检查（检查硬编码残留、提取数据库变更 DDL 审计）。
- **QA 验收点**：环境拉起后，回归核心登录流程、主要功能页面，并验证数据库变更脚本是否已在此环境中安全应用。

---

## 4. 生产发布阶段 (Pre-Production)

**核心：无 Tag 不上线，永远保留退路**

- **禁止分支直上**：QA 验收完美通过后，**绝对严禁**使用 `main` 分支直接发布生产。
- **打上线锚点 (Tag)**：在本地基于当前的 `main` 节点打具备明确语义的 Tag，并推送：
  ```bash
  git tag v$(date +%Y%m%d-%H%M)-核心业务简述
  # 示例: git tag v20260326-1500-user-auth-revamp
  git push origin --tags
  ```
- **生产部署**：
  - 构建类型必须选择 **tag**，并选中刚才打好的 Tag 作为构建源
  - 发布计划中**「回滚版本」字段必填**，必须选中上一次稳定健康的 Tag，确保遇到阻断性现网故障时可实现秒级降级退回
- **产线巡检闭环**：平台部署动作完成后，等待后置 CI 流水线发起自检请求。若该巡检报警，需立即介入回滚排查。
