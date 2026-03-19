---
name: run-relocate
description: 'Skill wrapper to run the repository `Makefile` relocate targets in a
  controlled, auditable way.

  Trigger example: "Run relocate source=.devcontainer/README.md dest=./ (dry-run)".

  Enforces `dry_run` by default and requires explicit confirmation to `apply`.

  '
usage: "Trigger examples:\n  - \"Run relocate: source=.devcontainer/README.md dest=./\
  \ (dry-run)\"\n  - \"Run relocate --apply source=README.md dest=docs/ confirm_phrase=yes\"\
  \n"
applyTo:
- Makefile
- scripts/**
- .github/workflows/**
do_not_edit_paths:
- .github/workflows/**
- .github/actions/**
- .github/skills/**
- infra/**
- terraform/**
- scripts/**
- secrets/**
- credentials/**
- cloud-credentials/**
- '**/*.pem'
- '**/*.key'
- '**/*.p12'
- .env*
- .docker/config.json
- kms/**
- keys/**
- ci/**
---
Agent guidance: Do not modify files listed in `do_not_edit_paths` without explicit human approval; produce a draft and open a ticket.


# Run Relocate (Skill)

## Purpose

Provide a minimal Skill entrypoint that maps user inputs to the `make` targets defined in the repository.

## Inputs

- `source` (required) — path or glob for files to relocate.
- `dest` (required) — destination path or directory.
- `action` (optional) — `dry-run` (default) or `apply`.
- `confirm_phrase` (optional) — when `action: apply` this must be set to the literal `yes` to proceed.

## Behaviour

- If `action` is omitted or `dry-run`, the skill runs: `make dry-run SOURCE=<source> DEST=<dest>` and returns the plan.
- If `action: apply`, the skill requires `confirm_phrase: yes` and will run:

  - `make backup-main`
  - `make apply SOURCE=<source> DEST=<dest> CONFIRM=yes`
  - `make smoke-test SOURCE=<source> DEST=<dest>`

The Skill will always report the commands it intends to run and will not run `apply` without explicit confirmation.

## Examples

- Dry-run example:

  `source: .devcontainer/README.md`, `dest: ./`, `action: dry-run`

- Apply example (requires explicit confirmation phrase):

  `source: .devcontainer/README.md`, `dest: ./`, `action: apply`, `confirm_phrase: yes`

## Agent guidance

- Always present dry-run results for review before performing `apply`.
- For multi-file globs, require a human reviewer to confirm.
