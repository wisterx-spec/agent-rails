#!/bin/bash
# ai-dev-workflow installer
# Usage: ./install.sh [target-project-path]
# If no path given, installs in current directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-$(pwd)}"

echo "==> Installing ai-dev-workflow into: $TARGET"

# ── 1. 确认目标目录存在 ──────────────────────────────────
if [ ! -d "$TARGET" ]; then
  echo "Error: Target directory '$TARGET' does not exist."
  exit 1
fi

# ── 2. 复制 .agents/ 目录 ───────────────────────────────
if [ -d "$TARGET/.agents" ]; then
  echo "  [!] .agents/ already exists in target. Skipping to avoid overwrite."
  echo "      If you want to update, manually merge from: $SCRIPT_DIR/.agents/"
else
  cp -r "$SCRIPT_DIR/.agents" "$TARGET/.agents"
  echo "  [+] Copied .agents/ to $TARGET/"
fi

# ── 3. 创建 tmp/ 目录（如不存在）──────────────────────────
mkdir -p "$TARGET/tmp"
echo "  [+] Ensured tmp/ directory exists"

# ── 4. 添加 tmp/ 到 .gitignore ───────────────────────────
GITIGNORE="$TARGET/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "^tmp/" "$GITIGNORE" 2>/dev/null; then
    echo "tmp/" >> "$GITIGNORE"
    echo "  [+] Added tmp/ to .gitignore"
  else
    echo "  [=] tmp/ already in .gitignore"
  fi
else
  echo "tmp/" > "$GITIGNORE"
  echo "  [+] Created .gitignore with tmp/"
fi

# ── 5. 复制 project.config.example.json（如目标不存在配置）──
CONFIG="$TARGET/project.config.json"
EXAMPLE="$SCRIPT_DIR/project.config.example.json"
if [ ! -f "$CONFIG" ]; then
  cp "$EXAMPLE" "$CONFIG"
  echo "  [+] Copied project.config.json (from example)"
  echo ""
  echo "  >>> ACTION REQUIRED: Edit $CONFIG and fill in your project-specific values."
else
  echo "  [=] project.config.json already exists, skipping."
fi

# ── 6. 将 project.config.json 加入 .gitignore ─────────────
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "^project.config.json" "$GITIGNORE" 2>/dev/null; then
    echo "project.config.json" >> "$GITIGNORE"
    echo "  [+] Added project.config.json to .gitignore (contains local paths)"
  fi
fi

# ── 7. 提示合并 CLAUDE.md ────────────────────────────────
TARGET_CLAUDE="$TARGET/CLAUDE.md"
SRC_CLAUDE="$SCRIPT_DIR/CLAUDE.md"
echo ""
if [ -f "$TARGET_CLAUDE" ]; then
  echo "  [!] CLAUDE.md already exists in target."
  echo "      Please manually merge the relevant sections from:"
  echo "      $SRC_CLAUDE"
else
  cp "$SRC_CLAUDE" "$TARGET_CLAUDE"
  echo "  [+] Copied CLAUDE.md to $TARGET/"
fi

# ── 完成 ─────────────────────────────────────────────────
echo ""
echo "==> Installation complete."
echo ""
echo "Next steps:"
echo "  1. Edit $CONFIG with your project's paths, DB URL, and deploy settings"
echo "  2. Review .agents/rules/ and customize constraints for your stack"
echo "  3. Update .agents/workflows/production-release.md with your deploy platform"
echo "  4. Start a new feature with: /dev-flow or /auto-dev [TODO]"
echo ""
