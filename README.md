# agent-rails

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

![Flow Overview](./docs/flow-overview.png)

Constraint framework for AI-assisted development — rules, skills & guardrails that keep LLMs reliable across a full project lifecycle.

---

## Why This Exists

AI coding assistants are fast. They're also amnesiac, inconsistent, and oblivious to project history.

You describe a feature, the AI writes it, and only at review time do you realize it built the wrong thing. Or it silently broke something that was working. Or it created a third version of a component that already existed twice. Or it ignored the conventions your team spent weeks establishing.

The root problem isn't AI's coding ability — it's that **the AI has no reliable structure to operate within**. Every session starts from scratch. No guardrails, no memory, no checkpoints where a human can catch drift before it compounds.

agent-rails gives the AI a framework to work inside:

- **Rules** — absolute red lines, loaded at startup, always enforced
- **Workflows** — standardized pipelines with human checkpoints at the right moments
- **Skills** — atomic tools, lazy-loaded on demand, released after use
- **Knowledge base** — project conventions, architecture decisions, and lessons learned that persist across sessions

**Design principle: together it's a workflow, alone it's a skill.**

Every workflow is composed of independent skills. Skills can also be invoked standalone. The framework is project-agnostic — inject your specifics via `project.config.json` and it's ready.

---

## What Problems It Solves

| Pain point | Solution |
|------------|----------|
| AI builds the wrong thing, you find out at the end | `requirement-clarification` spec sign-off + `proposal-review` plan review — two human gates before coding starts |
| New features break existing ones | `impact-analysis` blast radius scan + `test-lock` baseline protection |
| No consistent conventions | `docs/conventions.md` living doc, AI reads it before every task |
| Wheels reinvented everywhere | Mandatory grep for existing components before creating new ones |
| Codebase gets messier over time | `/slim` periodic cleanup + `scan-code-hygiene` pre-commit gate |
| AI hallucinates non-existent APIs | 4-scenario anti-hallucination protocol with self-circuit-breaker |
| Conventions pile up, stale rules never cleaned | `review-guardrails` health audit + 3-day auto-reminder + 90-day expiry detection |

---

## Three-Layer Architecture

```
Rules (loaded at startup, always in system prompt)
  └─ Absolute red lines. One compact file (~7KB) — no context waste.
       ↓
Workflows (triggered on demand)
  └─ Orchestration layer. Defines skill call order, conditions, and human gates.
       ↓
Skills (lazy-loaded)
  └─ Atomic tools. System stores only name + path index. Agent reads full
     content when needed, releases after use.
```

> **Why this design?**
>
> Many projects stuff tens of thousands of words into the system prompt. The AI's attention gets diluted, and code quality suffers.
>
> agent-rails leverages the **lazy-load mechanism** of AI IDEs: Rules contain only absolute red lines (~7KB). Skills and Workflows exist as index entries (a few hundred tokens). The Agent reads what it needs, when it needs it. This preserves both constraint enforcement and context window efficiency.

---

## Requirements

### Hard Prerequisites

The framework requires the AI's **file read/write tools (tool use)**. Pure chat mode won't work.

- Tool use / function calling support
- Context window ≥ 32K tokens

### Recommended Models

| Model | Compatibility | Notes |
|-------|--------------|-------|
| Premium LLMs (Claude 3.5+, GPT-4o) | Full | Framework designed for this class — best instruction-following and self-evaluation |
| Advanced reasoning models | Full | Best for complex tasks, watch the cost |
| GPT-4o / Gemini 1.5 Pro | Mostly works | Stable tool use, workflows may need manual triggering |
| Local small models (≤ 13B) | Not recommended | Insufficient instruction-following, Ralph-loop unreliable |

### Platform Compatibility

#### Native AI Agents (Recommended)

Works out of the box for agentic environments with tool use (Antigravity IDE, Roo Code, Cursor):

- Rules in `.agents/rules/` are loaded automatically
- `/skill-name` slash commands trigger directly
- File tools match the framework's conventions exactly

```bash
./install.sh /path/to/project
# Open project directory in your AI assistant and start
```

