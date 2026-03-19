**Overview**

- **Purpose:** Concise guidance for maintainers and automation engineers on safely authoring, reviewing, and running repository agents and skills.
- **Audience:** Repo maintainers, automation authors, CI engineers, and governance reviewers.
- **Scope:** Agent vs Skill roles, file formats (`.agent.md`, `SKILL.md`), templates, scenario approval matrix, CI examples, validators, vault/security guidance, Makefile targets, and FAQ.

**Key Concepts**

- **Agent:** An automation process or assistant that can read, propose, or make repository changes. Agents are driven by triggers, prompts, or scheduled jobs.
- **Skill:** A reusable capability (documented in `SKILL.md`) that agents invoke to perform safe, constrained tasks (e.g., `relocate-file`, `key-rotation`).
- **Customization:** Per-agent metadata in `.agent.md` files describing scope, triggers, maintainers, and constraints.
- **Dry-run-first:** All agents must support a `dry_run`/preview mode that shows planned changes without applying them.
- **Preserve-history:** When moving files, prefer `git mv` to keep history. If impossible, record a clear migration plan.

**Roles: Agent vs Skill**

- **Agent (orchestrator):**
  - Invokes Skills; parses user intents; creates PRs or runs Makefile targets.
  - Responsible for compliance checks, approvals, and audit logging.
  - Must never embed secrets; must reference vault paths.
- **Skill (executor):**
  - Implements a single, well-scoped operation with inputs/outputs and clear verification steps.
  - Must document required approvals, side effects, and dry-run behavior in `SKILL.md`.

**File Formats and Examples**

- `.agent.md` (metadata file — one-per-agent)
  - Example skeleton:

```
---
name: infra-deployer
description: "Deploy infra previews for PRs"
maintainer: ops@example.com
triggers:
  - "on PR labeled `deploy`"
applyTo:
  - infra/**
do_not_edit_paths:
  - infra/secrets/**
---
```

- `SKILL.md` (skill manifest)
  - Must contain `name`, `description`, `usage`, `inputs`, `outputs`, `applyTo`, and `agent guidance`.
  - Example minimal `SKILL.md` frontmatter:

```
---
name: relocate-file
description: "Move files safely with dry-run and optional `git mv`"
applyTo: [docs/**, .devcontainer/**]
inputs:
  - source (required)
  - dest (required)
  - dry_run (default: true)
---
```

**Templates**

- Agent template (use with generator tools):

```
---
name: {{agent_name}}
description: "{{one-line summary}}"
maintainer: "team@example.com"
triggers:
  - "manual"
  - "schedule: daily"
applyTo:
  - docs/**
do_not_edit_paths:
  - scripts/**
verification:
  - "dry_run: true"
  - "CI checks pass"
approvals:
  - "code-owner OR security"
---
```

**Scenario Matrix**

- Single-file relocate
  - Inputs: `source` (single file), `dest`
  - Approvals: repo maintainer or code-owner
  - CI Checks: `lint`, `link-check` (if docs), `unit`
  - Notes: allow `git mv` and preserve history.
- Glob relocate (multi-file)
  - Inputs: `source` (glob), `dest`, `dry_run: true`
  - Approvals: Maintainer + human review (explicit)
  - CI Checks: same as single-file + full link-update verification
  - Notes: Require dry-run preview before apply.
- Bulk refactor (many files / content changes)
  - Inputs: pattern, transform script
  - Approvals: Maintainer + security (if script runs)
  - CI Checks: `lint`, `format`, `smoke-test`, `integration`
  - Notes: Prefer staged PRs; break into batches.
- Preserve history relocation
  - Inputs: `preserve_history: true`
  - Approvals: Maintainer
  - CI Checks: basic CI; verify git history present
  - Notes: use `git mv` where possible.
- Cross-repo move
  - Inputs: source repo, dest repo, transfer plan
  - Approvals: Owners of both repos + security if secrets involved
  - CI Checks: CI in both repos; integration tests
  - Notes: Use PRs in both repos; document migration.
- Rollbackable change
  - Inputs: action, backup target, smoke-test
  - Approvals: Maintainer + ops
  - CI Checks: smoke-tests pre/post
  - Notes: Always produce an automated rollback command.
- Agent-driven relocate (automated)
  - Inputs: trigger, `dry_run`, confirm phrase for `apply`
  - Approvals: Human confirmation required for `apply` or code-owner
  - CI Checks: run `dry_run` checks in CI and require green before `apply`
  - Notes: Use `confirm_phrase` or manual merge gating.
- CI scheduled cleanup (housekeeping)
  - Inputs: schedule, scope
  - Approvals: Maintainer
  - CI Checks: lightweight `smoke-test`
  - Notes: Use rate limits and logging; require PR for scope changes.

**CI Job Examples (GitHub Actions)**

