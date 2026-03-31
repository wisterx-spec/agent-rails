# Contributing

Issues and PRs are welcome. The framework is Markdown files — the barrier to contribute is low.

---

## Ways to Contribute

### Report a Problem

If a workflow or skill behaves unexpectedly, or a rule is ambiguous, open a [Bug report](https://github.com/wisterx-spec/agent-rails/issues/new?template=bug_report.md).

### Suggest a New Skill or Workflow

If you have a use case the framework doesn't cover, open a [Feature request](https://github.com/wisterx-spec/agent-rails/issues/new?template=feature_request.md).

### Submit a PR

---

## Adding a Skill

Each skill is a standalone directory containing a single `SKILL.md` file.

**Directory structure:**

```
.agents/skills/your-skill-name/
  SKILL.md
```

**Required frontmatter in `SKILL.md`:**

```yaml
---
name: skill-name
description: One-line description of what this skill does
trigger: /skill-name [args]
inputs:
  - name: param-name
    source: where this input comes from
    required: true/false
outputs:
  - name: output-name
    destination: where the output goes
standalone: true/false      # can it be called independently?
called_by:
  - workflow/xxx             # which workflows call this skill
---
```

**Constraints:**
- A skill must be atomic — it does one thing
- Inputs and outputs must be explicit
- Every Step must be verifiable
- NEVER directly modify `.agents/rules/` or `docs/lessons/` inside a skill

After adding a skill, update the registry and dependency graph in `.agents/SKILL_INDEX.md`.

---

## Adding a Workflow

Workflows are pure orchestration — they call skills, they don't implement logic directly.

**Rules:**
- Each step either calls a skill or is a human checkpoint (waiting for user confirmation)
- Don't write raw `grep` commands or file operations in a workflow — that's a skill's job
- Register the new workflow's trigger command in the README quick-reference table

---

## Modifying Existing Rules (`.agents/rules/`)

Rule changes affect every project using this framework. In your PR description, explain:
- The motivation (what scenario the existing rule fails to handle, or where it's ambiguous)
- Whether this is a breaking change for existing projects

---

## PR Format

- Title: `feat(skill): add xxx skill` / `fix(workflow): fix auto-dev phase N`
- Describe *why*, not just *what*
- If you're adding a skill, include a usage example