#### Cursor / Continue.dev / Windsurf

Works with manual adaptation:

1. Copy `.agents/rules/core.md` content into your System Prompt or `.cursorrules`
2. Use natural language to trigger workflows ("run the auto-dev workflow" instead of `/auto-dev`)

#### Direct API (Programmatic)

1. Use `core.md` content as the system prompt
2. Prepend the target workflow's `.md` content to the user prompt
3. Ensure tool use is enabled with file read/write tools

#### Not Applicable

- Pure chat without tool use
- GitHub Copilot (no custom rule injection)
- Web chat interfaces (no project file access)

---

## 5-Minute Quickstart

### 1. Install

```bash
git clone https://github.com/wisterx-spec/agent-rails.git
./install.sh /path/to/your-project
```

### 2. Minimal Configuration

Edit `project.config.json` in your target project:

```jsonc
{
  "project": { "name": "your-project" },
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",
    "backend": "python+fastapi",
    "backend_path": "backend/app",
    "test_path": "backend/tests",
    "database": "mysql"          // mysql | sqlite | postgres
  },
  "testing": {
    "local_db_url": "mysql+pymysql://user:pass@localhost:3306/test_db"
  }
}
```

Missing fields degrade gracefully — they won't block startup.

### 3. First Command

```
/requirement-clarification   ← start here for new features (recommended)
```

Or jump straight in:

```
/auto-dev implement user login with email and password
```

### 4. What to Expect

```
[CONFIG LOADED] project=your-project | frontend=react+typescript | backend=python+fastapi | db=mysql
[MAINTENANCE DUE] Last guardrails review was 5 days ago. Consider running /review-guardrails

Phase 0: Pre-read
→ Reading conventions.md Quick Reference (2 STALE items flagged)
→ Loading frontend-dev-guide skill
→ Generating spec snapshot (14 lines)

[SPEC LOADED] layers: frontend+backend | constraints: 4 | tokens: tailwind.config.js
```

---

## Full Development Pipeline

```
User describes requirement
    ↓
/requirement-clarification → Spec document → 🔴 Human confirms
    ↓
Choose mode: /auto-dev (AI-driven) or /dev-flow (human-driven)
    ↓
Pre-read → Load config / conventions / decisions / domain skills
    ↓
Plan review → /proposal-review (non-trivial tasks) → 🔴 Human confirms
    ↓
Execute → Ralph-loop (Assess → Act → Verify → Log)
    ├─ Full-stack: Frontend Component-TDD first → 🔴 UX confirmation → Backend
    ├─ Auto-mount domain guardrails (frontend-dev-guide / db-dev-guide)
    └─ Loop until all P0 issues resolved
    ↓
Verification → Structured report → 🔴 Human confirms
    ↓
/commit-with-affects → Standardized commit with blast radius
    ↓
/pr-review → PR description + 4-dimension self-check
    ↓
/production-release → Hygiene scan → Tests → DDL review → 🔴 Release confirmation
    ↓
Live
```

Detailed flowchart: [`docs/flow-overview.md`](docs/flow-overview.md) (Mermaid source) and [`docs/flow-overview.png`](docs/flow-overview.png).

### Human Checkpoints

| Gate | Location | Pass condition |
|------|----------|----------------|
| Spec sign-off | After requirement-clarification | User confirms spec document |
| Plan review | auto-dev Phase 2 / dev-flow Step 3 | User replies "confirmed" |
| UX evaluation | After each frontend component | User confirms issues resolved |
| Change verification | auto-dev Phase 4 | User confirms verification report |
| Release approval | production-release | QA + DBA + deploy approval |

### Lightweight Path

These scenarios skip the proposal review to reduce confirmation fatigue:
- Bug fix with ≤ 2 files changed
- Pure styling / copy changes

---

## File Structure

