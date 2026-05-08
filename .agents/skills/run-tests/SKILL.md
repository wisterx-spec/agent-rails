---
name: run-tests
description: 测试执行路由器。优先执行 project.config.json 中显式声明的测试命令；缺失时再根据 tech_stack 选择兜底规范。
---

# Run Tests — 路由器

触发形式：

- `/run-tests --mode=fast`
- `/run-tests --mode=full`

## 执行顺序

1. 读取 `project.config.json → testing.commands`。
2. `--mode=fast` 时优先执行 `testing.commands.fast`。
3. `--mode=full` 时优先执行 `testing.commands.full`。
4. 命令为空、缺失或仍是 `replace-with-*` 占位值时，才进入 tech_stack fallback。

**命令执行前必须先运行测试锁校验**：

```bash
python .agents/scripts/test_lock.py verify
```

`verify` 失败必须阻断；只有 `[SKIP] No lockfile found` 可以继续。

## Fallback 路由

读取 `project.config.json → tech_stack.backend` / `tech_stack.frontend`，加载对应的测试执行规范：

| 配置值 | 加载文件 |
|--------|---------|
| `python` / `python+fastapi` / `python+django` | `.agents/skills/run-tests/pytest.md` |
| `node` / `node+express` / `node+nestjs` | `.agents/skills/run-tests/jest.md` |
| `frontend` / `react` / `vue` / `svelte` | `.agents/skills/run-tests/jest.md` |
| 其他 | 不猜测命令；要求用户在 `testing.commands.fast/full` 中显式配置 |

**强制要求**：确定类型后，若存在对应规范文件，必须通过工具物理读取规范文件，不允许凭记忆执行。若无法路由，停止并提示补充 `testing.commands`，不要凭常识猜项目命令。
