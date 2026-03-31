# Changelog

## v1.0.0 — 2026-03-31

### Initial Release

**Three-layer architecture**
- Rules (always-on): core, guardrails, frontend-ui, db series
- Workflows (on-demand): 11 workflows covering the full development lifecycle
- Skills (atomic tools): 14 independently callable skills

**Core workflows**
- `requirement-clarification` — structured Q&A → spec sign-off before any coding
- `auto-dev` — fully automated development with Ralph-loop self-optimization, supports resume
- `dev-flow` — human-driven development for exploratory scenarios
- `frontend-tdd` — Component-TDD with mandatory UX evaluation gate
- `project-bootstrap` — 0-to-1 project architecture planning
- `slim` — project cleanup (orphan components / dead routes / unused exports / bundle bloat)
- `production-release` — pre-release checks + tag

**Quality guardrails**
- Test baseline protection (`test_lock.py`) — SHA-256 lock on test assertions
- Pre-commit double gate: `scan-code-hygiene` (AI layer) + git hook (fallback)
- Anti-hallucination protocol — 4 mandatory hard stops
- Incremental component reuse check — grep before creating new components

**Knowledge management**
- `docs/conventions.md` — living conventions doc, maintained throughout the project
- `docs/decisions/` — Architecture Decision Records (ADR) with AI routing
- `docs/lessons/` — accumulated lessons from the project
- `[KNOWLEDGE_UPDATE]` / `[CONVENTION_PROPOSAL]` proposal mechanisms

**Token optimization**
- Snapshot seal protocol — load once in Phase 0, reference throughout
- SKILL.md on-demand routing — only load what the task needs
- `conventions.md` section routing — only read the "Quick Reference" block
- ADR QUICK line — single-line NEVER summary per decision file
- Session file rolling window — keep last 3 rounds only
