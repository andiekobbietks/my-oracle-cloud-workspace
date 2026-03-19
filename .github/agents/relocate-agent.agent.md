---
name: relocate-agent
description: "Agent metadata for safely relocating files in this repository"
maintainer: "@andiekobbietks"
triggers:
  - "Relocate files"
  - "Move README to root"
related:
  - docs/guide.md
  - docs/agents-institutional-knowledge.md

## Purpose

This agent is the canonical metadata entry for agent-driven relocate operations. It
points to the operational playbook and institutional knowledge so coding agents and
developers can run dry-runs, create relocations, and follow backup/rollback guidance.

## Usage

- Dry-run (preview): use the `relocate-file` SKILL with `dry_run` default to preview changes.
- Apply: follow `docs/guide.md` and use an explicit confirmation phrase before `apply`.

## Verification

- Smoke-test steps: `make smoke-test SOURCE=<src> DEST=<dest>`
- CI: ensure `tools/validate_skill.py` passes for SKILLs and docs before applying.

---
