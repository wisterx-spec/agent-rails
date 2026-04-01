读取并严格执行 `.agents/workflows/pr-review.md` 工作流。

执行两步：
1. 调用 `generate-pr-description` skill 生成 PR 描述
2. 调用 `pr-self-review` skill 进行代码质量/规范/安全/测试四维度自检

$ARGUMENTS
