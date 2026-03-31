---
name: run-tests
description: 测试执行路由器。根据 project.config.json → tech_stack.backend 自动分发到对应测试技能。
---

# Run Tests — 路由器

读取 `project.config.json → tech_stack.backend`，加载对应的测试执行规范：

| 配置值 | 加载文件 |
|--------|---------|
| `python` / `python+fastapi` / `python+django` | `.agents/skills/run-tests/pytest.md` |
| `node` / `node+express` / `node+nestjs` | `.agents/skills/run-tests/jest.md` |
| `go` | 暂未提供，使用 `go test ./...` |
| `java` / `java+spring` | 暂未提供，使用 `mvn test` 或 `gradle test` |

**强制要求**：确定后端类型后，必须通过工具物理读取对应规范文件，不允许凭记忆执行。

> 向后兼容：旧版 `.agents/skills/run-backend-tests/SKILL.md` 仍可使用，
> 内容等价于 `pytest.md`，新项目推荐直接使用本路由器。
