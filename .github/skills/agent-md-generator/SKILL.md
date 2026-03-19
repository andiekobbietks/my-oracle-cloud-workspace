---
name: agent-md-generator
title: Agent MD Generator
summary: Generate .agent.md files from interactive templates.
description: 'Interactive skill that scaffolds `.agent.md` (agent metadata) files
  using a small questionnaire and reusable templates. Example invocation: "Generate
  agent.md for infra-deployer". Designed for maintainers who want consistent agent
  metadata files created via prompts or automation.'
applyTo:
- repository
usage: "Trigger examples:\n  - \"Generate agent.md for payment-worker\"\n  - \"Create\
  \ an agent file named build-agent (dry-run)\"\n"
inputs:
- name: agent_name
  type: string
  description: Short identifier for the agent (e.g., build-worker)
- name: description
  type: string
  description: One-line description of the agent's purpose
- name: template_choice
  type: string
  description: 'Template to use (default: standard)'
outputs:
- name: path
  type: string
  description: Path to the generated `.agent.md` file
related:
- .github/skills/agent-customization/SKILL.md
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


This SKILL generates an `.agent.md` file from a small interactive flow or
from provided inputs (for automation). It avoids storing credentials and is
safe to run in CI when used with `dry_run`.

Behavior:
- If `dry_run` is set (default for interactive runs), the skill prints the
  generated content and the intended path without writing files.
- When `apply=true` the skill writes the file to the repository and returns
  the path.

Template (default):

```
---
name: {{agent_name}}
description: "{{description}}"
maintainer: ""
triggers:
  - "example trigger phrase"
---

## Purpose

Describe what this agent does, invocations, and any important notes.

## Verification

- Smoke-test steps
- Expected outputs
```

Examples:
- `Generate agent.md for infra-deployer` — interactive prompts for fields
- `Generate agent.md for infra-deployer --apply` — actually writes file

Safety:
- Never prompt for or store credentials. If a credential is needed, store in a
  vault and reference a path instead.

Implementation hints for integrators:
- Provide a CLI wrapper that accepts `--agent-name`, `--description`,
  `--template`, and `--apply`/`--dry-run` flags.
