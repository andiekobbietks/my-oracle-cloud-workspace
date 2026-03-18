---
name: run-relocate
description: |
  Skill wrapper to run the repository `Makefile` relocate targets in a controlled, auditable way.
  Enforces `dry_run` by default and requires explicit confirmation to `apply`.

---

# Run Relocate (Skill)

## Purpose

Provide a minimal Skill entrypoint that maps user inputs to the `make` targets defined in the repository.

## Inputs

- `source` (required) — path or glob for files to relocate.
- `dest` (required) — destination path or directory.
- `action` (optional) — `dry-run` (default) or `apply`.
- `confirm_token` (optional) — when `action: apply` this must be set to the literal `yes` to proceed.

## Behaviour

- If `action` is omitted or `dry-run`, the skill runs: `make dry-run SOURCE=<source> DEST=<dest>` and returns the plan.
- If `action: apply`, the skill requires `confirm_token: yes` and will run:

  - `make backup-main`
  - `make apply SOURCE=<source> DEST=<dest> CONFIRM=yes`
  - `make smoke-test SOURCE=<source> DEST=<dest>`

The Skill will always report the commands it intends to run and will not run `apply` without explicit confirmation.

## Examples

- Dry-run example:

  `source: .devcontainer/README.md`, `dest: ./`, `action: dry-run`

- Apply example (requires explicit token):

  `source: .devcontainer/README.md`, `dest: ./`, `action: apply`, `confirm_token: yes`

## Agent guidance

- Always present dry-run results for review before performing `apply`.
- For multi-file globs, require a human reviewer to confirm.