```
.agents/
  rules/
    core.md               — Single global rules file (~7KB): bootstrap protocol,
                            anti-hallucination, engineering red lines, domain routing,
                            knowledge protection, experience capture, guardrail freshness

  workflows/              — Orchestration layer (12 workflows)
    requirement-clarification.md  — Structured Q&A → spec sign-off
    project-bootstrap.md          — 0→1: tech stack → page map → components → conventions
    auto-dev.md                   — Fully automated dev (Ralph-loop, supports resume)
    dev-flow.md                   — Human-driven dev
    frontend-tdd.md               — Component-TDD + UX evaluation gate
    impact-analysis.md            — Change blast radius analysis
    hotfix.md                     — P0 production emergency fix
    pr-review.md                  — PR description + self-review
    slim.md                       — Project cleanup (includes guardrail review)
    production-release.md         — Pre-release checks → tag → deploy
    git-lifecycle.md              — Git branching and commit conventions
    weekly-report.md              — Auto-generate weekly dev report

  skills/                 — Atomic tools (25+ skills, lazy-loaded)
    Plan review:    proposal-review/
    Domain guides:  frontend-dev-guide/, db-dev-guide/
    Governance:     review-guardrails/
    Planning:       advise-tech-stack/, plan-page-map/, plan-component-hierarchy/,
                    lock-global-conventions/
    Testing:        generate-test-skeleton/, run-tests/, generate-test-from-impact/
    Database:       export-db-indexes/
    Commit:         commit-with-affects/, generate-pr-description/, pr-self-review/
    Frontend:       frontend-ux-evaluator/, scan-frontend-quality/
    Hygiene:        scan-code-hygiene/
    Cleanup:        scan-orphan-components/, scan-dead-routes/, scan-unused-exports/,
                    scan-bundle-bloat/
    Knowledge:      sync-llm-context/, record-decision/

  hooks/
    pre-commit.sh         — Secret detection hook

  scripts/
    test_lock.py          — Test baseline tamper protection

docs/
  INDEX.md                — Project knowledge map (AI reads first)
  conventions.md          — Living conventions doc (maintained throughout)
  decisions/              — Architecture Decision Records (ADR)
  lessons/                — Project lessons learned (backend / frontend / testing)
  flow-overview.md        — Full pipeline flowchart (Mermaid source)
  flow-overview.png       — Full pipeline flowchart (image)

project.config.json       — Project config (not committed)
```

---

## Quick Command Reference

### Workflows

| Command | Purpose |
|---------|---------|
| `/requirement-clarification` | Clarify requirements (start here) |
| `/project-bootstrap` | New project architecture planning |
| `/auto-dev [spec]` | Fully automated development |
| `/auto-dev resume` | Resume from last checkpoint |
| `/hotfix` | P0 production emergency fix |
| `/pr-review` | PR description + self-review |
| `/production-release` | Pre-release checks + deploy |
| `/slim` | Project cleanup + guardrail review |

### Standalone Skills

| Command | Purpose |
|---------|---------|
| `/proposal-review` | Plan review (human gate) |
| `/review-guardrails` | Audit convention health (stale / conflicts / gaps) |
| `/frontend-dev-guide` | View frontend development rules |
| `/db-dev-guide` | View database development rules |
| `/generate-test-skeleton --type=api\|service\|db\|frontend` | Test-First skeleton |
| `/export-db-indexes` | Database migration DDL + rollback DDL |
| `/scan-frontend-quality` | Full frontend quality scan |
| `/scan-code-hygiene [--scope=staged\|all]` | Code hygiene scan |
| `/scan-orphan-components` | Orphan component scan |
| `/scan-dead-routes` | Dead route scan |
| `/scan-unused-exports` | Unused export scan |
| `/scan-bundle-bloat` | Heavy dependency scan |
| `/sync-llm-context` | Refresh AI context map |
| `/record-decision` | Record architecture decision |

---

## Typical Scenarios

### New Project

```
/project-bootstrap user management system, React + FastAPI
→ confirm tech stack → page map → component hierarchy → lock conventions
→ /requirement-clarification [first feature]
→ /auto-dev [confirmed spec]
```

### Taking Over an Existing Project

