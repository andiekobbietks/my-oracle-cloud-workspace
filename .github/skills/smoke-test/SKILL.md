---
title: smoke-test
name: smoke-test
description: "Quick verification checks to validate critical paths after changes. Trigger example: \"Run smoke-test target=service/api\""
summary: Fast, deterministic checks (connectivity, health endpoints, auth) to validate changes
tags:
  - smoke
  - test
  - verify
usage: |
  Run smoke-test to perform a small set of checks against newly provisioned resources. Example: `target: service/api`, `command: curl -sf http://localhost:8080/health`
applyTo:
  - tests/**
  - scripts/**
  - .github/workflows/**
inputs:
  - name: target
    required: true
    description: Resource or endpoint to validate
  - name: command
    required: true
    description: Shell command or script to run as the test
  - name: timeout
    required: false
    default: 30s
    description: Maximum duration per test
outputs:
  - name: status
    description: pass/fail results and logs
related:
  - .github/skills/oci-bootstrap/SKILL.md
---

Purpose
Execute minimal, fast checks that validate whether a service or change is functioning and reachable after deployment or configuration changes.

Steps
1. Validate `command` and setup environment variables.
2. Run command with `timeout` and optional `retries`.
3. Capture and normalize output; return pass/fail and relevant logs.
4. On failure, return structured data to drive remediation or rollback.

Agent guidance
- Keep smoke-tests focused and fast; deeper coverage belongs in full test suites.
- Return clear failure diagnostics: what failed, stdout/stderr snippets, and suggested next steps.

Completion criteria
- Command exits success within `timeout` (or allowed retries); logs attached for review.
