---
name: oci-bootstrap-agent
title: OCI Bootstrap Agent
description: |
  Agent to perform idempotent OCI bootstraps (compartment, VCN, subnets, vault,
  optional compute) using the OCI CLI. Defaults to dry-run and requires human
  confirmation for applying changes. Provides a step-by-step runbook and audit
  artifacts.
inputs:
  - name: compartment
    description: Target compartment OCID or name
    required: true
  - name: resources
    description: List of resources to create (vcn, subnet, vault, compute)
    required: false
outputs:
  - name: report_path
    description: Path to the generated plan/report artifact
example_invocation: "Run oci-bootstrap (dry_run) and return report"
related: |
  See docs/oci-bootstrap-agent.md and .github/skills/oci-bootstrap/SKILL.md
---

This agent is a thin persona describing intent for automated bootstraps. Use
the `.github/skills/oci-bootstrap/SKILL.md` skill for implementation details
and `scripts/oci-bootstrap.sh` to run CLI-based bootstraps.
