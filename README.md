# agent-rails

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Claude Code](https://img.shields.io/badge/Platform-Claude_Code-blue)](https://claude.ai/code)
[![Works with: GPT-4o](https://img.shields.io/badge/Works_with-GPT--4o-green)]()

Opinionated workflow framework for AI-assisted development — rules, skills & guardrails that keep LLMs reliable across a full project lifecycle.

---

## Why This Exists

AI coding assistants are fast. They're also amnesiac, inconsistent, and oblivious to project history.

You've probably experienced this: you describe a feature, the AI writes it, and only when you look at the result do you realize it built the wrong thing. Or it silently broke something that was working. Or it created a third version of a component that already existed twice. Or it ignored the conventions your team spent weeks establishing.

The root problem isn't the AI's coding ability — it's that **the AI has no reliable structure to operate within**. Every session starts from scratch. There are no guardrails, no memory, no checkpoints where a human can catch drift before it compounds.

agent-rails solves this by giving the AI a framework to work inside:

- **Rules** that load automatically and constrain what the AI can do
- **Workflows** that enforce checkpoints, require human sign-off at the right moments, and prevent the AI from skipping steps
- **Skills** that are atomic, independently verifiable, and composable into larger flows
- **Knowledge files** that accumulate project-specific context across sessions — conventions, decisions, lessons learned

The result is an AI that asks before assuming, checks before committing, and builds on what already exists instead of reinventing it.

**Design principle: together it's a workflow, alone it's a skill.**

Every workflow is composed of independent skills. Skills can also be invoked standalone. The framework is project-agnostic — inject your project specifics via `project.config.json` and it's ready to use.

---

## What Problems It Solves

| Pain point | How the framework addresses it |
|------------|-------------------------------|
| AI builds the wrong thing and you only find out at the end | `requirement-clarification` spec sign-off + Frontend-First: UI confirmed before backend starts |
| New features break existing ones | `impact-analysis` + `test-lock` test baseline protection |
| No consistent conventions — every file written differently | `docs/conventions.md` living doc, AI reads it before every task |
| No component reuse, wheels reinvented everywhere | Mandatory grep for existing components before creating new ones |
| Codebase gets messier with every change | `/slim` periodic cleanup + pre-commit double gate |
| AI hallucinates — references functions that don't exist | 4-scenario anti-hallucination protocol with self-circuit-breaker |

---

## Requirements

### Hard Prerequisites

The framework depends on the AI's **file read/write tools (tool use)**. Pure chat mode won't work. Minimum requirements:

- Tool use / function calling support
- Context window ≥ 32K tokens

### Recommended Models

| Model | Compatibility | Notes |
|-------|--------------|-------|
| Claude Sonnet 3.5 / 4+ | Full | Framework designed for this — best instruction-following and self-evaluation |
| Claude Opus | Full | Better for complex tasks, higher cost |
| GPT-4o | Mostly works | Stable tool use, but workflows must be triggered manually (see platform notes) |
| Gemini 1.5 Pro+ | Mostly works | Same as GPT-4o, requires trigger adaptation |
| Local small models (≤ 13B) | Not recommended | Complex instruction-following quality insufficient, Ralph-loop unreliable |

### Platform Notes

#### Claude Code (native, recommended)

Built for Claude Code — works out of the box:

- Rules in `.agents/rules/` marked `trigger: always_on` are loaded automatically
- `/skill-name` slash commands trigger skills directly
- File tools (Read / Edit / Grep / Glob / Bash) match the framework's conventions exactly

```bash
./install.sh /path/to/project   # install
# Open project directory in Claude Code and start
```

#### Cursor / Continue.dev / Windsurf

Works, but requires manual adaptation:

1. Copy core rule content from `.agents/rules/` into the platform's System Prompt or `.cursorrules`
2. Trigger workflows by typing the workflow name in chat (e.g. "run the auto-dev workflow") instead of `/auto-dev`
3. Replace slash commands with natural language (e.g. "run the commit-with-affects skill")
4. Tool names differ — the AI will map them, but verify Read/Edit/Bash availability

```
# Add to .cursorrules or system prompt:
Please read the rules in .agents/rules/core.md before starting any task.
```

#### Direct API (programmatic use)

For embedding the framework in automation pipelines:

1. Use `core.md` and `guardrails.md` content as the system prompt
2. Prepend the target workflow's `.md` content to the user prompt
3. Ensure tool use is enabled and file read/write tools are mounted
4. Rules must be reloaded each conversation (no `always_on` mechanism)

#### Not Applicable

- Pure chat API calls without tool use
- GitHub Copilot (no custom workflow rule injection)
- Web-based ChatGPT / Claude.ai (no project-level file access)

---

## 5-Minute Quickstart

### 1. Install

```bash
git clone https://github.com/wisterx-spec/agent-rails.git
./install.sh /path/to/your-project
```

### 2. Minimal Configuration

Edit `project.config.json` in your target project — only these fields are required to start:

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

Open the project directory in Claude Code and type:

```
/requirement-clarification   ← start here for new features (recommended)
```

Or jump straight into development:

```
/auto-dev implement user login with email and password
```

### 4. What to Expect

```
[CONFIG LOADED] project=your-project | frontend=react+typescript | backend=python+fastapi | db=mysql

Phase 0: Pre-read
→ Reading docs/conventions.md Quick Reference block
→ Reading docs/decisions/README.md index (0 decisions matched)
→ Routing: loading commit-with-affects/SKILL.md
→ Generating spec snapshot (12 lines)

[SPEC LOADED] layers: frontend+backend | constraints: 3 | token definitions: tailwind.config.js
```

---

## File Structure

```
.agents/
  rules/          # Always-on guardrails
    core.md           — global rules: config loading, anti-hallucination, write protection
    guardrails.md     — engineering hard stops: DB ops, frontend bans, secrets, dependencies
    frontend-ui.md    — frontend UI conventions: semantic colors, shared components, state boundaries
    db.md             — DB router: dispatches to db-mysql.md / db-sqlite.md / db-postgres.md
    db-mysql.md       — MySQL-specific rules
    db-sqlite.md      — SQLite-specific rules
    db-postgres.md    — PostgreSQL-specific rules

  workflows/      # Orchestration layer (calls skills, no direct logic)
    requirement-clarification.md  — structured Q&A → spec sign-off
    project-bootstrap.md          — 0-to-1: tech stack → page map → component hierarchy → conventions
    auto-dev.md                   — fully automated dev (Ralph-loop, supports resume)
    dev-flow.md                   — human-driven dev (exploratory scenarios)
    frontend-tdd.md               — Component-TDD + UX evaluation gate
    impact-analysis.md            — change blast radius analysis
    hotfix.md                     — P0 production emergency fix
    pr-review.md                  — PR description generation + self-review
    slim.md                       — project cleanup (orphan files / dead routes / dependencies)
    production-release.md         — pre-release checks → tag → deploy
    git-lifecycle.md              — git branching and commit conventions
    weekly-report.md              — auto-generate weekly dev report

  skills/         # Atomic tools (independently callable, also orchestrated by workflows)
    Planning:
      advise-tech-stack/          — tech stack recommendation with rationale
      plan-page-map/              — page route tree (MVP / deferred annotations)
      plan-component-hierarchy/   — component layering rules + state management boundaries
      lock-global-conventions/    — global conventions doc + .slimignore bootstrap
    Testing:
      generate-test-skeleton/     — Test-First skeleton by type (api/service/db/frontend)
      run-tests/                  — test router (→ pytest or jest)
      generate-test-from-impact/  — generate tests from impact-analysis GAP list
    Database:
      export-db-indexes/          — incremental ALTER DDL + rollback DDL
    Commit:
      commit-with-affects/        — structured commit with blast radius assessment
      generate-pr-description/    — PR description from git log
      pr-self-review/             — 4-dimension self-check: quality / compliance / security / tests
    Frontend quality:
      frontend-ux-evaluator/      — single component/page UX evaluation (5 dimensions)
      scan-frontend-quality/      — full frontend quality scan (8 dimensions)
    Code hygiene:
      scan-code-hygiene/          — scan for console.log / TODO / hardcoded addresses / secrets
    Cleanup:
      scan-orphan-components/     — find components with zero import references
      scan-dead-routes/           — ghost routes + orphan pages
      scan-unused-exports/        — unused function/type/constant exports
      scan-bundle-bloat/          — heavy dependency alternatives
    Knowledge:
      sync-llm-context/           — refresh AI context map
      record-decision/            — write Architecture Decision Record (ADR)

  hooks/
    pre-commit.sh   # git pre-commit hook template (auto-installed by install.sh)

  scripts/
    test_lock.py    # test baseline tamper protection (lock / verify / status)

  SKILL_INDEX.md  # skill registry (workflow overview + full dependency graph + quick-find)

docs/
  INDEX.md              # project knowledge map (AI reads this first)
  conventions.md        # living conventions doc (bootstrapped, maintained throughout)
  decisions/
    README.md           # ADR index (AI routing)
    _template.md        # decision record template
  lessons/
    backend.md          # backend lessons learned
    frontend.md         # frontend lessons learned
    testing.md          # testing lessons learned

project.config.json        # project-specific config (not committed)
project.config.example.json
.slimignore.example        # cleanup exemption list template
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
| `/production-release` | Pre-release checks + tag |
| `/slim` | Project cleanup |
| `/sync-llm-context` | Refresh AI's project context map |

### Standalone Skills

| Command | Purpose |
|---------|---------|
| `/advise-tech-stack` | Tech stack recommendation only |
| `/plan-page-map` | Page route structure only |
| `/plan-component-hierarchy` | Component hierarchy only |
| `/generate-test-skeleton --type=api\|service\|db\|frontend` | Test-First skeleton |
| `/export-db-indexes` | Database migration DDL + rollback DDL |
| `/generate-pr-description` | PR description only |
| `/pr-self-review` | PR code self-review only |
| `/frontend-ux-evaluator` | Single component/page UX evaluation |
| `/scan-frontend-quality` | Full frontend quality scan |
| `/scan-code-hygiene [--scope=staged\|all]` | Code hygiene scan |
| `/scan-orphan-components` | Orphan component scan only |
| `/scan-dead-routes` | Dead route scan only |
| `/scan-unused-exports` | Unused export scan only |
| `/scan-bundle-bloat` | Heavy dependency scan only |

---

## How the Framework Constrains AI (Examples)

**Scenario: AI is about to create a new Modal component**

Without the framework, AI writes a new component directly. With it:

```
[Component reuse check]
grep frontend/src/components/ Modal Dialog...
Found candidates:
  - components/common/Modal.tsx (exists, supports title/footer/width props)
  - components/common/DeleteConfirmModal.tsx (extends Modal)

→ Reusing Modal.tsx, extending with onConfirm prop. No new component created.
```

**Scenario: AI is about to commit**

```
[Step 0-A] scan-code-hygiene --scope=staged
P0 issues: 0
P1 issues: 2
  - frontend/src/pages/UserPage.tsx:47  console.log("debug user data")
  - backend/app/routers/auth.py:23      # TODO: add rate limiting

→ Commit allowed. Appending to commit message: known-issues: console.log×1, TODO×1
```

**Scenario: AI reads the decision index**

```
[Decision pre-read] docs/decisions/README.md
1 decision matched: jwt-auth-strategy.md (affects: backend/app/routers/auth/)
QUICK: NEVER swap to Session Cookie | NEVER store token in localStorage | NEVER TTL > 2h

→ NEVER constraints added to spec snapshot. Applied to all auth module changes.
```

---

## Typical Scenarios

### New Project

```
/project-bootstrap user management system, React + FastAPI
→ confirm tech stack → page map → component hierarchy → lock conventions → you sign off
→ /requirement-clarification [first feature]
→ /auto-dev [confirmed spec]
```

### Taking Over an Existing Project

```bash
./install.sh /path/to/existing-project
# fill in project.config.json
```
```
/sync-llm-context        # AI scans repo, builds context map
/scan-frontend-quality   # establish current frontend quality baseline
# then develop new features normally
```

### Full-Stack Feature

```
/requirement-clarification     # up to 6 clarifying questions
→ you confirm the spec
→ /auto-dev [spec]
  → frontend Component-TDD (write test → lock → implement → green → UX eval → you confirm)
  → you verify UI in browser
  → backend (API contract derived from confirmed UI)
→ /pr-review
→ /production-release
```

### Interrupted Mid-Feature

```bash
git stash                # save current work
git checkout -b feature/B
# handle feature B
git checkout feature/A
git stash pop
/auto-dev resume         # resume from tmp/.agent-session.md
```

### Production P0 Incident

```bash
git stash
git checkout main && git checkout -b hotfix/xxx
/hotfix                  # minimal fix flow, skips most steps
# after fix is stable
git checkout feature/xxx
git stash pop
/auto-dev resume
```

### Periodic Cleanup

```
/slim
→ scan-orphan-components + scan-dead-routes + scan-unused-exports + scan-bundle-bloat
→ generates deletion proposal (P0/P1/P2 priority)
→ you confirm → AI deletes file by file → full test run
```

---

## project.config.json Key Fields

```jsonc
{
  "tech_stack": {
    "frontend": "react+typescript",
    "frontend_path": "frontend/src",       // frontend source root
    "backend": "python+fastapi",
    "backend_path": "backend/app",         // backend source root
    "test_path": "backend/tests",
    "database": "mysql",                   // mysql | sqlite | postgres
    "css_framework": "tailwind",           // affects color convention enforcement
    "frontend_test_path": "frontend/src/__tests__",
    "frontend_extensions": ["tsx", "ts"]   // used by scan-frontend-quality
  },
  "testing": {
    "local_db_url": "...",                 // local test database URL
    "test_lock_script": ".agents/scripts/test_lock.py"
  },
  "deploy": {
    "tag_format": "v{YYYYMMDD-HHMM}-{description}",
    "rollback_required": true
  }
}
```

Full field reference: `project.config.example.json`.

---

## Three-Layer Architecture

```
Rules (always-on)
  └─ Hard constraints, the foundation for all operations
       ↓
Workflows (on-demand)
  └─ Orchestration layer — defines skill call order and conditions
       ↓
Skills (atomic tools)
  └─ Each skill has its own trigger command and is also called by workflows
```

- **Rules** load automatically when AI starts a session — no manual trigger needed
- **Workflows** are triggered via `/workflow-name`, orchestrating skills in sequence
- **Skills** are invoked via `/skill-name` independently, or chained by workflows

See `.agents/SKILL_INDEX.md` for the full dependency graph and quick-find table.

---

## Test Baseline Protection

```bash
# Lock (after human confirms the test skeleton in Test-First phase)
python .agents/scripts/test_lock.py lock

# Verify (run before every test execution — prevents assertion tampering)
python .agents/scripts/test_lock.py verify

# Check current baseline status
python .agents/scripts/test_lock.py status
```

Once locked, test assertions cannot be modified. If implementation breaks, fix the implementation — not the expectations.

---

## Knowledge Accumulation

During development, AI detects lessons at the end of each Ralph-loop iteration and surfaces a `[KNOWLEDGE_UPDATE]` proposal. You decide whether to write it to `docs/lessons/`.

These files are the AI's "onboarding background" for the next session — not general knowledge, only **lessons learned in this specific project**.
