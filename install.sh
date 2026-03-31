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

# ── 7. 创建 docs/ 知识库骨架（如不存在）──────────────────────
TARGET_DOCS="$TARGET/docs"
SRC_DOCS="$SCRIPT_DIR/docs"

if [ ! -f "$TARGET_DOCS/INDEX.md" ]; then
  mkdir -p "$TARGET_DOCS/lessons"
  cp "$SRC_DOCS/INDEX.md" "$TARGET_DOCS/INDEX.md"
  echo "  [+] Created docs/INDEX.md"
else
  echo "  [=] docs/INDEX.md already exists, skipping."
fi

for lesson in backend frontend testing; do
  DEST="$TARGET_DOCS/lessons/${lesson}.md"
  if [ ! -f "$DEST" ]; then
    cp "$SRC_DOCS/lessons/${lesson}.md" "$DEST"
    echo "  [+] Created docs/lessons/${lesson}.md"
  else
    echo "  [=] docs/lessons/${lesson}.md already exists, skipping."
  fi
done

# ── 8. 创建 docs/conventions.md（活的约定文档）──────────────────
CONVENTIONS_FILE="$TARGET_DOCS/conventions.md"
if [ ! -f "$CONVENTIONS_FILE" ]; then
  cp "$SRC_DOCS/conventions.md" "$CONVENTIONS_FILE"
  echo "  [+] Created docs/conventions.md"
else
  echo "  [=] docs/conventions.md already exists, skipping."
fi

# ── 9. 创建 docs/decisions/ 架构决策记录骨架 ──────────────────
DECISIONS_DIR="$TARGET_DOCS/decisions"
if [ ! -d "$DECISIONS_DIR" ]; then
  mkdir -p "$DECISIONS_DIR"
  cp "$SRC_DOCS/decisions/README.md" "$DECISIONS_DIR/README.md"
  cp "$SRC_DOCS/decisions/_template.md" "$DECISIONS_DIR/_template.md"
  echo "  [+] Created docs/decisions/ with README.md and _template.md"
else
  echo "  [=] docs/decisions/ already exists, skipping."
fi

# ── 10. 安装 pre-commit git hook ─────────────────────────────
GIT_DIR="$TARGET/.git"
HOOK_SRC="$SCRIPT_DIR/.agents/hooks/pre-commit.sh"
HOOK_DEST="$GIT_DIR/hooks/pre-commit"

if [ -d "$GIT_DIR" ]; then
  if [ ! -f "$HOOK_DEST" ]; then
    cp "$HOOK_SRC" "$HOOK_DEST"
    chmod +x "$HOOK_DEST"
    echo "  [+] Installed pre-commit hook (.git/hooks/pre-commit)"
  else
    echo "  [!] pre-commit hook already exists, skipping."
    echo "      To update manually: cp $HOOK_SRC $HOOK_DEST && chmod +x $HOOK_DEST"
  fi
else
  echo "  [!] No .git directory found, skipping pre-commit hook installation."
fi

# ── 11. 提示合并 CLAUDE.md ────────────────────────────────
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
echo "  3. Edit docs/INDEX.md with your project overview"
echo "  4. Update .agents/workflows/production-release.md with your deploy platform"
echo "  5. Start a new feature with: /dev-flow or /auto-dev [TODO]"
echo "  6. Emergency fix: /hotfix [problem description]"
echo ""
