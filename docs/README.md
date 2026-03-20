# Docs (Doc-as-Code)

This `docs/` folder holds repository documentation as code. Treat docs as first-class, reviewable, and versioned artifacts.

Overview
- Keep docs small, targeted, and linked from code where relevant.
- Prefer incremental edits (small PRs) so changes are reviewable and traceable.

Authoring conventions
- File layout: start with a one-line summary, then a short intro paragraph, then headings.
- Tone: prescriptive and actionable; prefer examples and commands over long theoretical text.
- Naming: use kebab-case for filenames (for example `oci-bootstrap.md`).
- Frontmatter: use YAML frontmatter for machine-readable metadata (see examples below).

Index (key docs)
- `guide.md` — entry-level contributor guide and linking conventions.
- `oci-explainer.md` — OCI-focused explanation and best practices.
- `oci-bootstrap.mdx` — agent and bootstrap guidance for OCI provisioning.
- `key-rotation.md` / `key-rotation.mdx` — rotating long-lived credentials.
- `relocate-file.mdx` / `relocate-safety-and-makefile-plan.md` — relocation SOPs and safety checks.
- `smoke-test.md` / `smoke-test.mdx` — quick verification checks.
- `mcp-lint.md` — linting rules and CI integration for MCPs and skills.
- `agent-safety.mdx` — safety controls about automated agent edits.

Frontmatter examples
```yaml
---
title: "OCI Bootstrap — Quick Reference"
description: "How to run the OCI bootstrap agent and review plans."
tags: [oci, agent, bootstrap]
reviewers:
	- alice@example.com
	- platform-team@example.com
---
```

Markdown authoring tips
- Use fenced code blocks for all commands and samples.
- Prefer explicit CLI examples including environment variables and exact commands.
- Add cross-links to related docs using relative paths.

CI / testing guidance
- Linting: enable `markdownlint` (or repo-preferred linter) in CI and fix reported issues.
- Link checking: run a link-checker (for example `lychee` or `markdown-link-check`) in CI to catch broken references.
- Spell / style: run a lightweight spelling or style checker (for example `cspell` or `alex`).
- Automated docs tests: keep small smoke-test scripts under `examples/` and exercise them in CI when relevant.

Recommended CI job names and checks
- `docs/lint` — runs `markdownlint` and fails on rule violations.
- `docs/links` — runs link-checker against built site or raw markdown.
- `docs/spell` — runs spelling checks for contributor-facing docs.

Agent / index updates
- Keep `AGENTS.md` and `.github/agents/*` manifests synchronized with docs; add a link to `docs/README.md` so agents and maintainers can find authoring guidance.
- When adding a new agent or skill, add a short one-line description and pointer to the authoritative docs file.

Next actions
- A: Run a repo-wide doc audit (lint + link check + spell) and collect failures.
- B: Add a `make docs-check` target that runs linters, link-checks, and spelling checks (CI-friendly).

How to edit
1. Create or update a file under `docs/` following frontmatter and authoring conventions.
2. Run local checks: `markdownlint`, link-checker, and `cspell` (or repo equivalents).
3. Commit with a short message describing the doc change and open a PR for non-trivial edits.

Further reading
- See `docs/agents-institutional-knowledge.md` for agent-focused conventions.
- See `docs/relocate-file.mdx` for safety and relocation SOPs.
