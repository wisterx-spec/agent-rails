读取并严格执行 `.agents/workflows/production-release.md` 工作流。

发版上线前的完整检查流程：代码卫生扫描 → 测试验证 → 数据库迁移审计 → 前端质量扫描（可选）→ 打 tag → 部署。

前置要求：先读取 `project.config.json` 加载项目配置。
