---
title: credential-detection
name: credential-detection
description: 'Scan the repository for accidental credentials or high-entropy strings;
  trigger: "Run credential-detection"'
summary: Detect exposed credentials, classify findings, and recommend remediation
  (rotate, remove, vault)
tags:
- secrets
- detection
- security
usage: 'Run credential-detection to locate high-confidence credential patterns and
  suggest remediation.

  Example: "Run credential-detection on path .github to find exposed credentials"

  '
applyTo:
- '**/*'
- .github/**
- scripts/**
inputs:
- name: path
  required: false
  default: .
  description: Path to scan
- name: tools
  required: false
  default:
  - gitleaks
  description: Scanning tools to run
outputs:
- name: findings
  description: JSON list of findings with classification and suggested action
related:
- tools/validate_skill.py
- docs/skills/credential-detection.md
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


Purpose
Locate high-confidence credential patterns and provide actionable remediation steps: rotate, remove, migrate to vault, or rewrite history with a safe plan.

Steps
1. Run pattern and entropy-based scans using configured tools.
2. Classify findings by confidence and exposure (public, internal, CI only).
3. Produce a remediation plan: rotate affected credentials, remove files, and update consumers.
4. For historical leaks, provide an optional safe history-rewrite plan and notify maintainers.

Agent guidance
- Mask any proof-of-exposure when sharing publicly; include only minimal masked samples in reports.
- For confirmed leaks, advise rotation before public disclosure and document the rotation plan.

Completion criteria
- No high-confidence credentials remain unaddressed OR a documented remediation plan is in place and tracked.
