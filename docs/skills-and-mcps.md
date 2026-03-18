# Skills and MCPs

TL;DR
- Skills: best for multi-step, reusable workflows that bundle prompts, templates, scripts, and docs.
- MCPs: use when you must integrate external systems, datasets, or deterministic APIs into an agent workflow.
- Follow simple frontmatter rules, meaningful `description`, scoped `applyTo` globs, and include examples/tests.

## Recommendations

**When to create a Skill**
- Context: You need a shareable, discoverable workflow that may run multiple stages, access bundled assets, or be invoked by name.
- Guidance:
  - Include `name`, `description` (use trigger phrases), and `usage` examples in the SKILL.md body.
  - Keep assets colocated (templates, scripts, examples).
  - Prefer Skills over ad-hoc prompts when the workflow spans steps or files.

3 example scenarios
- Code review assistant: runs staged checks, summarizes diffs, and suggests edits across multiple files.
- Release-note generator: reads changelog entries and formats release notes using templates.
- Onboarding helper: collects repo metadata and generates a starter checklist + config files.

- **When to create an MCP**
- Context: You must call an external system deterministically (APIs, databases, model orchestration, CI/CD triggers) or include credentials / connectors.
- Guidance:
  - Treat MCPs as integration primitives: document inputs/outputs, auth, rate limits, and failure modes.
  - Keep deterministic behavior and authorization explicit; do not embed secrets in repo files.
  - Provide a local "dry-run" mode or mocks for development and tests.

3 example scenarios
- Issue syncer: pushes/selects issues from a ticketing system and maps fields back into the repo.
- Search-backed assistant: queries an internal vector DB and returns verified document snippets.
- CI notifier: posts build/test status to a release dashboard or external monitoring endpoint.

## Short examples

Skill frontmatter example
```yaml
name: api-doc-generator
description: "Use when: generating API docs from source annotations and OpenAPI specs"
version: 0.1.0
```

Minimal SKILL.md body
```markdown
# API Doc Generator
Usage: /api-doc-generator path=src/api
What it does:
- extracts route annotations
- enriches with examples
- writes docs/api.md
Assets:
- templates/openapi.mustache
- scripts/extract.js
```

MCP (integration) example (document)
```yaml
mcp: jira-sync
description: "Use when: syncing PR metadata to Jira tickets"
auth: "refer to CI secret JIRA_API_TOKEN"
endpoints:
  - name: create-comment
    url: https://jira.example.com/rest/api/2/issue/{issueId}/comment
    method: POST
notes:
  - Provide a mock server for local development.
  - Failures must be surfaced back to the user.
```

## Practical rules & patterns

- Description is discovery: include short trigger phrases and example invocations.
- Scope `applyTo` narrowly: prefer `src/**` or `**/*.py` over `**`.
- YAML safety: quote values containing colons or flow characters; use spaces (no tabs).
- Assets: include a clear `assets/` folder and reference files relatively.
- Tests: include example inputs and expected outputs (small fixtures) so maintainers can validate changes.

## Checklist before committing

- - [ ] SKILL.md present and readable
- - [ ] `name` and `description` in frontmatter (description includes triggers)
- - [ ] `applyTo` present or rationale in body if global
- - [ ] No secrets in repo (use CI secrets or vault)
- - [ ] Examples and usage documented (one-liner invocation)
- - [ ] Local mocks or dry-run for MCPs
- - [ ] YAML frontmatter validated (no tabs, proper quoting)
- - [ ] Minimal tests or fixtures included and runnable
- - [ ] Lint/format as project requires

## Commit Guidance

Branch
- Use a short feature branch: `skill/<short-name>-<purpose>` (e.g., `skill/relocate-file-cleanup`).

Commit message
- Start with the skill path and short description:
  - Example: `Add: .github/skills/relocate-file — add relocate-file skill with MCP contract`

PR description
- Include:
  - **What**: Short summary of the skill and responsibilities.
  - **Why**: Reason for a single-skill approach and references to canonical docs.
  - **MCP requirements**: Permissions needed and suggested `MCP` policy.
  - **Testing**: How reviewers can run dry-runs or tests.
  - **Docs links**: Link to the canonical docs (e.g., `.github/skills/relocate-file/SKILL.md`, `docs/symbolic-links.md`).
- **Checklist for merging**:
  - Tests pass (unit/dry-run)
  - Docs linked, not duplicated
  - `MCP` policy drafted or referenced
  - Security review completed for actions that mutate state

## Quick validation commands (suggested)

- YAML lint (example)
```
python -c "import sys,yaml,io; yaml.safe_load(open('path/to/SKILL.md').read().split('---',2)[1])"
```

- Run a skill dry-run (project-specific): document the exact command in SKILL.md usage and include it in PR.

## Further reading
- See repo docs: [docs/README.md](docs/README.md) and [docs/symbolic-links.md](docs/symbolic-links.md) for repo conventions.

---
