# Security origins, provenance, and first-instance history

This file records the provenance and background for the security work in this repository: why the relocate workflow, validator, and key-rotation tooling were created, and the earliest action that started the effort.

Quick provenance summary
-----------------------
- First trigger: a request to move `.devcontainer/README.md` into the repository root and to generalize the relocation workflow. That request expanded into a broader effort to make relocations auditable, reversible, and safe.
- Follow-on work: design and implementation of the `relocate-file` SKILL and `run-relocate` wrapper; `scripts/relocate-dryrun.sh` and `scripts/relocate-apply.sh`; validator `tools/validate_skill.py` to validate SKILL frontmatter and referenced assets.
- Security-focused additions: non-interactive OCI installer (`scripts/install-oci-noninteractive.sh`), bootstrap example, exhaustive `docs/key-rotation.md`, and the `scripts/rotate-oci-key.sh` rotation skeleton.

Expanded provenance & influences
--------------------------------
- Community security frameworks: Recommendations in these docs draw directly from community-maintained guidance such as OWASP Top 10, OWASP ASVS, and OWASP Proactive Controls. Those projects (community-driven and updated periodically) provided the taxonomy and control objectives used to prioritise remediations (e.g., secret management, deployment hardening, and secure-by-default patterns).
- Operational story: The repo's early changes were focused on file relocation safety; as the team iterated, two recurring risks emerged: accidental secret exposure during file moves and brittle automation that could revoke keys without verification. Those risks drove the creation of `tools/validate_skill.py` and `scripts/rotate-oci-key.sh`.
- Technical influences: Patterns used here reflect broader DevSecOps evolution — shift-left validation in CI, declarative infrastructure practice (Terraform), and secret managers (Vault/OCI Vault) for lifecycle and rotation.

Why these security controls were added
------------------------------------
- Risk of secret leakage: moving files or adding bootstrap scripts can accidentally expose API keys or private config. Validator and secret-detection were added to reduce this risk.
- Operational safety: `dry-run` by default, `CONFIRM=yes` guard, and `git bundle` backups were added to prevent accidental destructive operations.
- Key management: long-lived API keys were identified as a risk, so rotation guidance, sample automation, and Vault placeholders were added.

Sources and references
----------------------
- Security frameworks referenced in this repo and docs:
  - OWASP Top 10 — web application risks and threat taxonomy: https://owasp.org/www-project-top-ten/
  - OWASP ASVS — detailed verification controls: https://owasp.org/www-project-application-security-verification-standard/
  - OWASP Proactive Controls — developer-focused secure practices: https://owasp.org/www-project-proactive-controls/
- OCI documentation references (concepts used throughout docs): https://docs.oracle.com/en-us/iaas/Content/home.htm

First-instance timeline (local)
-----------------------------
- Initial user request (local): move `.devcontainer/README.md` to repo root and document the relocation steps. This is the recorded origin in the repository work that led to the relocate SKILL and supporting artifacts.
- Immediate follow-ups: dry-run/apply scripts, Makefile targets, SKILL frontmatter, and validator to ensure relocations are safe.
- Security evolution: as the relocation and bootstrap scripts were added, the key-rotation and Vault guidance were introduced to address API key lifecycle risks.

Additional timeline notes
------------------------
- Validator addition: shortly after the relocate SKILL was scaffolded, the validator was added to ensure consistent SKILL frontmatter, detect referenced assets, and run a basic secret scan. This mirrors common patterns in teams adopting doc-as-code, where machine checks prevent accidental policy violations.
- Key rotation and Vault guidance: After adding imperative bootstrap and installer scripts, the team recognised the need for a rotation story for long-lived OCI API keys and added `docs/key-rotation.md` and `scripts/rotate-oci-key.sh` as a conservative, auditable starting point.

How this file should be used going forward
----------------------------------------
- Keep this provenance file updated with dates/PR numbers when major security decisions happen (e.g., Vault integration, CI gating). This creates a useful audit trail for reviewers and auditors.

How to use these notes
----------------------
- Treat this file as living documentation — update it if the project's origin story or security controls change.
- When onboarding auditors or reviewers, link them to `docs/owasp-mapping.md`, `docs/key-rotation.md`, and the SKILL files for concrete examples.
