---
name: agent-customization
title: Agent Customization
description: |
  Create, update, review, fix, or debug VS Code agent customization files. Prevent agents
  from making unsafe edits to sensitive repository files by restricting `applyTo` and
  declaring explicit `do_not_edit_paths` that agents must never modify without human review.
applyTo:
  - .github/**
  - .github/skills/**
  - docs/**
  - examples/**
  - scripts/**
do_not_edit_paths:
  - .github/workflows/**
  - scripts/rotate-oci-key.sh
  - scripts/bootstrap-example.sh
  - scripts/install-oci-noninteractive.sh
  - infra/**
  - terraform/**
  - secrets/**
  - **/*.pem
  - **/*.key
  - .env*
usage: |
  Use this skill to author or modify agent-facing customization files (SKILL.md, .agent.md,
  prompts/instructions). Agents must not edit files listed in `do_not_edit_paths` without
  explicit human approval. When a sensitive change is required, produce a draft and open a
  ticket for manual review.
related:
  - AGENTS.md
  - .github/skills/secret-detection/SKILL.md
  - .github/skills/vault-integration/SKILL.md
---

Purpose

This skill defines the discovery surface and safe-edit rules for agent customization. It is
intentionally narrow: do not use `applyTo: "**/*"`. Agents are expected to:

- Load this skill for workspace-level customization guidance.
- Respect `do_not_edit_paths` — never change those files.
- When a change touches sensitive paths, present a dry-run and require a human reviewer.

If you are implementing an automation that must modify a sensitive file, include an audit
log, a vault-backed credential flow, and a clear rollback plan in the PR description.
