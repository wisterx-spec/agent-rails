---
name: run-pending-specs
description: Discover pending implementation specs, execute them in dependency order, verify acceptance criteria, archive the spec, and write a session signal for Dream.
trigger: manual | called by spec handoff
---

# Run Pending Specs

## Purpose

This skill turns a reviewed implementation spec into an executable handoff.
It is designed for a planner/executor split:

- Planner writes a structured `spec-*.md`.
- Executor reads and implements the spec.
- Executor writes `session-*.md`.
- Dream later reads the session as the durable signal of what actually happened.

No project-specific business rules belong in this skill. Project rules must come from
`project.config.json`, `docs/conventions.md`, `docs/lessons/`, and the spec itself.

## Paths

Read `project.config.json` first. Use these defaults when fields are missing:

| Config field | Default | Meaning |
|---|---|---|
| `agent.signal_dir` | `tmp/agent-signals` | Live specs, sessions, prereviews, incidents |
| `agent.delivery_dir` | `docs/agent-runs/delivery` | Archived spec/session/prereview bundles |
| `agent.management_dir` | `docs/agent-runs/management` | Dream and Analyzer management output |

Create `agent.signal_dir` and `agent.delivery_dir` if they do not exist.

## File Contract

| File pattern | Meaning |
|---|---|
| `{signal_dir}/spec-{slug}-{YYYYMMDD_HHMMSS}.md` | Planner-authored implementation spec |
| `{signal_dir}/prereview-{slug}-{YYYYMMDD_HHMMSS}.md` | Executor feasibility review before implementation |
| `{signal_dir}/session-{slug}-{YYYYMMDD_HHMMSS}.md` | Executor completion summary and Dream signal |
| `{signal_dir}/arbitration-{slug}-{YYYYMMDD_HHMMSS}.md` | Manual arbitration request after repeated verification failure |

Slug extraction removes the `spec-` prefix and a trailing `-YYYYMMDD_HHMMSS.md` timestamp.

## Required Spec Metadata

Each spec should include these machine-readable fields near the top:

```markdown
**depends-on**: none
**parallel-ok**: false
**work-dir**: /absolute/path/to/project
**test-command**: npm test
```

If `work-dir` is absent, use the current repository root.
If `test-command` is absent, follow the commands written inside each task or in `## Acceptance Criteria`.

## Step 1: Scan Pending Specs

Use `find`, not shell globs, so empty directories do not produce shell errors:

```bash
SIGNAL_DIR="${SIGNAL_DIR:-tmp/agent-signals}"
find "$SIGNAL_DIR" -maxdepth 1 -name "spec-*.md" -type f 2>/dev/null | sort
```

For each spec:

1. Extract slug.
2. Look for any matching `session-{slug}-*.md` in `signal_dir`.
3. Mark as `DONE` if a session exists, otherwise `PENDING`.

No pending spec means exit with: `All specs completed.`

## Step 2: Select Execution Order

For all pending specs:

1. Read `**depends-on**`.
2. A dependency is satisfied when `session-{depends-on}-*.md` exists in `signal_dir` or in `delivery_dir/{depends-on}/session.md`.
3. Execute serial specs first.
4. Only run `parallel-ok: true` specs in parallel when the execution environment explicitly supports independent workers.

If dependency metadata is missing, treat it as `depends-on: none` and `parallel-ok: false`.

## Step 3: Prereview

Before editing code, read the full target spec and write:

```markdown
## Prereview - {slug} - {timestamp}

**Executor feasibility review**: identifies execution blockers only. It does not redesign the spec.

### Unclear Items
- None

### Suspected Contradictions
- None

### Execution Risks
- None

### Decision
- [ ] No blockers, proceed
```

Rules:

- If `Unclear Items` or `Suspected Contradictions` is not `None`, pause for planner clarification.
- If only `Execution Risks` exist, continue and let Dream review them later.
- Do not edit the spec file.

## Step 4: Execute The Spec

Use the spec as the source of truth:

1. Read every file listed under "must read", "involved files", or equivalent sections.
2. Implement tasks in the order specified by the spec.
3. After each task, run the task's stated verification command if present.
4. Do not modify locked test expectations to make implementation pass.
5. Put scratch scripts and diagnostic output under the configured temp directory.

## Step 5: Verify Acceptance

After implementation, invoke `.agents/skills/verify-spec/SKILL.md` against the current spec.

If verification returns failures:

1. Fix implementation.
2. Re-run the failing check.
3. Stop after three failed repair attempts for the same acceptance item.
4. Write `arbitration-{slug}-{timestamp}.md` and pause.

## Step 6: Archive And Write Session

Archive into `delivery_dir/{slug}/`:

- `spec.md`
- `prereview.md` if present
- `session.md` after writing it

Write the live session to `signal_dir` first so Dream can consume it:

```markdown
## Spec
- {original spec path}
- Archived: {delivery_dir}/{slug}/spec.md

## Completed Tasks
- Task A: {files changed and behavior delivered}

## Verification Results
- {paste verify-spec output: ✓ / ✗→✓ / ○}

## Problems Encountered
- None

## Deviations From Spec
- Fully followed the spec

## Dream Candidates
- None
```

The session is the durable signal. If no session is written, Dream must treat the execution as invisible.
