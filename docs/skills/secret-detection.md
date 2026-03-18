# Secret Detection — deep doc

This document describes how the `secret-detection` Skill scans the repository for high-confidence secrets and suggests remediation actions.

Approach
--------
- Start with regex-based heuristics for common API keys and private keys.
- Use entropy checks for base64-like strings.

Remediation
----------
- If a secret is found: rotate it, purge from history (git-filter-repo), and replace with Vault reference.
# Secret Detection — deep doc

This doc expands the `secret-detection` Skill with scanner choices, false-positive handling, and remediation playbooks.

Scanner recommendations
-----------------------
- `gitleaks` — fast repository scanner for patterns and high-entropy secrets.
- `git-secrets` — pre-commit style blocking of common secrets.
- `trufflehog` — deep history scanning for sensitive strings.

False positives and heuristics
-----------------------------
- Use filename heuristics to ignore known binary blobs and vendor directories.
- Use entropy thresholds plus pattern matches to reduce noise.
- Provide an explainable SR (suppress/resolve) workflow rather than blind ignores.

Remediation playbook
--------------------
1. Rotate exposed secrets immediately.
2. Remove secrets from history (use git-filter-repo) only after coordination and CI gating.
3. Update consumers and notify stakeholders.

CI Integration
--------------
- Run `secret-detection` as a required job on PRs to `main` and on a scheduled basis for history scans.