- `ci-dry-run.yml` (dry-run + validation)

```
name: Agent Dry-Run
on: [pull_request, workflow_dispatch]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install validators
        run: pip install -r requirements.txt
      - name: Run agent validators
        run: |
          make validate-agent-manifests
          ./tools/check_sensitive_pr.py --dry-run
      - name: Lint & tests
        run: |
          make lint
          make test
```

- `ci-apply.yml` (apply gated by approvals)

```
name: Agent Apply
on:
  workflow_dispatch:
jobs:
  gated-apply:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Human approval
        uses: peter-evans/slash-command-dispatch@v2
      - name: Run relocate apply
        run: |
          make apply SOURCE="${{ inputs.source }}" DEST="${{ inputs.dest }}" CONFIRM=yes
```

**Validator Commands**

- Repo manifest & policy checks:
  - `make validate-agent-manifests` — checks `.agent.md` frontmatter, `applyTo`, and `do_not_edit_paths`.
- Sensitive-change detection:
  - `python3 tools/check_sensitive_pr.py --path <PR_DIR>`
- Skill lint:
  - `./tools/validate_skill.py .github/skills/*.md`
- Relocate dry-run:
  - `bash scripts/relocate-dryrun.sh <source> <dest>`

**Security and Vault Guidance**

- **Never store secrets in agent metadata or PR descriptions.**
- Agents and CI must reference credentials by vault path only (e.g., `vault/data/ci/my-token`).
- Use the repository vault integration patterns: see `.github/skills/vault-integration/SKILL.md`.
- Key rotation must follow dry-run → canary → staged rollout → revoke pattern (see `.github/skills/key-rotation/SKILL.md`).
- Audit:
  - Record agent actions in logs with actor, timestamp, command, and reason.
  - For sensitive operations, keep a signed audit artifact and PR with explicit rollback instructions.
- Least privilege:
  - Grant CI principals minimal read-only access to the vault path needed.
- Masking:
  - All logs must mask secrets; dry-run outputs show masked diffs only.

**Examples of Commands**

- Generate agent file (dry-run):
  - `agent-md-generator --agent-name infra-deployer --description "Deploy previews" --dry-run`
- Relocate dry-run:
  - `bash scripts/relocate-dryrun.sh docs/guide.md docs/archive/guide.md`
- Run skill locally (dry-run):
  - `python tools/run_skill.py --skill relocate-file --source docs/*.md --dest docs/archive/ --dry_run`
- Validate manifests:
  - `make validate-agent-manifests`
- Apply relocate (manual, requires confirmation):
  - `make apply SOURCE=.devcontainer/README.md DEST=./ CONFIRM=yes`

**Recommended Makefile Targets**

- `make validate-agent-manifests` — lint `.agent.md` and `SKILL.md` files
- `make dry-run SOURCE=<src> DEST=<dest>` — run relocate dry-run
- `make apply SOURCE=<src> DEST=<dest> CONFIRM=yes` — apply relocate (guarded)
- `make backup-main` — snapshot main branch before large apply
- `make smoke-test` — run basic post-change checks

**Agent Governance Checklist (must be satisfied before `apply`)**

- Dry-run produced a clear plan and diff.
- Required approvals obtained (per scenario matrix).
- CI validators passed (`validate-agent-manifests`, `lint`, `test`, `link-check`).
- Backup or rollback plan exists and is executable.
- No secrets embedded in changes; vault references used.
- Commit messages and PR descriptions include audit details and contact info.

**Short FAQ**

- Q: When should an agent be allowed to push directly to `main`?
  - A: Avoid direct pushes. Only highly-trusted, auditable automation with signed commits and explicit policy may do so; prefer PRs and human merges.
- Q: How do I request an exception to `do_not_edit_paths`?
  - A: Create a ticket explaining the change, include a dry-run, and obtain explicit maintainers' approval. Agents must not modify those paths without human review.
- Q: How are secrets provided to agents in CI?
  - A: Via vault-backed secret references (not env-in-plaintext). Configure CI to fetch secrets at runtime using short-lived roles.
- Q: How to rollback a bot-applied relocate?
  - A: Use the backup produced by `make backup-main` and follow rollback commands documented in the PR; automated rollback scripts should be part of the relocate Skill.
- Q: Where do I find example Skills and agent rules?
  - A: See `.github/skills/` for Skill patterns and templates (for example, `agent-customization SKILL.md`).

**Further Reading and Links**

- Skill examples: `.github/skills/agent-customization/SKILL.md`, `.github/skills/agent-md-generator/SKILL.md`
- Relocate patterns: `.github/skills/relocate-file/SKILL.md`, `.github/skills/run-relocate/SKILL.md`
- Vault & key rotation: `.github/skills/vault-integration/SKILL.md`, `.github/skills/key-rotation/SKILL.md`

— End of guide.
