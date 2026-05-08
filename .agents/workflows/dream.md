---
description: Evidence-based memory consolidation workflow. Reads structured execution signals, updates lessons and LLM context, and creates workflow-improvement candidates.
trigger: manual (/dream) | scheduled
---

# Dream: Memory Consolidation Workflow

## Purpose

Dream converts execution evidence into durable project memory.
It reads structured signals such as `session-*.md`, `prereview-*.md`, and `incident-*.md`.
It does not scan raw source code to invent lessons.

## Paths

Read `project.config.json` and use defaults when fields are missing:

| Config field | Default |
|---|---|
| `agent.signal_dir` | `tmp/agent-signals` |
| `agent.delivery_dir` | `docs/agent-runs/delivery` |
| `agent.management_dir` | `docs/agent-runs/management` |
| `llm_context.core_doc` | `docs/llm-context/llms-core.txt` |
| `llm_context.backend_doc` | `docs/llm-context/llms-domain-backend.txt` |
| `llm_context.frontend_doc` | `docs/llm-context/llms-domain-frontend.txt` |

Create missing directories before writing.

## Step 1: Determine Scan Window

Use `{management_dir}/.last_dream_ts` as the sentinel.

```bash
cat {management_dir}/.last_dream_ts 2>/dev/null || echo "1970-01-01T00:00:00Z"
cp {management_dir}/.last_dream_ts {management_dir}/.last_dream_ts.prev 2>/dev/null || true
```

Collect files newer than the previous sentinel:

- `{signal_dir}/session-*.md`
- `{signal_dir}/prereview-*.md`
- `{signal_dir}/incident-*.md`
- `{delivery_dir}/*/spec.md`

If no new signal files exist, update the sentinel, append a dream-log entry saying no signal was found, and exit.

## Step 2: Read Signals

Priority:

| Source | Priority | Meaning |
|---|---|---|
| `incident-*.md` | Highest | Production or release incident |
| `session-*.md` | High | What the executor actually changed and verified |
| `prereview-*.md` | Medium | Ambiguity or execution-risk signal before implementation |
| Archived `spec.md` | Medium | Planner intent and rationale |

Use spec/session comparison when possible:

- If a session records `Deviations From Spec`, read the matching archived spec.
- If prereview concerns later appear under `Problems Encountered`, treat it as a workflow-improvement signal.

## Step 3: Extract Candidates

Candidate types:

- Guardrail candidate: repeated failure, production incident, or clear "do not do this again" lesson.
- Positive pattern candidate: a pattern with repeated successful use.
- Workflow-improvement candidate: spec format, skill logic, toolchain, or handoff issue.

Write workflow candidates to `{management_dir}/workflow-optimization-candidates-{YYYYMMDD}.md` only when at least one exists:

```markdown
# Workflow Optimization Candidates - {date}

### {pattern title}
- Count: {n}
- Evidence: {session/prereview/spec paths}
- Impact layer: {spec-format / skill-logic / toolchain / flow-handoff}
- Observed problem: {specific behavior}
- Suggested direction: {what kind of workflow change may help}
```

## Step 4: Evidence Gate

Before writing lessons or LLM context, each candidate must pass:

1. Concrete evidence points to a file, function, test, session, prereview, or incident.
2. The claim is observed, not inferred from general experience.
3. Existing `docs/lessons/` does not already cover it after duplicate normalization.
4. Guardrail candidates include symptom, root cause, and prevention.
5. Positive patterns have at least two successful uses or explicit production validation.

Discard weak candidates and mention them in the dream log as "insufficient evidence".

## Step 5: Write Memory

Dream is allowed to update these files after the evidence gate:

- `docs/lessons/backend.md`
- `docs/lessons/frontend.md`
- `docs/lessons/testing.md`
- configured `docs/llm-context/*.txt`
- `{management_dir}/dream-log.md`

Do not modify `.agents/rules/*`.
Rules are the stable contract and require human edits.

Lesson format:

```markdown
### [Area] Title (YYYY-MM-DD)
**Severity**: P0/P1/P2
**Symptoms**: ...
**Root Cause**: ...
**Prevention Rule**: ...
**Evidence**: {signal/spec/test/file paths}
```

### Write Rules

Lessons are append-only:

1. Do not delete, reorder, or rewrite existing lesson entries during `/dream`.
2. Build a duplicate key from normalized title, root cause, and prevention rule. Normalization means lowercase, remove date stamps, collapse whitespace, and ignore punctuation.
3. If a candidate matches an existing lesson on at least two of title/root-cause/prevention, do not create a new entry. Append only:

```markdown
**Additional Evidence (YYYY-MM-DD)**: {signal/spec/test/file paths} — {one-line observation}
```

4. If the duplicate location is ambiguous, do not write the lesson. Log it as `duplicate-ambiguous` in `{management_dir}/dream-log.md`.
5. Replace `_（暂无记录）_` only when adding the first real entry under that section.

LLM context files are compact rewrites:

1. Read existing context first, then merge accepted candidates.
2. De-duplicate by normalized bullet body, ignoring priority tags, dates, and evidence suffixes.
3. Use one line per item: `- [P1][area] Rule or invariant — evidence: path`.
4. Keep priority order: P0 incidents, recurring P1 failures, active workflow invariants, production-validated positive patterns, then low-risk reminders.
5. Enforce `llm_context.max_lines.core` and `llm_context.max_lines.domain`. If over limit, drop lower-priority items first; for same priority, keep newer or better-evidenced items.
6. Write atomically: create a temp file in `tmp/`, then move it over the target after content is complete.
7. Every changed memory file and its evidence paths must be listed in the dream log.

## Step 6: Escrow Promotion And Analyzer Health

If `{management_dir}/proposals-escrow-*.md` exists:

1. Compare Escrow proposals with current workflow candidates using `.agents/rules/propose-wi-constitution.md` I-7.
2. If the same signal recurs, promote the proposal to `{management_dir}/proposals-actionable-{YYYYMMDD}.md`.
3. If the signal does not recur, mark it expired and archive it under `{delivery_dir}/workflow-proposals/`.

Read `{management_dir}/proposals-status.md` defensively:

- Missing file means cold start.
- Bad format means skip rate calculation.
- Repeated unhealthy rates can write `{management_dir}/analyzer-freeze.md`.

## Step 7: Archive Consumed Signals

Copy processed `session-*.md` and `prereview-*.md` into `{delivery_dir}/{slug}/`.
Do not delete live signal files unless the project has an explicit retention policy.

## Step 8: Log

Append `{management_dir}/dream-log.md`:

```markdown
## [{YYYY-MM-DD HH:mm}] Dream
- Scan window: {previous} -> {current}
- Signal files: sessions {n}, prereviews {n}, incidents {n}, specs {n}
- Lessons updated: {n}
- LLM context updated: {n}
- Workflow candidates: {n}
- Escrow promoted: {n}
- Analyzer health: normal / warning / frozen / cold start
- Next expected: {timestamp or manual}
```
