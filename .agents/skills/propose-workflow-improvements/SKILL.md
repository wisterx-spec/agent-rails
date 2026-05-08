---
name: propose-workflow-improvements
description: Convert Dream workflow-optimization candidates into evidence-backed Escrow proposals using a fixed Observer/Analyzer split.
trigger: manual | after Dream writes workflow-optimization-candidates
---

# Propose Workflow Improvements

## Architecture

| Phase | Responsibility | Mutability |
|---|---|---|
| Observer | Collect and normalize raw signals | Stable; change only by direct human edit |
| Analyzer | Group patterns, filter by constitution, write Escrow proposals | Evolves through reviewed workflow changes |

Analyzer reads only the Observer snapshot. It must not directly reinterpret raw files after the snapshot is written.

## Paths

Read `project.config.json` and use:

- `agent.signal_dir` default `tmp/agent-signals`
- `agent.management_dir` default `docs/agent-runs/management`
- `agent.delivery_dir` default `docs/agent-runs/delivery`

Before running, check for an Analyzer freeze:

```bash
test -f {management_dir}/analyzer-freeze.md \
  && ! rg -q "manual review complete, resume" {management_dir}/analyzer-freeze.md \
  && echo "[FROZEN] Analyzer is frozen until manual review resumes it"
```

## Phase 1: Observer Snapshot

Collect:

- Latest `{management_dir}/workflow-optimization-candidates-*.md`
- Historical candidates under `{management_dir}` and `{delivery_dir}`
- Historical proposals and Escrow files
- `{management_dir}/proposals-status.md` if present
- Matching `session-*.md` and `prereview-*.md` evidence from `agent.signal_dir`

Write:

```markdown
## Observer Snapshot - {timestamp}

### Current Candidates
{latest candidates content}

### Historical Candidate Summary
- {title} - first {date}, latest {date}, count {n}

### Historical Proposal Summary
- {title} - status {implemented/not implemented/partial}, effect {resolved/unresolved/unknown}

### Evidence Summary
- {slug}: session {path}, prereview {path or none}
```

## Phase 2: Analyzer

Use `.agents/rules/propose-wi-constitution.md`.

For each candidate:

1. Assign one impact layer: `spec-format`, `skill-logic`, `toolchain`, or `flow-handoff`.
2. Confirm direct evidence exists in a session or prereview file.
3. Group with historical candidates using the constitution's similarity rule.
4. Mark as first occurrence, recurrence, or likely resolved.
5. Drop anything that violates the constitution.

## Output: Escrow Proposal

Write `{management_dir}/proposals-escrow-{YYYYMMDD}.md`:

```markdown
# Workflow Improvement Proposals (Escrow) - {date}

**Status**: pending Dream confirmation before becoming Actionable
**Based on**: workflow-optimization-candidates-{date}.md

### Proposal N: {title}

**Impact layer**: {spec-format / skill-logic / toolchain / flow-handoff}
**History**: first occurrence / recurrence / likely resolved
**Evidence**: {session/prereview paths}
**Observed problem**: {specific behavior}
**Root cause**: {why the workflow allowed it}
**Suggested change**:
- File: {path}
- Change: {paragraph-level edit}
**Expected effect**: {what stops recurring}
**Review focus**: {what a human should verify}

## Filtered By Constitution
- {title}: violates I-{n}; {reason}

## Manual Review Needed
- {title}: suspected Observer change; human decision required

## Low Priority
- {title}: likely resolved; continue watching
```

Append a confidence report with counts for total candidates, Escrow entries, filtered entries, and unresolved Actionable items.

