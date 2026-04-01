读取并严格执行 `.agents/workflows/auto-dev.md` 工作流。

用户输入格式：`/auto-dev [TODO内容]` 或 `/auto-dev resume`

前置要求：
1. 先读取 `project.config.json` 加载项目配置
2. 如果用户输入 `resume`，执行会话恢复协议（读取 `tmp/.agent-session.md`）
3. 如果输入的是模糊需求，先触发 `requirement-clarification` 工作流
4. 按 auto-dev 的 5 个阶段严格执行

$ARGUMENTS