```bash
./install.sh /path/to/existing-project
# fill in project.config.json
```
```
/sync-llm-context          # AI scans repo, builds context map
/scan-frontend-quality     # establish frontend quality baseline
# then develop normally
```

### Full-Stack Feature

```
/requirement-clarification           # up to 6 clarifying questions
→ confirm spec
→ /auto-dev [spec]
  → /proposal-review → human confirms plan
  → frontend Component-TDD (test → lock → implement → UX eval → human confirms)
  → verify UI in browser
  → backend (API contract derived from confirmed UI)
→ /pr-review
→ /production-release
```

### Interrupted Mid-Feature

```bash
git stash && git checkout -b feature/B
# handle feature B
git checkout feature/A && git stash pop
```
```
/auto-dev resume    # resume from tmp/.agent-session.md
```

### Periodic Maintenance

```
/slim                      # Code cleanup + guardrail health review
/review-guardrails         # Standalone convention audit
```

---

## project.config.json Key Fields

```jsonc
{
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",
    "backend": "python+fastapi",
    "backend_path": "backend/app",
    "test_path": "backend/tests",
    "database": "mysql",                   // mysql | sqlite | postgres
    "css_framework": "tailwind",           // affects color convention enforcement
    "frontend_test_path": "frontend/src/__tests__",
    "frontend_extensions": ["tsx", "ts"]
  },
  "testing": {
    "local_db_url": "...",
    "test_lock_script": ".agents/scripts/test_lock.py"
  },
  "deploy": {
    "tag_format": "v{YYYYMMDD-HHMM}-{description}",
    "rollback_required": true
  }
}
```

Full field reference: `project.config.example.json`

---

## Guardrail Freshness

Conventions that only grow and never shrink lead to stale rules and diluted attention. The framework has a built-in freshness cycle:

```
On write  → Every entry must carry a date (YYYY-MM-DD)
On read   → Entries older than 90 days are flagged [STALE]
On close  → Review proposal presented, human decides: keep / update / delete
On start  → If last review was > 3 days ago, auto-reminder for /review-guardrails
```

Positive experiences are recorded too — not just "what not to do" but also "what's worth repeating."

---

## How It Constrains AI (Examples)

**AI is about to create a new Modal component:**

```
[Component reuse check]
grep frontend/src/components/ Modal Dialog...
Found candidates:
  - components/common/Modal.tsx (supports title/footer/width props)
  - components/common/DeleteConfirmModal.tsx (extends Modal)

→ Reusing Modal.tsx, extending with onConfirm prop. No new component created.
```

**AI is about to commit:**

```
[scan-code-hygiene --scope=staged]
P0: 0
P1: 2
  - frontend/src/pages/UserPage.tsx:47  console.log("debug user data")
  - backend/app/routers/auth.py:23      # TODO: add rate limiting

→ Commit allowed. Appending: known-issues: console.log×1, TODO×1
```

**AI touches a module with an architecture decision:**

```
[Decision pre-read] docs/decisions/README.md
1 match: jwt-auth-strategy.md (affects: backend/app/routers/auth/)
QUICK: NEVER swap to Session Cookie | NEVER store in localStorage | NEVER TTL > 2h

→ NEVER constraints added to spec snapshot. Applied to all auth module changes.
```

---

## Test Baseline Protection

```bash
python .agents/scripts/test_lock.py lock      # Lock after human confirms test skeleton
python .agents/scripts/test_lock.py verify    # Verify before each test run
python .agents/scripts/test_lock.py status    # Check current baseline
```

Once locked, test assertions cannot be modified. If implementation breaks, fix the implementation — not the expectations.

---

## Knowledge Accumulation

During development, the AI detects lessons at the end of each Ralph-loop iteration and surfaces proposals:

- **`[KNOWLEDGE_UPDATE]`** — pitfalls and effective practices, written to `docs/lessons/`
- **`[CONVENTION_PROPOSAL]`** — repeating patterns that should become conventions
- **`[GUIDE_UPDATE]`** — experience that should be synced back to domain guide skills

You decide whether to accept each proposal. The AI never writes to knowledge files without explicit human approval.
