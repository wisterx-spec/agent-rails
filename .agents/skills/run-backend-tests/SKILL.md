---
name: run-backend-tests
description: 执行后端测试套件。用于上线前验证、代码瘦身后回归、或显式要求运行测试时。
---

# 后端测试执行规范

## 使用场景

- **上线前验证**（`/production-release` Workflow 调用）
- **代码瘦身后回归**（slim 相关 Skill 调用）
- **用户手动触发**：提及"跑测试"、"run tests"、"验证后端"

---

## 前提条件

1. 测试框架（pytest 或项目使用的框架）已安装
2. 测试数据库已配置（见 `project.config.json → testing.local_db_url`）
3. 如需并行执行，确认并行依赖已安装

**本地快速运行（推荐）**：把本地数据库地址设为环境变量：
```bash
export TEST_DATABASE_URL='{{project.config.json → testing.local_db_url}}'
```
未设置时回退到 CI 数据库（速度慢，适合 CI/CD）。

---

## 执行模式

### 模式一：快速子集（上线前 / 瘦身后回归）——默认模式

排除慢测、性能测试，保留核心逻辑：
```bash
# 快速执行示例（根据项目调整路径和 exclude marks）
cd {{BACKEND_PATH}} && TEST_DATABASE_URL='{{LOCAL_DB_URL}}' \
  python -m pytest tests/ -m "not slow and not performance"
```

> `{{BACKEND_PATH}}` 来自 `project.config.json → tech_stack.backend_path`
> `{{LOCAL_DB_URL}}` 来自 `project.config.json → testing.local_db_url`
> exclude marks 来自 `project.config.json → testing.fast_mode_exclude_marks`

**警告：正式上线前（/production-release）不能排除 integration 集成测试，必须让真实 DB 连接测试跑通！**

### 模式二：全量测试（标准验证）

```bash
cd {{BACKEND_PATH}} && TEST_DATABASE_URL='{{LOCAL_DB_URL}}' \
  python -m pytest tests/
```

**默认使用模式一**，除非用户明确要求全量。

---

## 进度报告格式

使用后台执行模式，每 20 秒轮询一次输出，实时向用户报告：

```
⏱ [0:20] 已完成  80/722 (11.1%) | ✅  80 PASSED | 🔴 0 FAILED
⏱ [0:40] 已完成 200/722 (27.7%) | ✅ 199 PASSED | 🔴 1 FAILED → test_xxx::test_yyy
⏱ [1:00] 已完成 360/722 (49.9%) | ✅ 358 PASSED | 🔴 2 FAILED
✅ [2:45] 完成 722/722 — 720 PASSED, 2 FAILED, 0 ERROR
```

---

## 结果判断规则

| 结果 | 处理方式 |
|------|---------|
| 全部 `PASSED` | ✅ 测试通过，继续后续步骤 |
| 有 `FAILED` 或 `ERROR` | 🔴 Blocker：报告失败用例，**必须修复后才能继续** |
| 有 `WARNING` | 🟡 记录，不阻断 |
| `ImportError` 导入失败 | 🔴 Blocker：依赖问题，立即暂停 |

---

## 测试分类说明（按 mark）

在 `conftest.py` 中注册以下 mark，快速模式跳过前两个：

| Mark | 含义 | 快速模式是否跑 |
|------|------|--------------|
| `slow` | 执行时间长的测试 | ❌ 跳过 |
| `performance` | 性能基准测试 | ❌ 跳过 |
| `integration` | 依赖真实 DB / 外部服务 | 正式上线前必跑 |
| `api` | API 接口测试 | ✅ 跑 |
| （无标记） | 普通单元测试 | ✅ 跑 |

---

## 测试锁定验证

如果项目使用了测试基线锁（`test_lock.py`），在执行测试前先验证：
```bash
python .agents/scripts/test_lock.py verify
```
若基线被篡改，立即报警并终止。
