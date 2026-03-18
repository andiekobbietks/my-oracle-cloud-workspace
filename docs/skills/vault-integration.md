# Vault Integration — deep doc

Guidance for integrating Vault or cloud secret stores with CI and skills.

Best practices
--------------
- Use least-privilege roles for CI and automation users.
- Prefer secret versioning and short-lived credentials.

CI Considerations
-----------------
- Inject secrets as environment variables at run-time via the runner's secret mechanism.
# Vault Integration — deep doc

Expands the `vault-integration` Skill with implementation patterns, policy examples, and ASVS mapping.

Overview
--------
- Purpose: ensure secrets are stored, versioned, and accessed securely by CI and runtime consumers.
- Supported backends: HashiCorp Vault, OCI Vault, cloud provider secrets stores.

Implementation patterns
-----------------------
- Auth: prefer instance principals or approle with short-lived tokens for automation.
- Policy: restrict read access to minimal principals and rotate service tokens frequently.
- Secrets lifecycle: write new versions, update pointers, and let consumers pull by version.

Example policy snippet (Vault, pseudo):

```
path "secret/data/myapp/*" {
  capabilities = ["create","read","update"]
}
```

OWASP / ASVS mapping
--------------------
- OWASP Top10: A02 Cryptographic Failures; A05 Misconfiguration
- ASVS: V6 (Secrets management), V11 (Deployment)

Operational notes
-----------------
- Mask logs during writes and reads in CI jobs.
- Audit: ensure vault audit devices or provider audit events are enabled and shipped to SIEM.
