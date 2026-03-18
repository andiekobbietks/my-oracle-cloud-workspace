---
title: oci-bootstrap
name: oci-bootstrap
description: 'Idempotent Always Free-aware OCI resource bootstrap; trigger: "Run oci-bootstrap for demo"'
summary: Create minimal OCI resources (compartments, VCN, vaults) with idempotent plans and dry-run support
tags:
  - oci
  - bootstrap
  - terraform
usage: |
  Use this skill to provision minimal OCI resources for demos or CI smoke-tests. Always run in `dry_run` first.
applyTo:
  - terraform/**
  - infra/**
  - scripts/**
inputs:
  - name: compartment
    required: true
    description: Target compartment OCID or name
  - name: resources
    required: false
    description: List of resources to create (vcn, subnet, vault, gateway)
  - name: dry_run
    required: false
    default: true
    description: If true, show a plan without applying changes
outputs:
  - name: plan
    description: A human-readable plan of intended changes
related:
  - .github/skills/smoke-test/SKILL.md
  - docs/skills/oci-bootstrap.md
---

Purpose
Automate creation and initial configuration of a minimal OCI environment needed to run or test repository workloads. Provides idempotent behavior, explicit dry-run plans, and guidance for secure handling of outputs and credentials.

Steps
1. Validate OCI credentials and region availability.
2. Discover existing resources and compute a minimal delta for requested `resources`.
3. Present a plan in `dry_run` mode and require `confirm=yes` to apply.
4. If confirmed, apply changes idempotently and record outputs (OCIDs, endpoints) to a vault or credential store per `vault-integration` guidance.
5. Run smoke tests against created resources and report status.

Notes
- Always prefer `dry_run` and require explicit human confirmation for destructive actions.
- Do not write private keys or raw credentials into repository files; use a vault.

Completion criteria
- Requested OCI resources exist and pass basic reachability checks; access details stored securely and documented.
