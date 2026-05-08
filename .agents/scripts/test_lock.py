#!/usr/bin/env python3
"""
test_lock.py — 测试基线防篡改工具

用法：
  python .agents/scripts/test_lock.py lock    # 锁定当前测试文件状态
  python .agents/scripts/test_lock.py verify  # 校验测试文件是否被篡改
  python .agents/scripts/test_lock.py status  # 查看锁定记录

设计意图：
  测试骨架一旦由人类确认，AI 在整个编码周期内严禁修改已有断言。
  此脚本通过对测试目录做 SHA-256 快照，检测测试文件的变更。

  verify 行为：
  - 已有文件 hash 变化（MODIFIED）→ 硬阻断，断言被篡改
  - 新增文件（ADDED）或删除文件（REMOVED）→ 警告，不阻断（开发中正常行为）
"""

import hashlib
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
LOCKFILE = ROOT / ".agent-testlock.json"

# 配置优先，缺失时回退到常见测试目录。
CONFIG_FILES = [ROOT / "project.config.json", ROOT / "project.config.example.json"]
DEFAULT_TEST_DIRS = ["backend/tests", "tests", "test", "src/__tests__", "src/test"]
TEST_FILE_PATTERNS = [
    "**/*.py",
    "**/*.test.ts",
    "**/*.test.tsx",
    "**/*.test.js",
    "**/*.test.jsx",
    "**/*.test.mjs",
    "**/*.spec.ts",
    "**/*.spec.tsx",
    "**/*.spec.js",
    "**/*.spec.jsx",
    "**/*.spec.mjs",
    "**/*.test.vue",
    "**/*.spec.vue",
]


def load_config() -> tuple[dict, Path | None]:
    for path in CONFIG_FILES:
        if not path.exists():
            continue
        try:
            return json.loads(path.read_text(encoding="utf-8")), path
        except json.JSONDecodeError as exc:
            print(f"[ERROR] Invalid JSON in {project_relative(path)}: {exc}")
            sys.exit(1)
    return {}, None


def project_relative(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return str(path)


def normalize_test_dirs() -> list[Path]:
    config, _ = load_config()
    tech_stack = config.get("tech_stack", {}) if isinstance(config, dict) else {}

    candidates = []
    for key in ("test_path", "frontend_test_path"):
        value = tech_stack.get(key)
        if isinstance(value, str) and value.strip():
            candidates.append(value.strip())
    candidates.extend(DEFAULT_TEST_DIRS)

    dirs = []
    seen = set()
    for raw in candidates:
        path = Path(raw)
        if not path.is_absolute():
            path = ROOT / path
        normalized = str(path.resolve())
        if normalized in seen:
            continue
        seen.add(normalized)
        dirs.append(path)
    return dirs


def find_test_dirs() -> list[Path]:
    return [path for path in normalize_test_dirs() if path.exists() and path.is_dir()]


def hash_file(path: Path) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha.update(chunk)
    return sha.hexdigest()


def collect_hashes(test_dirs: list[Path]) -> dict[str, str]:
    hashes = {}
    for test_dir in test_dirs:
        for pattern in TEST_FILE_PATTERNS:
            for f in sorted(test_dir.glob(pattern)):
                if f.is_file():
                    hashes[project_relative(f)] = hash_file(f)
    return hashes


def cmd_lock(test_dirs: list[Path]):
    hashes = collect_hashes(test_dirs)
    if not hashes:
        print(f"[WARN] No test files found in: {', '.join(project_relative(d) for d in test_dirs)}")
        sys.exit(1)

    data = {
        "locked_at": datetime.now(timezone.utc).isoformat(),
        "test_dirs": [project_relative(d) for d in test_dirs],
        "file_count": len(hashes),
        "hashes": hashes,
    }
    LOCKFILE.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    print(f"[LOCKED] {len(hashes)} test files in {', '.join(data['test_dirs'])}")
    print(f"         Lockfile: {project_relative(LOCKFILE)}")


def cmd_verify(test_dirs: list[Path]):
    if not LOCKFILE.exists():
        print("[SKIP] No lockfile found — test lock not initialized. Run 'lock' first.")
        sys.exit(0)

    data = json.loads(LOCKFILE.read_text(encoding="utf-8"))
    baseline = data["hashes"]
    current = collect_hashes(test_dirs)

    added = sorted(set(current) - set(baseline))
    removed = sorted(set(baseline) - set(current))
    modified = sorted(k for k in current if k in baseline and current[k] != baseline[k])

    if not added and not removed and not modified:
        print(f"[OK] All {len(baseline)} test files match the baseline.")
        sys.exit(0)

    if modified:
        print("[TAMPERED] Existing test assertions have been modified since last lock:")
        for f in modified:
            print(f"  MODIFIED  {f}")
        if added:
            for f in added:
                print(f"  ADDED     {f} (new file, ok — but assertions were also modified)")
        if removed:
            for f in removed:
                print(f"  REMOVED   {f}")
        print()
        print("Modified assertions violate the test contract.")
        print("Fix the implementation, not the test expectations.")
        sys.exit(1)

    # Only added/removed files, no existing assertions changed.
    if added or removed:
        print("[WARN] Test file set has changed, but no existing assertions were modified:")
        for f in added:
            print(f"  ADDED  {f}")
        for f in removed:
            print(f"  REMOVED {f}")
        print()
        print("New tests added or old tests removed — this is expected during development.")
        print("Run 'lock' again after review to update the baseline.")
        sys.exit(0)


def cmd_status():
    if not LOCKFILE.exists():
        print("[STATUS] No lockfile — test lock not initialized.")
        return
    data = json.loads(LOCKFILE.read_text(encoding="utf-8"))
    test_dirs = data.get("test_dirs") or [data.get("test_dir", "<unknown>")]
    print(f"[STATUS] Locked at : {data['locked_at']}")
    print(f"         Test dirs : {', '.join(test_dirs)}")
    print(f"         Files     : {data['file_count']}")


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("lock", "verify", "status"):
        print("Usage: python .agents/scripts/test_lock.py [lock|verify|status]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "status":
        cmd_status()
        return

    if cmd == "verify" and not LOCKFILE.exists():
        cmd_verify([])
        return

    test_dirs = find_test_dirs()
    if not test_dirs:
        searched = ", ".join(project_relative(path) for path in normalize_test_dirs())
        print(f"[ERROR] Could not find test directory. Searched: {searched}")
        print("        Set tech_stack.test_path / tech_stack.frontend_test_path in project.config.json.")
        sys.exit(1)

    if cmd == "lock":
        cmd_lock(test_dirs)
    elif cmd == "verify":
        cmd_verify(test_dirs)


if __name__ == "__main__":
    main()
