---
name: run-tests-pytest
description: Python + pytest 测试执行规范。由 run-tests 路由器加载，或直接调用。
---

# Python / pytest 测试执行规范

## 前提条件

1. `pytest` 已安装（`requirements-dev.txt` 或 `pyproject.toml` 中声明）
2. 测试数据库已配置（`project.config.json → testing.local_db_url`）
3. 推荐安装并行插件：`pytest-xdist`（`-n auto`），超时插件：`pytest-timeout`

**本地快速运行**：
```bash
export TEST_DATABASE_URL='{{LOCAL_DB_URL}}'
```
未设置时回退到 CI 数据库（速度慢，适合流水线）。

---

## 执行模式

### 模式一：快速子集（默认，上线前 / 日常开发）

```bash
# 先验证测试基线（如已初始化；失败必须阻断）
python .agents/scripts/test_lock.py verify

PYTHONPATH="{{BACKEND_PATH}}${PYTHONPATH:+:$PYTHONPATH}" \
TEST_DATABASE_URL='{{LOCAL_DB_URL}}' \
  python -m pytest {{TEST_PATH}} -m "{{FAST_MARK_EXPR}}" \
  -n auto --dist=loadfile -v --tb=short --timeout=30
```

> `{{TEST_PATH}}` 来自 `project.config.json → tech_stack.test_path`
> `{{FAST_MARK_EXPR}}` 由 `project.config.json → testing.fast_mode_exclude_marks` 派生；例如 `slow,performance` 转为 `not slow and not performance`。为空时删除整段 `-m "{{FAST_MARK_EXPR}}"`，不要保留空 marker。

**警告**：正式上线前（`/production-release`）不能排除 `integration` 集成测试。

### 模式二：全量测试

```bash
# 先验证测试基线（如已初始化；失败必须阻断）
python .agents/scripts/test_lock.py verify

PYTHONPATH="{{BACKEND_PATH}}${PYTHONPATH:+:$PYTHONPATH}" \
TEST_DATABASE_URL='{{LOCAL_DB_URL}}' \
  python -m pytest {{TEST_PATH}} \
  -n auto --dist=loadfile -v --tb=short --timeout=30
```

**默认使用模式一**，用户明确要求全量时才使用模式二。

---

## 进度报告格式

后台执行，每 20 秒轮询输出：

```
⏱ [0:20]  80/722 (11%) | ✅  80 PASSED | 🔴 0 FAILED
⏱ [0:40] 200/722 (28%) | ✅ 199 PASSED | 🔴 1 FAILED → test_auth::test_login
✅ [2:45] 完成 722/722 — 720 PASSED, 2 FAILED, 0 ERROR
```

---

## 结果判断

| 结果 | 处理 |
|------|------|
| 全部 `PASSED` | ✅ 继续 |
| 有 `FAILED` / `ERROR` | 🔴 Blocker，必须修复后才能提交/发版 |
| 有 `WARNING` | 🟡 记录，不阻断 |
| `ImportError` | 🔴 Blocker，依赖问题立即暂停 |

---

## 测试分类 mark（在 conftest.py 中注册）

| Mark | 含义 | 快速模式 |
|------|------|---------|
| `slow` | 执行时间 > 30s | ❌ 跳过 |
| `performance` | 性能基准测试 | ❌ 跳过 |
| `integration` | 依赖真实 DB / 外部服务 | 上线前必跑 |
| `api` | API 接口测试 | ✅ 跑 |
| 无标记 | 普通单元测试 | ✅ 跑 |
