读取并严格执行 `.agents/workflows/hotfix.md` 工作流。

用于生产紧急修复（P0 专用精简流程）。
跳过大部分常规步骤，直接进入：定位 → 修复 → 测试 → 提交 → 发布。

前置要求：先读取 `project.config.json` 加载项目配置。

$ARGUMENTS
