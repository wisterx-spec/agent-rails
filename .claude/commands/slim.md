读取并严格执行 `.agents/workflows/slim.md` 工作流。

项目瘦身流程：
1. scan-orphan-components — 扫描孤儿组件
2. scan-dead-routes — 扫描死路由
3. scan-unused-exports — 扫描未引用导出
4. scan-bundle-bloat — 扫描重型依赖
5. 生成删除提案（P0/P1/P2），人工确认后逐个删除
6. 全量测试验证

前置要求：先读取 `project.config.json` 加载项目配置。
