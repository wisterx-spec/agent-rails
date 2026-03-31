---
name: run-tests-jest
description: Node.js + Jest / Vitest 测试执行规范。由 run-tests 路由器加载，或直接调用。
---

# Node.js / Jest (Vitest) 测试执行规范

> 适用框架：Jest（默认）、Vitest、Mocha + Chai
> 如项目使用 Vitest，将下文 `jest` / `npx jest` 替换为 `vitest` / `npx vitest`

## 前提条件

1. 测试框架已安装（`package.json` 中声明）
2. 测试环境变量已配置（`.env.test` 或 CI 环境变量）
3. 推荐配置 `jest.config.ts`（或 `vitest.config.ts`）集中管理测试行为

---

## 执行模式

### 模式一：快速子集（默认）

```bash
cd {{BACKEND_PATH}} && npm test -- --testPathPattern="unit|api" --forceExit
```

或使用 jest 的 tag 过滤（如项目配置了 `@group` 注释）：

```bash
cd {{BACKEND_PATH}} && npx jest --testNamePattern="(?!integration)" --forceExit
```

### 模式二：全量测试

```bash
cd {{BACKEND_PATH}} && npm test -- --forceExit --runInBand
```

> `--runInBand`：串行执行，适合有共享数据库状态的集成测试；
> 并行测试用 `--maxWorkers=4` 替代。

### 前端组件测试（如适用）

```bash
cd {{FRONTEND_PATH}} && npm test -- --watchAll=false --forceExit
```

---

## 进度报告格式

```
⏱ [0:15] Test Suites: 5/32 | Tests: 48 PASSED, 0 FAILED
⏱ [0:30] Test Suites: 18/32 | Tests: 156 PASSED, 2 FAILED
  🔴 FAIL src/services/auth.test.ts > should reject invalid token
✅ [1:20] Test Suites: 32/32 — 30 passed, 2 failed
```

---

## 结果判断

| 结果 | 处理 |
|------|------|
| 全部通过 | ✅ 继续 |
| 有 FAIL | 🔴 Blocker，必须修复 |
| 超时挂起 | 🔴 检查是否有未关闭的 DB 连接或 async 泄漏（缺少 `afterAll` 清理） |
| `Cannot find module` | 🔴 依赖或 tsconfig path 问题，立即暂停 |

---

## 常见问题速查

| 现象 | 根因 | 修复 |
|------|------|------|
| 测试挂起不退出 | DB 连接 / Timer 未清理 | 补 `afterAll(() => db.close())` |
| 并行测试数据冲突 | 共享测试数据 | 每个测试用独立 fixture 或加 `--runInBand` |
| `jest` 找不到 TS 文件 | 缺 `ts-jest` 或 `babel-jest` | 检查 `jest.config.ts → transform` |
| 覆盖率不更新 | 缓存旧数据 | 加 `--clearCache` 后重跑 |

---

## 测试分类约定（Jest 项目推荐）

使用文件命名约定区分测试类型：

| 文件名模式 | 类型 | 快速模式 |
|-----------|------|---------|
| `*.unit.test.ts` | 单元测试 | ✅ 跑 |
| `*.api.test.ts` | API 接口测试 | ✅ 跑 |
| `*.integration.test.ts` | 集成测试（真实 DB） | 上线前必跑 |
| `*.e2e.test.ts` | 端到端测试 | ❌ 独立流水线 |
