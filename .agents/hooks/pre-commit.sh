#!/bin/bash
# ai-dev-workflow — pre-commit hook
# 安装路径：.git/hooks/pre-commit（由 install.sh 写入）
#
# 职责：拦截高危模式，作为 scan-code-hygiene AI 检查的兜底。
# 只检查 P0 级问题（可能导致安全事故的内容），P1 由 AI 层处理。

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

ERRORS=0

for FILE in $STAGED_FILES; do
  # 跳过二进制文件和 lock 文件
  case "$FILE" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.woff*|*.ttf|*.eot|*.lock|package-lock.json)
      continue ;;
  esac

  CONTENT=$(git show ":$FILE" 2>/dev/null) || continue

  # 检测硬编码密钥模式（password/secret/api_key 赋值为非空字符串）
  if echo "$CONTENT" | grep -qiE '(password|secret|api_key|apikey|private_key)\s*[=:]\s*["'"'"'][^"'"'"']{8,}["'"'"']'; then
    echo "[PRE-COMMIT BLOCKED] Possible hardcoded secret in: $FILE"
    ERRORS=$((ERRORS + 1))
  fi

  # 检测明显的 token / credential 硬编码
  if echo "$CONTENT" | grep -qE '(sk-[a-zA-Z0-9]{20,}|Bearer [a-zA-Z0-9._-]{20,}|ghp_[a-zA-Z0-9]{36})'; then
    echo "[PRE-COMMIT BLOCKED] Possible hardcoded token in: $FILE"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "提交被拦截：发现 $ERRORS 处高危内容，请修复后再提交。"
  echo "确认误报需要跳过时：git commit --no-verify（需人工确认安全）"
  exit 1
fi

exit 0
