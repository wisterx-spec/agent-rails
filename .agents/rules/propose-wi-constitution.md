# Propose Workflow Improvements Constitution

**Status**: frozen. Human edits only.
**Version**: v1.0

This file constrains `.agents/skills/propose-workflow-improvements/SKILL.md`.
Analyzer output that violates these invariants must be filtered out.

## Invariants

### I-1: Fixed Impact Layers

Every proposal must use exactly one of these layer identifiers:

| Layer | Identifier |
|---|---|
| Spec format | `spec-format` |
| Skill logic | `skill-logic` |
| Toolchain | `toolchain` |
| Flow handoff | `flow-handoff` |

### I-2: Direct Evidence Required

Every proposal must cite at least one `session-*.md` or `prereview-*.md` path.
Advice based only on intuition, general experience, or code inspection is discarded.

### I-3: Three-Cycle Closure

A recurring issue can be marked "likely resolved" only after three consecutive Dream cycles without a matching signal.
It must not be closed earlier.

### I-4: Observer Logic Is Stable

Analyzer must not propose changes to Observer collection logic.
Observer changes require direct human edits because changing the signal collector changes the evidence base.

Mechanical check:

```bash
rg -i "Phase 1|Observer|Step 1:|Step 2:" proposal.md
```

Matches require manual review.

### I-5: Constitution Is Not Self-Modifying

Analyzer must not propose changes to this constitution.

Mechanical check:

```bash
rg -i "constitution|propose-wi-constitution" proposal.md
```

Matches are discarded.

### I-6: Snapshot Before Workflow Rewrites

Before overwriting any workflow or skill that is modified because of an Actionable proposal, copy the previous version into a local `versions/` directory near the file or under `docs/agent-runs/management/versions/`.
Snapshots are permanent.

### I-7: Similarity Rule

Two candidates are the same kind of signal only when both are true:

1. The impact layer identifier matches.
2. The title plus observed-problem text share at least two core keywords.

Keyword extraction is intentionally simple: use meaningful nouns and technical terms, ignore filler words and adjectives.

## Freeze Thresholds

Dream monitors Analyzer health:

- Implementation rate below 20% for two consecutive cycles: write a warning.
- Implementation rate above 85% for two consecutive cycles: write a warning because proposals may be too broad.
- Same kind of Actionable proposal implemented three times without resolving the issue: write `analyzer-freeze.md`.

When frozen, Analyzer refuses to run until the freeze file contains:

```text
manual review complete, resume
```

