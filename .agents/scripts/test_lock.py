#!/usr/bin/env python3
"""
test_lock.py — 测试基线防篡改工具

用法：
  python .agents/scripts/test_lock.py lock    # 锁定当前测试文件状态
  python .agents/scripts/test_lock.py verify  # 校验测试文件是否被篡改
  python .agents/scripts/test_lock.py status  # 查看锁定记录

设计意图：
  测试骨架一旦由人类确认，AI 在整个编码周期内严禁修改断言。
  此脚本通过对测试目录做 SHA-256 快照，检测任何未经授权的测试文件变更。
"""

import hashlib
import json
import sys
import os
from pathlib import Path
from datetime import datetime, timezone

LOCKFILE = Path(".agent-testlock.json")

# 自动检测测试目录（按优先级）
TEST_DIRS = ["backend/tests", "tests", "test", "src/__tests__", "src/test"]


def find_test_dir() -> Path | None:
    for d in TEST_DIRS:
        p = Path(d)
        if p.exists() and p.is_dir():
            return p
    return None


def hash_file(path: Path) -> str:
    sha = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            sha.update(chunk)
    return sha.hexdigest()


def collect_hashes(test_dir: Path) -> dict[str, str]:
    hashes = {}
    patterns = ["**/*.py", "**/*.test.ts", "**/*.test.tsx", "**/*.spec.ts", "**/*.spec.tsx",
                "**/*.test.js", "**/*.spec.js"]
    for pattern in patterns:
        for f in sorted(test_dir.glob(pattern)):
            if f.is_file():
                rel = str(f.relative_to(Path(".")))
                hashes[rel] = hash_file(f)
    return hashes


def cmd_lock(test_dir: Path):
    hashes = collect_hashes(test_dir)
    if not hashes:
        print(f"[WARN] No test files found in {test_dir}")
        sys.exit(1)

    data = {
        "locked_at": datetime.now(timezone.utc).isoformat(),
        "test_dir": str(test_dir),
        "file_count": len(hashes),
        "hashes": hashes,
    }
    LOCKFILE.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    print(f"[LOCKED] {len(hashes)} test files in {test_dir}")
    print(f"         Lockfile: {LOCKFILE}")


def cmd_verify(test_dir: Path):
    if not LOCKFILE.exists():
        print("[SKIP] No lockfile found — test lock not initialized. Run 'lock' first.")
        sys.exit(0)

    data = json.loads(LOCKFILE.read_text())
    baseline = data["hashes"]
    current = collect_hashes(test_dir)

    added = sorted(set(current) - set(baseline))
    removed = sorted(set(baseline) - set(current))
    modified = sorted(k for k in current if k in baseline and current[k] != baseline[k])

    if not added and not removed and not modified:
        print(f"[OK] All {len(baseline)} test files match the baseline.")
        sys.exit(0)

    print("[TAMPERED] Test file changes detected since last lock:")
    for f in modified:
        print(f"  MODIFIED  {f}")
    for f in added:
        print(f"  ADDED     {f}")
    for f in removed:
        print(f"  REMOVED   {f}")
    print()
    print("If these changes are intentional (new tests, not modified assertions),")
    print("run 'lock' again to update the baseline.")
    print("If assertions were modified to make tests pass, that violates the test contract.")
    sys.exit(1)


def cmd_status():
    if not LOCKFILE.exists():
        print("[STATUS] No lockfile — test lock not initialized.")
        return
    data = json.loads(LOCKFILE.read_text())
    print(f"[STATUS] Locked at : {data['locked_at']}")
    print(f"         Test dir  : {data['test_dir']}")
    print(f"         Files     : {data['file_count']}")


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("lock", "verify", "status"):
        print("Usage: python .agents/scripts/test_lock.py [lock|verify|status]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "status":
        cmd_status()
        return

    test_dir = find_test_dir()
    if test_dir is None:
        print(f"[ERROR] Could not find test directory. Searched: {TEST_DIRS}")
        print("        Set the correct path in TEST_DIRS at the top of this script.")
        sys.exit(1)

    if cmd == "lock":
        cmd_lock(test_dir)
    elif cmd == "verify":
        cmd_verify(test_dir)


if __name__ == "__main__":
    main()
