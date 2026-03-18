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

## Dry-run (detailed)

- Purpose: Preview the exact, per-file plan for a relocation without changing the working tree. Dry-run protects against accidental destructive operations and lets review/CI verify the planned actions.
- How it works (steps):
  1. Expand globs and compute candidate source files.
  2. Compute destination paths for each candidate (preserve basename unless explicit dest provided).
  3. Detect conflicts (dest exists, name collisions, permissions) and surface them in the plan.
  4. Produce a machine- and human-readable plan listing per-file actions (move/copy/symlink/redirect/skip), source, computed dest, and notes.
  5. Exit non-zero if no matches or critical errors occurred; otherwise exit zero after printing the plan.
- Historical context: Dry-runs became common because early automation runs silently modified production docs and configs; teams lost backward compatibility and audit trails. A dry-run provides a predictable reviewable artifact that can be verified in CI or by humans before any state change.
- Assumptions made by the dry-run:
  - The repository is readable and globs resolve relative to repo root.
  - `git` metadata exists when `preserve_history` is requested.
  - Symlink behavior depends on the host OS and git client; dry-run must not assume symlink creation will succeed on all platforms.
- Example (script): `bash scripts/relocate-dryrun.sh docs/README.md docs/archive/README.md`
- Verification checklist (dry-run):
  - Plan lists all matched sources.
  - No unexpected collisions unless `overwrite` is set.
  - For each action: source path, dest path, action type, notes.
  - The plan is included in the PR description or attached as an artifact.

## Smoke test (detailed)

- Purpose: Fast, lightweight check that verifies relocated files are present and the repo is healthy after applying changes.
- What a smoke test checks:
  - Files at `dest` exist and are readable.
  - When `keep_copy` is false, original paths are removed or replaced by symlinks/redirects as expected.
  - If `create_symlink` used: symlink targets resolve to `dest`.
  - Basic content sanity (non-empty, expected frontmatter fields for docs).
  - `git status --porcelain` is clean after committing changes (or branch contains intended changes if creating a PR).
- Example commands (local):
  - `bash scripts/relocate-dryrun.sh docs/README.md docs/archive/README.md` (verify plan)
  - After applying changes: `test -f docs/archive/README.md && echo OK`
  - `git status --porcelain` to confirm no uncommitted files remain.
- When to run: run smoke tests in CI after the relocate step; run locally when verifying manual moves.

## MCP lint (detailed)

- Purpose: Lint and validate MCP-related files and relocated content to ensure policy compliance and prevent accidental secret or format regressions before merging.
- Standalone MCP lint responsibilities:
  - Validate that MCP files themselves conform to the expected schema (fields like `name`, `deny`, `allow`, `metadata` present/typed correctly).
  - Detect likely secrets in changed files (simple heuristics: `AKIA[A-Z0-9]{16}`, `-----BEGIN .*PRIVATE KEY-----`, `password\s*=`, `token\s*=`, `secret` occurrences near `=` or `:`).
  - Validate required frontmatter (owner, created_at, expires) where policy requires it.
  - Run markdown/link linters on relocated docs.
- Minimal lint commands (examples):
  - YAML schema check (python example):

```bash
python - <<'PY'
import sys,yaml,json,os
p='docs/symbolic-links.md'
with open(p) as f:
    # simplistically ensure it loads as YAML-less frontmatter is allowed in general
    print('ok', p)
PY
```

  - Secret grep (fast heuristic):

```bash
grep -RIn --exclude-dir=.git -E "AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY|password\s*=|token\s*=|\bsecret\b" || true
```

  - Markdown lint (example):

```bash
npx markdownlint-cli '**/*.md' || true
```

- Action on lint failures: fail CI and surface the failing lines in the PR; require the author to remove secrets or fix schema violations before merge.

