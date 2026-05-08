#!/bin/bash
# Unified self-check for the agent-rails framework repository.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILED=0

section() {
  echo "==> $1"
}

mark_failed() {
  FAILED=1
}

section "Shell syntax"
bash -n scripts/check.sh
bash -n install.sh
bash -n .agents/hooks/pre-commit.sh

section "Python syntax"
python3 -m py_compile .agents/scripts/test_lock.py

section "Example config JSON"
python3 -m json.tool project.config.example.json >/tmp/agent-rails-project-config.json

section "Skill directory structure"
MISSING_SKILL=0
while IFS= read -r skill_dir; do
  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "missing SKILL.md: $skill_dir"
    MISSING_SKILL=1
  fi
done < <(find .agents/skills -mindepth 1 -maxdepth 1 -type d | sort)

SINGLE_FILE_SKILLS="$(find .agents/skills -mindepth 1 -maxdepth 1 -type f -name '*.md' ! -name '_SKILL_TEMPLATE.md' -print | sort)"
if [ -n "$SINGLE_FILE_SKILLS" ]; then
  echo "$SINGLE_FILE_SKILLS" | sed 's/^/single-file skill candidate: /'
  MISSING_SKILL=1
fi

if [ "$MISSING_SKILL" -ne 0 ]; then
  mark_failed
fi

section "Residual framework references"
FORBIDDEN_PATTERNS=(
  'proposal-review''\.md'
  'codex-''dispatch'
  'codex_''command'
  'codex_''dispatch_enabled'
  'test_lock\.py verify.*\|\| true'
  'FAST_''EXCLUDE_MARKS'
  'python -m pytest ''tests/'
  'tech_stack''\.frontend_test`'
  'frontend-ui''\.md'
  'project''\.profile'
  'run-tests/''java'
  '后端测试''验证'
  'models''\.py.*db''\.md'
)
RG_ARGS=()
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  RG_ARGS+=(-e "$pattern")
done
if rg -n -g '!*.svg' -g '!*.png' "${RG_ARGS[@]}" \
  .agents README.md README_zh.md docs project.config.example.json install.sh scripts; then
  mark_failed
fi

section "Documentation consistency"
python3 - <<'PY'
from pathlib import Path
import sys

workflow_names = sorted(path.stem for path in Path(".agents/workflows").glob("*.md"))
docs = [Path("README.md"), Path("README_zh.md"), Path(".agents/SKILL_INDEX.md")]
errors = []

for doc in docs:
    text = doc.read_text(encoding="utf-8")
    for name in workflow_names:
        if name not in text:
            errors.append(f"{doc}: missing workflow reference: {name}")

required_commands = {
    "README.md": ["/dev-flow", "/impact-analysis", "/weekly-report"],
    "README_zh.md": ["/dev-flow", "/impact-analysis", "/weekly-report"],
    ".agents/SKILL_INDEX.md": ["`git-lifecycle`", "/dev-flow", "/impact-analysis", "/weekly-report"],
}
for doc_name, commands in required_commands.items():
    text = Path(doc_name).read_text(encoding="utf-8")
    for command in commands:
        if command not in text:
            errors.append(f"{doc_name}: missing command/index reference: {command}")

stale_refs = {
    ".agents/workflows/pr-review.md": ["dev-flow` Step 8"],
    ".agents/workflows/production-release.md": ["run-backend-tests/SKILL.md"],
    ".agents/workflows/dev-flow.md": ["run-backend-tests`"],
    ".agents/workflows/git-lifecycle.md": ["run-backend-tests"],
}
for doc_name, needles in stale_refs.items():
    text = Path(doc_name).read_text(encoding="utf-8")
    for needle in needles:
        if needle in text:
            errors.append(f"{doc_name}: stale reference: {needle}")

if errors:
    print("\n".join(errors))
    sys.exit(1)
PY

section "Markdown internal links"
python3 - <<'PY'
from pathlib import Path
import re
import sys

root = Path.cwd()
files = []
for pattern in ("*.md", "docs/**/*.md", ".agents/**/*.md"):
    files.extend(p for p in root.glob(pattern) if p.is_file())

link_re = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
scheme_re = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")
missing = []

for path in sorted(set(files)):
    in_code = False
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        for match in link_re.finditer(line):
            raw = match.group(1).strip()
            target = raw.split("#", 1)[0].strip()
            if target.startswith("<") and target.endswith(">"):
                target = target[1:-1].strip()
            if not target:
                continue
            if target.startswith("#") or target.startswith("/"):
                continue
            if "{{" in target or "}}" in target:
                continue
            if scheme_re.match(target):
                continue
            candidate = (path.parent / target).resolve()
            if not candidate.exists():
                missing.append(f"{path.relative_to(root)}:{line_no}: {raw}")

if missing:
    print("\n".join(missing))
    sys.exit(1)
PY

section "Test lock smoke"
python3 .agents/scripts/test_lock.py verify

if [ "$FAILED" -ne 0 ]; then
  echo "check failed"
  exit 1
fi

echo "all checks passed"
