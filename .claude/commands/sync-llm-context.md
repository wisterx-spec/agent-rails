读取并严格执行 `.agents/skills/sync-llm-context/SKILL.md`。

全局扫描工程最新状态，提取陷阱禁区、依赖入口和开发命令，增量更新 LLM 上下文地图文件。

前置要求：先读取 `project.config.json` 获取 `llm_context` 配置。
