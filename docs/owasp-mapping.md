# OWASP Mapping for repository artifacts

This document maps repository artifacts to OWASP Top 10, OWASP ASVS, and OWASP Proactive Controls, lists quick remediations, and gives an estimated effort to fix.

Summary
-------
- Scope: scripts/, tools/, Makefile, .github/skills/, docs/, .devcontainer/
- Date: created from the current repo state (see `docs/security-origins.md` for provenance)

Per-artifact mapping
--------------------

- `scripts/rotate-oci-key.sh` (scripts/rotate-oci-key.sh)
  - OWASP Top 10: A02 Cryptographic Failures; A05 Security Misconfiguration; A09 Security Logging & Monitoring
  - ASVS: V6 (Cryptography & Secret Management); V11 (Configuration/Deployment)
  - Proactive: C2 (Use Safe Defaults), C6 (Protect Data)
  - Quick remediation: integrate OCI Vault for private keys, avoid writing secrets to temporary files, add audit logging and explicit rollback checks.
  - Estimated effort: Medium
    - Historical context: Key rotation guidance and rotation scripts grew directly from operational incidents and industry practice around long-lived API keys. The repository's rotation skeleton codifies a conservative, audit-first pattern: generate new keys, verify consumers, then revoke old keys. This approach mirrors guidance from cloud providers and community playbooks that emphasise verification before revocation to avoid service interruption.
    - OWASP origin: The focus on cryptographic handling and secret storage maps to OWASP guidance in the Proactive Controls (Protect Data) and ASVS V6 recommendations about secure key storage and lifecycle management. These OWASP artifacts have long advised minimizing secret exposure and automating rotation where possible.

- `scripts/install-oci-noninteractive.sh` (scripts/install-oci-noninteractive.sh)
  - OWASP Top 10: A05 Security Misconfiguration; A02 Cryptographic Failures
  - ASVS: V11, V6
  - Proactive: C2, C7 (Automate Security Checks)
  - Quick remediation: require CI/host secret providers, validate installer checksums, set strict permissions on files.
  - Estimated effort: Small
    - Historical context: Non-interactive installers became common as CI, devcontainers, and Codespaces adoption increased; the pattern here reflects the need to provision developer/CI environments reproducibly while keeping secrets out of source control. The explicit permissioning and environment-variable patterns follow practices introduced by cloud onboarding guides.
    - OWASP origin: OWASP Proactive Controls and ASVS highlight deployment hardening and secure configuration; the remediation emphasizes avoiding insecure defaults and controlling secret injection points during automated provisioning.

- `scripts/bootstrap-example.sh` (scripts/bootstrap-example.sh)
  - OWASP Top 10: A05 Security Misconfiguration; A06 Vulnerable Components
  - ASVS: V11, V6
  - Proactive: C4 (Threat Model), C8 (Use Proven Libraries)
  - Quick remediation: remove embedded credentials, prefer Terraform for persistent infra.
  - Estimated effort: Small
    - Historical context: Bootstrap examples are intentionally minimal to demonstrate patterns; the guidance to prefer declarative IaC (Terraform) over imperative CLI commands follows infrastructure-as-code best practices that rose to prominence in the mid-2010s.
    - OWASP origin: Recommendations to avoid embedding credentials and to prefer idempotent, reviewable IaC maps to ASVS and Proactive Controls recommendations around secure deployment and reducing human error.

- `scripts/relocate-dryrun.sh` & `scripts/relocate-apply.sh`
  - OWASP Top 10: A05 Misconfiguration; A09 Logging & Monitoring; A08 Software and Data Integrity
  - ASVS: V10 (Integrity & CI/CD), V11
  - Proactive: C1 (Define Security Requirements), C7
  - Quick remediation: keep dry‑run default, run secret-detection before apply, require CONFIRM token (already present), add CI gate.
  - Estimated effort: Small–Medium
    - Historical context: The relocate workflow and its dry-run/apply split are rooted in classic change-control practices — preview, backup, apply, verify — that grew from site reliability engineering and secure ops playbooks. The `dry_run` default and `CONFIRM` gating aim to reduce human error in repository-wide refactors that historically caused outages or leaked configuration.
    - OWASP origin: Ensuring integrity and auditability of repository changes ties into ASVS and Proactive Controls that push for safe defaults, reviewable changes, and automated checks before deployment.

