读取并严格执行 `.agents/workflows/dev-flow.md` 工作流。

前置要求：
1. 先读取 `project.config.json` 加载项目配置（遵循 `.agents/rules/core.md` 的配置加载协议）
2. 按 dev-flow 定义的 8 步闭合链逐步执行
3. 每步完成后等待人工确认再继续下一步
