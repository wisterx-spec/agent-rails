---
name: verify-spec
description: Extract acceptance criteria from a spec, classify each item, run automatic checks where possible, and return a structured verification report.
trigger: called by run-pending-specs after spec execution
---

# Verify Spec

## Input

Path to a completed `spec-*.md`.

## Step 1: Extract Acceptance Criteria

Read the `## Acceptance Criteria`, `## 验收标准`, or equivalent section.
List every unchecked item (`- [ ]`) as an acceptance criterion.

If no acceptance section exists, return:

```markdown
## Verification Results
- ○ No explicit acceptance criteria found; manual review required
```

## Step 2: Classify Each Criterion

| Type | Signals | Check |
|---|---|---|
| Test/build command | `npm run`, `pytest`, `pnpm`, `yarn`, `go test`, `cargo test`, `mvn test`, `build`, `lint` | Run command and inspect exit code |
| File content | `exists`, `contains`, `does not contain`, `不存在`, `包含`, `不出现` | Use `test`, `rg`, or equivalent |
| HTTP/API behavior | `status`, `redirect`, `returns`, `response`, `状态码`, `返回` | Use local curl/http client when endpoint is available |
| Database/schema artifact | `DDL`, `migration`, `ALTER TABLE`, `schema` | Check generated migration/DDL files or run the configured schema command |
| Browser/visual/manual | `browser`, `DevTools`, `Network`, `visual`, `screenshot`, `UX`, `浏览器`, `视觉` | Mark manual (`○`) |
| External service | third-party APIs, paid APIs, production-only services | Mark manual or mock-only (`○`) |

## Step 3: Repair Failed Automatic Checks

For each automatic check:

1. Run the check.
2. Mark `✓` if it passes.
3. If it fails, inspect the relevant files and fix implementation.
4. Re-run only the failing check.
5. Mark `✗→✓` if the repair succeeds.
6. After three failed repair attempts, return `✗` with the last error summary and request arbitration.

Do not rewrite the spec to make verification easier.
Do not weaken test assertions unless the spec explicitly says test expectations are still drafts.

## Step 4: Output

Return this exact shape for `run-pending-specs` to paste into the session:

```markdown
## Verification Results
- ✓ npm run build passed
- ✗→✓ API returned 500 first; fixed missing null guard; now returns 200
- ○ Visual layout requires browser review
```

Legend:

- `✓` automatic check passed.
- `✗→✓` automatic check failed, implementation was fixed, then passed.
- `✗` automatic check still fails and needs arbitration.
- `○` cannot be automatically verified in this environment.

