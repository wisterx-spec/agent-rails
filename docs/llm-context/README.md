# LLM Context

Short, high-priority memory files maintained by `/dream` and human review.

Suggested files:

- `llms-core.txt`
- `llms-domain-backend.txt`
- `llms-domain-frontend.txt`

Keep entries concise and evidence-backed. Long explanations belong in `docs/lessons/`.

Write rules for `/dream`:

- Treat these files as compact summaries, not append-only logs.
- Read existing content first, merge accepted candidates, then rewrite atomically.
- Keep one concise item per line: `- [P1][area] Rule or invariant — evidence: path`.
- De-duplicate by normalized bullet body, ignoring priority tags, dates, and evidence suffixes.
- Enforce `project.config.json → llm_context.max_lines`; drop lower-priority or weak-evidence items first.
- Do not write inferred lessons. If evidence is weak, write only to `dream-log.md`.
