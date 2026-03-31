---
description: 0-1 新项目初始化工作流。在写第一行业务代码前，串联技术栈建议、页面地图、组件规划、约定锁定四个独立 skill，输出经人工确认的《架构蓝图》。
---

# Project Bootstrap 新项目初始化工作流

> **触发指令**：`/project-bootstrap [项目简述]`
> **适用场景**：全新项目，或重大重构前需要重新规划架构时
>
> **单步调用**：工作流内每个阶段也可独立触发：
> - `/advise-tech-stack` — 仅做技术栈选型建议
> - `/plan-page-map` — 仅规划页面地图
> - `/plan-component-hierarchy` — 仅规划组件层级
> - `/lock-global-conventions` — 仅生成全局约定 + .slimignore

---

## Phase 1：信息收集 (Discovery)

向用户提问，收集必要信息（一次性提问，不超过 8 个问题）：

```
Q1. 这个产品解决什么问题？目标用户是谁？
Q2. 预计的核心功能模块有哪些？
Q3. 初期预计日活/并发量级？
Q4. 是否需要多租户/多角色权限体系？有哪些角色？
Q5. 前端框架偏好？（React / Vue / 其他）
Q6. 后端语言偏好？（Python / Node.js / Go / 其他）
Q7. 是否有指定的 UI 组件库？
Q8. MVP 需要在什么时间节点可用？
```

**人工回答后**进入 Phase 2。

---

## Phase 2：技术栈确认

调用 `advise-tech-stack` skill，输入：Phase 1 问卷答案。
→ 输出：前端/后端/数据库/工程约定选型建议 + project.config.json 草稿。

**人工卡点**：确认技术栈后才进入 Phase 3。

---

## Phase 3：页面地图规划

调用 `plan-page-map` skill，输入：需求描述 + 角色信息。
→ 输出：完整页面路由树（标注 MVP/推迟）。

---

## Phase 4：组件层级规划

调用 `plan-component-hierarchy` skill，输入：页面地图 + 技术栈。
→ 输出：分层规则 + 必建组件清单 + 状态管理边界。

---

## Phase 5-6：全局约定锁定 + 项目围栏

调用 `lock-global-conventions` skill，输入：技术栈 + 组件规划。
→ 输出：全局约定文档 + .slimignore 初始内容。

---

## Phase 7：人工确认与归档 (Sign-off)

输出《架构蓝图》摘要：

```markdown
## 架构蓝图确认书 v1.0

✅ 技术栈：{{前端}} + {{后端}} + {{数据库}}
✅ 页面数量：N 个（MVP），M 个推迟
✅ 组件分层：ui / common / 模块专属 / pages
✅ 全局约定：已锁定
✅ .slimignore：已生成

确认后将执行：
1. 写入 project.config.json
2. 创建必建组件空壳
3. 创建页面路由骨架
4. 写入 docs/architecture/（约定文档）
5. 进入 /requirement-clarification → /auto-dev 开始第一个功能
```

**强制挂起**，等待用户回复"确认"后执行上述动作。

---

## 约束

- **NEVER** 在《架构蓝图》确认前创建任何业务代码文件
- **MUST** 必建组件在第一个功能开发前全部完成（哪怕是空壳）
- **MUST** 技术栈确认后才进入后续规划（顺序不可颠倒）
