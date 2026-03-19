# OCI Bootstrap Agent

Overview
--------
This document explains the `oci-bootstrap` agent: its purpose, inputs, outputs,
security guidance, and runbook. The agent automates idempotent bootstrapping of
OCI resources (compartment, VCN, subnets, vault, optional compute) using the
OCI CLI. It defaults to dry-run and requires explicit human confirmation to apply.

Runbook (short)
---------------
1. Ensure OCI credentials are available (preferred: Codespace secrets or local `~/.oci`).
2. Run `scripts/check-free-resources.sh <compartment-ocid>` to inventory Always Free resources.
3. Run `scripts/oci-bootstrap.sh --compartment <ocid> --resources vcn,compute --dry-run` to generate a plan.
4. Review `outputs/oci-bootstrap/plan-*.json` and open a PR for operator review.
5. To apply: an authorized operator runs the script with `--apply` after approvals.

Security
--------
- Never commit private keys or raw credentials to the repo.
- Store secrets in a vault or GitHub Actions secrets and prefer IAM federation for production.

Related
-------
- `.github/skills/oci-bootstrap/SKILL.md`
- `scripts/oci-bootstrap.sh`
- `scripts/check-free-resources.sh`
