---
title: OIDC 12 Vault: Admin Setup and Runbook
description: Step-by-step guide for admins to provision Vault roles, policies, and store OCI keys for GitHub Actions OIDC-based access.
---

# OIDC 12 Vault: Admin Setup and Runbook

This document gives concrete commands and an operational checklist to provision a Vault role and policy that trust GitHub Actions OIDC tokens, store OCI private keys into Vault, and test the GitHub Actions workflow that retrieves them.

Warning: these commands require Vault admin privileges and a secure network path to the Vault cluster. Use TLS and enable Vault audit logging in production.

## Architecture (Mermaid)

```mermaid
graph LR
  A[GitHub Actions Job] -->|request id-token| B(GitHub OIDC endpoint)
  B -->|ID token| C[Vault JWT/OIDC Auth]
  C -->|vault token| D[Vault (KV v2) Secret Path]
  D -->|private_key value| E[Action writes ~/.oci/oci_api_key.pem]
  E -->|uses| F[OCI CLI]
  C -->|audit| G[Vault Audit Logs]
```

## Prerequisites

- Vault server reachable (VAULT_ADDR) and admin token available (use a short-lived bootstrap token).
- `vault` CLI installed and authenticated as an admin for initial setup.
- GitHub repository admin privileges to add repository secrets (VAULT_ADDR, role name if needed).

## 1) Enable the JWT auth method in Vault

Run as a Vault admin (replace VAULT_ADDR and VAULT_TOKEN with your values):

```bash
export VAULT_ADDR=https://vault.example.com
export VAULT_TOKEN=<VAULT_ADMIN_TOKEN>

# enable the jwt auth mount if not already enabled
vault auth enable -path=jwt jwt || true
```

## 2) Create policy that grants read access to the OCI key

```bash
cat > /tmp/ci-oci-read.hcl <<'EOF'
path "secret/data/oci/keys/my-repo" {
  capabilities = ["read"]
}
EOF

vault policy write ci-oci-read /tmp/ci-oci-read.hcl
rm -f /tmp/ci-oci-read.hcl
```

## 3) Create a JWT role bound to GitHub Actions

Set the bound repository value to your repo (org/repo). This example binds to `andiekobbietks/my-oracle-cloud-workspace`.

```bash
vault write auth/jwt/role/github-actions \
  role_type="jwt" \
  bound_issuer="https://token.actions.githubusercontent.com" \
  user_claim="sub" \
  bound_repository="andiekobbietks/my-oracle-cloud-workspace" \
  policies="ci-oci-read" \
  ttl="1h"
```

Notes:
- `ttl` controls how long Vault tokens issued via this role live; choose short values for CI access.
- You can bind additional claims (branch, environment) using `bound_claims` or `bound_claim_keys` depending on Vault version.

## 4) Store the OCI private key into Vault (KV v2)

Use the `vault kv put` or `vault kv metadata` commands. Example:

```bash
vault kv put secret/oci/keys/my-repo private_key=@/path/to/oci_api_key.pem
```

Verify the secret exists:

```bash
vault kv get secret/oci/keys/my-repo
```

## 5) Add required GitHub repository secrets

In the repository settings (or via GitHub API), add the following secrets:

- `VAULT_ADDR` 12 URL of the Vault server (e.g., https://vault.example.com)
- `VAULT_ROLE` 12 the Vault role name you created (e.g., `github-actions`) (optional; you can hardcode in workflows)

If you prefer not to expose `VAULT_ADDR` as a secret, the workflow can reference an organization-level secret or environment.

## 6) Test the login flow inside a GitHub Actions job

The reliable way to test the full exchange is to run the sample workflow `.github/workflows/oidc-vault.yml` that was added to this repo. The job:

- requests the OIDC ID token from GitHub
- exchanges it for a Vault token using the `auth/jwt/login` endpoint
- reads `secret/data/oci/keys/my-repo` and writes the `private_key` to `~/.oci/oci_api_key.pem`
- runs an example `oci` command and cleans up the key

Trigger the workflow using the GitHub UI -> Actions -> OIDC + Vault CI -> Run workflow.

## 7) Hardening & production checklist

- Enable Vault audit logging and ship logs to a secure SIEM.
- Restrict the `github-actions` role with tight claim bindings (repo, branch, environment).
- Apply short TTLs for issued Vault tokens and short leases for secrets.
- Use Vault namespaces or paths per-project to isolate secrets.
- Require manual approvals via GitHub Environments for sensitive deploy jobs.

## 8) Troubleshooting

- Vault `permission denied` on read: check policy and role binding.
- `ID token` empty in Actions: ensure `permissions: id-token: write` is set in the workflow and GitHub provides the token in newer runners.
- `oci` errors: confirm `~/.oci/config` is populated correctly (tenancy/user/fingerprint/key_file).

## 9) Next steps for automation

- Automate rotation: use a scheduled job to rotate the Vault secret version and update consumers.
- Consider dynamic secrets: if your cloud provider supports dynamic short-lived credentials via Vault, use that instead of storing PEMs.

---

File: docs/oidc-vault-setup.md
