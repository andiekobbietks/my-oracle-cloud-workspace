---
name: security-scan
title: Security Scan
description: |
  Run automated security and compliance scans against the repository to identify
  vulnerabilities, misconfigurations, and policy violations. Defaults to dry-run.
usage: |
  python3 tools/validate_skill.py .github/skills/security-scan/SKILL.md
  # Example invocation for agents: "Run security-scan (dry-run) and output report"
applyTo:
  - repository
inputs:
  code_path:
    description: Path to scan (relative to repo root)
    default: .
  scan_types:
    description: Which scanners to run (e.g. dependency, container, IaC)
    default:
      - dependency
      - container
      - iac
  dry_run:
    description: If true, do not modify code or create PRs
    default: true
outputs:
  report_path:
    description: Path to the generated scan report
    example: security-scan/report-2026-03-19.json
confirm_phrase: "I confirm apply"
do_not_edit_paths:
  - ".github/**"
  - "docs/**"
  - "scripts/**"
  - ".git/**"
  - ".devcontainer/**"
  - ".github/skills/**"
  - "README.md"
---

## Purpose

This SKILL runs a set of automated security scanners and produces a machine-readable
report and a human summary. It always defaults to `dry_run: true` and must be
explicitly applied by an authorized human with a matching `confirm_phrase`.

## Scanners (suggested)

- Dependency scanner (e.g., `pip-audit`, `npm audit`, `snyk`)
- Container image scanner (e.g., `trivy`)
- Infrastructure-as-Code scanner (e.g., `tfsec`, `checkov`)
- Static analysis for secrets (e.g., `git-secrets`, `detect-secrets`)

## Steps

1. Validate inputs and ensure `dry_run` is set unless `confirm_phrase` provided.
2. Run dependency scanner and collect results.
3. If repository contains containers, run container image scan.
4. Run IaC scanners on Terraform/CloudFormation files.
5. Run a secrets scan across the repo (non-destructive).
6. Aggregate results into `outputs.report_path` and produce a short markdown summary.
7. If `dry_run: false` and `confirm_phrase` matches, optionally open a PR with fixes
   or create follow-up tickets; otherwise only emit the report.

## CI Integration

- CI jobs should run this SKILL in `dry_run` mode on every push and produce an artifact
  `security-scan/report-<sha>.json` for triage.
- Apply flows that modify code must require human review and an explicit `confirm_phrase`.

## Audit

- Always attach the generated report and the exact scanner versions used as artifacts.
- Record the `confirm_phrase` and the acting principal in audit logs when applying changes.

## Examples

- Dry-run (default): run full scan and save report only.
- Apply (human): run scan, then with `dry_run: false` and `confirm_phrase` create PRs.

