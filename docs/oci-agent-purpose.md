# OCI Bootstrap Agent — Purpose and Rationale

This document explains why the `oci-bootstrap` agent, related scripts, SKILLs,
prebuild wizard, and CI workflow exist, what problems they solve, and how they
fit together. It is written for engineers, reviewers, and maintainers.

Purpose (short)
---------------
Provide a safe, repeatable, and auditable way to bootstrap minimal OCI
environments (compartment, VCN, subnets, vault, optional compute) using the
OCI CLI as a first step, with a clear migration path to Terraform + OCI
Resource Manager and IAM federation for production.

Problems addressed
------------------
- Knowledge silos: captures exact steps and parameters so any engineer can run
  the same bootstraps without tribal knowledge.
- Risk of accidental change: defaults to `dry_run` and produces machine-readable
  plans and human summaries rather than immediately mutating cloud resources.
- Auditability: plan outputs (JSON) and CI artifacts provide an evidence trail
  for what was intended and executed.
- Security mistakes: enforces atomic writes of credentials, permission hardening,
  and guidance to prefer vaults or federation instead of committing keys.
- Cost control: quick inventory commands and Always‑Free checks avoid
  accidentally provisioning costly resources.

Components and responsibilities
-------------------------------
- `docs/`: explains policies, SOPs, and the agent's purpose (this file).
- `.github/skills/oci-bootstrap/SKILL.md`: machine-readable operational intent
  and guidance for agents (inputs, outputs, dry_run semantics, do_not_edit_paths).
- `.github/agents/oci-bootstrap.agent.md`: persona/manifest used by agents to
  identify the bootstrap capability and its inputs/outputs.
- `scripts/oci-bootstrap.sh`: lightweight CLI wrapper that performs idempotent
  discovery and writes a plan (JSON) for review — never performs destructive
  apply automatically.
- `scripts/check-free-resources.sh`: quick audit to list Always‑Free resource
  types in a compartment.
- `.devcontainer/setup-oci.sh`: prebuild “wizard” that verifies secrets, installs
  OCI CLI, writes credentials atomically, and runs a connectivity test.
- `.github/workflows/oci-bootstrap-dryrun.yml`: CI job that runs the non-destructive
  audits and emits artifacts; it is configured manual-only and concurrency-safe.

What the prebuild wizard does (detailed)
----------------------------------------
1. Detects whether `OCI_CONFIG_CONTENT` and `OCI_PRIVATE_KEY` secrets are set.
   - If missing, it prints clear instructions and exits gracefully so the
     Codespace can start and the operator can add secrets.
2. Installs the OCI CLI (with retry) if not present.
3. Writes credentials atomically to `$HOME/.oci` using a temp directory and
   `mv` to avoid half-written files.
4. Restricts file permissions (600) on the private key and config.
5. Updates `key_file` paths inside the config to match the runtime user.
6. Runs a minimal connectivity test (`oci os ns get`) and reports status.

Security posture and recommendations
------------------------------------
- Short term (what this repo uses): GitHub Actions secrets and Codespace
  secrets. These are encrypted at rest but still represent long-lived tokens —
  rotate regularly and keep minimal scopes.
- Medium term (recommended): use OCI Resource Manager (ORM) and OIDC federation
  so CI can authenticate without long-lived API keys.
- Long term (enterprise): federate corporate IdP → map groups to OCI policies;
  use short-lived tokens and centralize state in Terraform Cloud or ORM.
- Never commit private keys or raw credentials to the repo; the prebuild wizard
  enforces atomic writes and permissions to reduce accidental leaks.

Operational workflow (how to use)
--------------------------------
1. Operator obtains one-time OCI API key and config in the OCI Console.
2. Operator adds secrets to the repo (Actions secrets or Codespace secrets).
3. Operator triggers the prebuild wizard (Codespace rebuild) or runs the
   `scripts/check-free-resources.sh` locally to audit Always‑Free resources.
4. Operator runs `scripts/oci-bootstrap.sh --compartment <ocid> --resources vcn,compute --dry-run`.
5. Review the generated plan in `outputs/oci-bootstrap/plan-*.json` and open a
   PR for discussion if changes are needed.
6. After approvals, authorized operator runs the apply flow (subject to a
   human `confirm_phrase` and policy gating) — this repository intentionally
   prevents unattended destructive applies.

Next steps and migration path
-----------------------------
Short-term: continue improving SKILL docs and add smoke tests that validate
created resources.  
Medium-term (Phase 2): extract Terraform modules under `infra/oci/bootstrap/`,
publish them as an ORM stack, and use GitHub Actions with OIDC to run ORM jobs
without long-lived keys.  
Long-term (Phase 3): establish IdP federation, map groups to OCI policies,
implement automated key rotation and centralized state management (Terraform
Cloud or ORM) for multi-client scale and compliance.

How to contribute
------------------
- Improve docs under `docs/` and update `AGENTS.md` index so retrieval-led
  reasoning finds the right content.  
- Add Terraform modules into `infra/` and provide a `terraform.zip` for ORM.
- Implement smoke tests in `tests/` and wire them into a gated workflow.

Questions? File an issue or open a PR with suggested edits to this document.
