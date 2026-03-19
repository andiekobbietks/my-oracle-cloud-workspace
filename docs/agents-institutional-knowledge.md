# Agents as Code — Institutional Knowledge

Purpose
--------
Capture our standards and workflow for "agents as code" so future maintainers and
coding agents get consistent, safe behavior from documentation, skills, and CI.

Key concepts
------------
- `agents.md`: global project-level context the agent sees in prompts.
- Skill (SKILL.md): lazily-loaded documentation modules (`.github/skills/*`) with YAML frontmatter (name, description, usage, inputs, applyTo).
- Codebase: the repository itself is a primary source of truth agents can read to learn new APIs/patterns.
- External sources: web fetches and curated docs (used when a skill or local code is absent).

Why this matters
----------------
Modern coding agents can use (1) prompts, (2) `agents.md`, (3) skills, (4) the local
codebase, and (5) web resources to learn how to act. Providing clear, machine-readable
documentation and safe defaults lets agents produce correct, auditable changes even for
technologies not yet common in model training data.

Standards & best practices
--------------------------
- Dry-run by default: any generator or skill should default to `dry_run` and print proposed changes. `apply` must be explicit.
- Explicit confirmation for destructive actions: require an explicit `CONFIRM`/`confirm_phrase` value to enable `apply`.
- Never store credentials in repo: reference vault paths or environment variables instead.
- Minimal frontmatter required for SKILLs:
  - `name`, `description`, `usage`, `applyTo` (where applicable)
  - Provide a short trigger phrase in `usage` or `triggers`.
- Use the in-repo validator for fast checks: run `python3 tools/validate_skill.py` (see link below).
- Keep long-form guidance in skills and short, actionable steps in `agents.md` and `docs/`.

Templates
---------
Agent metadata template (use with `agent-md-generator`):

```
---
name: <agent_name>
description: "<one-line description>"
maintainer: "<github user or team>"
triggers:
  - "example trigger phrase"
---

## Purpose

Describe the agent's responsibilities, typical inputs, and outputs.

## Verification

- Smoke-test steps
- Expected outputs
```

SKILL frontmatter template:

```
---
name: skill-name
title: One-line title
summary: Short summary
description: >-
  Longer description and guidance.
applyTo:
  - repository
usage: |
  Trigger examples:
    - "Use skill X for Y"
inputs:
  - name: param
    type: string
    description: "What it controls"
outputs:
  - name: path
    type: string
    description: "Path to generated file (dry-run/apply result)"
related:
  - .github/skills/other/SKILL.md
---
```

Operational workflows
---------------------
- Dry-run (preview):
  - Example: `make dry-run SOURCE=.devcontainer/README.md DEST=./`
  - For skills: `python3 tools/agent_md_cli.py --dry-run --agent-name infra-deployer` (or use `agent-md-generator` wrapper).
- Apply (explicit require):
  - `make backup-main`
  - `make apply SOURCE=.devcontainer/README.md DEST=./ CONFIRM=yes`
  - For skills that write files: `--apply --confirm-phrase="I confirm apply"`
- Smoke-test:
  - `make smoke-test SOURCE=.devcontainer/README.md DEST=./`

CI recommendations
------------------
- Fast pre-merge job:
  - Run `python3 tools/validate_skill.py` across `.github/skills/**` and fail on errors (warnings optional).
  - Lint Markdown and YAML frontmatter.
- Scheduled/maintainer-only job:
  - Run the heavier external skills linter (Node-based) on a schedule or release branch; triage WARNs separately.
- Protect `apply` actions behind human reviewers for multi-file/glob changes.

Repository artifacts (links)
---------------------------
- Validator: [tools/validate_skill.py](../tools/validate_skill.py)
- Relocate guide/workflow: [docs/guide.md](docs/guide.md)
- Relocate skills: [/.github/skills/relocate-file/SKILL.md](.github/skills/relocate-file/SKILL.md)
- Wrapper skill: [/.github/skills/run-relocate/SKILL.md](.github/skills/run-relocate/SKILL.md)
- Agent MD generator: [/.github/skills/agent-md-generator/SKILL.md](.github/skills/agent-md-generator/SKILL.md)
- Makefile targets: [Makefile](../Makefile)
- AGENTS index: [AGENTS.md](AGENTS.md)

Onboarding checklist for a new repo
----------------------------------
- Add `agents.md` with a one-line purpose and pointer to skills.
- Add or curate `.github/skills/*` for domain-specific guidance.
- Add `tools/validate_skill.py` to CI pre-merge workflows.
- Add `Makefile` targets for `validate`, `dry-run`, `apply`, and `smoke-test`.
- Ensure `agent-md-generator` or equivalent CLI is available to scaffold `.agent.md` files.

Short guidance for authors
------------------------
- Write SKILLs for concrete patterns (e.g., "how to relocate files", "how to rotate keys"); keep them focused.
- Provide examples and command snippets to run locally.
- Avoid language that triggers secret heuristics; use "credential" and give vault references.
- Use `dry_run` examples everywhere.

Why agents can learn new frameworks
----------------------------------
- Agents synthesize context from the codebase, skills, and web fetches. If your repo contains demos, runtime wrappers, and a small reference (for example, a `demo.remote.ts` or runtime wrapper), agents will pattern-match and produce correct code even for new or private frameworks.

Example quick-start (create an agent file)
-----------------------------------------
- Dry-run generation (preview):
```
# use your generator wrapper; this is an example
python3 tools/agent_md_cli.py --agent-name relocate-agent --description "Safely relocate files" --dry-run
```
- Apply (explicit):
```
python3 tools/agent_md_cli.py --agent-name relocate-agent --description "Safely relocate files" --apply --confirm-phrase "I confirm agent apply"
```

FAQ
---
- Q: Are skills required? A: No, but they drastically improve reliability when agents operate on repo-specific patterns.
- Q: Should we always run the external linter? A: Run the in-repo validator on every PR; run the external linter on a schedule or before releases.

Next steps you can take
-----------------------
- Link this document from `AGENTS.md` or `docs/guide.md`.
- I can also scaffold a `relocate-agent` `.agent.md` or a SKILL file from the templates above.
