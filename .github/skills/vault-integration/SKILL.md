---
title: vault-integration
name: vault-integration
description: 'Integrate a vault or credential store with skills and CI for secure
  credential management; trigger: "Run vault-integration"'
summary: Patterns and safe practices for writing, reading, and bootstrapping credentials
  in a managed vault
tags:
- vault
- credentials
- ci
usage: 'Use this skill to securely store and retrieve credentials. Example: `backend:
  oci-vault`, `path: vault/data/app/ci`, `dry_run: true`

  '
applyTo:
- infra/**
- .github/workflows/**
- scripts/**
inputs:
- name: backend
  required: true
  description: Vault backend type (e.g., `vault`, `oci-vault`)
- name: path
  required: true
  description: Credential path or mount (e.g., vault/data/myapp)
- name: dry_run
  required: false
  default: true
  description: Preview writes and policy changes without applying
outputs:
- name: credential_ref
  description: Canonical reference to stored credential
related:
- .github/skills/key-rotation/SKILL.md
- docs/skills/vault-integration.md
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
Standardize secure access to credential stores, bootstrap policies/roles, and safely write/read credentials required by repo automation and CI.

Steps
1. Authenticate to the backend using the provided `auth` method.
2. Validate `path` and present a masked diff in `dry_run`.
3. Create or update credentials atomically and set appropriate metadata and TTLs.
4. Optionally create policies/roles and grant least-privilege access to CI principals.
5. Verify consumers can read the credential and record audit evidence.

Agent guidance
- Never echo plaintext credentials in logs; always show masked diffs in dry-run.
- Prefer short-lived credentials and role-based access for CI.

Completion criteria
- Credentials are written and readable by intended consumers; audit entries recorded and documented.
