---
title: key-rotation
name: key-rotation
description: "Rotate OCI API credentials and long-lived keys safely"
summary: Rotate API keys and other long-lived credentials with dry-run and staged verification
tags:
  - key-rotation
  - security
  - oci
usage: |
  Orchestrate credential replacement with `dry_run`, staged rollout, and verification.
applyTo:
  - scripts/**
  - rotate-*.sh
  - docs/**
inputs:
  - name: user_ocid
    required: true
    description: OCID of the automation user to rotate credentials for
  - name: dry_run
    required: false
    default: true
    description: If true, show a plan without applying changes
outputs:
  - name: rotation_plan
    description: Planned steps and verification checks for the rotation
related:
  - .github/skills/smoke-test/SKILL.md
  - docs/skills/key-rotation.md
---

Purpose
Provide a safe, auditable workflow to rotate credentials and keys used by the repository or CI pipelines. Supports dry-run planning, staged rollout, propagation to vaults or credential stores, and rollback guidance.

Steps
1. Discover consumers of the credential and produce a detailed plan.
2. Create replacement credentials and stage them for a canary consumer.
3. Run verification checks (see smoke-test) against the canary.
4. Promote to remaining consumers if verification passes.
5. Revoke or retire old credentials after verification or per policy.
6. If verification fails and rollback is enabled, revert consumers and revoke new credentials.

Examples
- Dry run: `resource: user/alice/apikey, method: replace, dry_run: true`
- Rotate and propagate: `resource: oci/user/ci-runner-key, propagate_to: [ci/vault/ci-runner], notify: devops@example.com`

Agent guidance
- Always present a dry-run when multiple consumers are found.
- Enumerate and ask for confirmation to update CI or production systems.
- Do not revoke old keys until verification passes or grace period elapses.

Completion criteria
- New key is active and consumers verified.
- Old key is removed or retained per policy with documented justification.
