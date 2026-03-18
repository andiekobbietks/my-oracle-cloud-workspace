# Key Rotation — deep doc

Guidance for rotating OCI API keys and other long-lived credentials with minimal disruption.

Principles
----------
- Canary first: stage in a low-impact environment or service.
- Automate verification: use smoke-tests to validate new credentials.
- Backup and rollback: keep previous keys for immediate rollback.

Steps
-----
1. Generate new keypair and store private key in Vault.
2. Attach new public key to automation user.
3. Run smoke-test with the canary service.
4. If successful, propagate new key to the rest of services and revoke old key.
# Key Rotation — deep doc

This doc expands the `key-rotation` Skill with background, implementation notes, CI examples, OWASP/ASVS mapping, and rollout patterns.

See also: [scripts/rotate-oci-key.sh](scripts/rotate-oci-key.sh) and [docs/key-rotation.md](docs/key-rotation.md).

Background & rationale
----------------------
- Why: long-lived API keys are a frequent root cause of breaches and accidental exposure. Automating rotation reduces windows of exposure and ensures a reproducible verification pattern.
- Origin: started from a request to make relocations safe; evolved when bootstrap scripts and installers introduced more long-lived keys into CI/dev workflows.

Implementation notes
--------------------
- Use the `key-rotation` Skill to drive `scripts/rotate-oci-key.sh` in a controlled, staged manner.
- Integrate `vault-integration` to persist private keys; do NOT store private keys in repo or logs.
- Prefer canary deployments (staged=true) and smoke-tests after each stage.

CI Example (GitHub Actions)
---------------------------
Use a scheduled job that invokes the Skill via a runner script that calls `scripts/rotate-oci-key.sh` and then `make smoke-test` for verification. Store secrets in Actions secrets or an OCI Vault connector.

OWASP / ASVS mapping
--------------------
- OWASP Top10: A02 Cryptographic Failures, A09 Logging & Monitoring
- ASVS: v5.0.0-V6 (Cryptography & Secrets)

Rollout checklist
-----------------
- Dry-run plan attached to PR.
- Backup: keep a fallback secret/version available for a bounded window.
- Notify: Ops + security channels and run smoke-tests.