- `tools/validate_skill.py` (tools/validate_skill.py)
  - OWASP Top 10: A03 Injection (YAML handling) and A05 Misconfiguration
  - ASVS: V14 (Security Logging & CI), V11
  - Proactive: C7, C8
  - Quick remediation: improve secret regexes/entropy checks, add CI unit tests, fail CI on high confidence secrets.
  - Estimated effort: Small
    - Historical context: The validator emerged from the practical need to enforce structure and detect secrets as SKILLs and MCPs proliferated — a pattern seen in many projects that adopt doc-as-code. Practical validators and secret-grepping tools have been standard practice since automated CI pipelines became the norm.
    - OWASP origin: The validator's secret-detection and frontmatter checks align with OWASP Proactive Controls (automate security checks) and ASVS guidance for CI-level validation and logging.

- `Makefile` targets (Makefile)
  - OWASP Top 10: A09 Logging & Monitoring; A05 Misconfiguration
  - ASVS: V10, V11
  - Proactive: C7, C1
  - Quick remediation: enforce `make validate` in CI, gate `apply` behind PR approvals and pre-apply checks.
  - Estimated effort: Small
    - Historical context: Adding Make targets to wrap safe workflows (validate, dry-run, apply, backup) reflects a long-standing pattern of making complex operations reproducible and scriptable, dating back to Make-centric build tooling and the rise of automated CI/CD pipelines.
    - OWASP origin: Emphasises ASVS recommendations for integrating security checks into build pipelines and ensuring changes are auditable and reversible.

- `.github/skills/*` SKILLs
  - OWASP Top 10: A05 Misconfiguration; A09 Monitoring
  - ASVS: V11, V14
  - Proactive: C1, C7
  - Quick remediation: keep dry-run defaults, require explicit `confirm_token: yes`, define least-privilege for agents.
  - Estimated effort: Small
    - Historical context: Skills and agent-driven automation are recent repo-level patterns; the safety defaults mirror lessons learned from earlier automation incidents where scripts ran with elevated privileges without review.
    - OWASP origin: The recommended dry-run-first and confirm-token patterns reflect OWASP's broader advice to automate security checks and require human review for state-changing operations.

- `docs/` and `.devcontainer/`
  - OWASP Top 10: A04 Insecure Design, A05 Misconfiguration, A02 Cryptographic Failures
  - ASVS: V0-V1 (architecture & requirements), V11
  - Proactive: C1, C4
  - Quick remediation: add explicit threat-model excerpts, secure-by-default config examples, and reviewer checklists.
  - Estimated effort: Small
    - Historical context: Documentation and devcontainer lifecycle automation are included to reduce onboarding friction. The security-oriented edits reflect modern DevSecOps principles — shifting security left by embedding checks and secure defaults in developer tooling.
    - OWASP origin: Documents and secure-by-default snippets map to OWASP Proactive Controls and ASVS sections that encourage threat modelling and secure configuration documentation for maintainers.

Cross-cutting recommendations
-----------------------------
- Move private keys into a managed secrets store (OCI Vault or provider secrets) and never commit or log private keys.
- Add CI gates: run `tools/validate_skill.py`, secret scan, and smoke-tests before merging `apply` PRs.
- Prefer instance principals / dynamic groups to avoid long-lived user keys for compute workloads.
- Add audit logging for key uploads/deletes and alerts for unexpected changes.

References
----------
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP ASVS: https://owasp.org/www-project-application-security-verification-standard/
- OWASP Proactive Controls: https://owasp.org/www-project-proactive-controls/

If you want, I can open a PR with this file and link it from `docs/README.md`.
