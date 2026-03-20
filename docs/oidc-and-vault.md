---
title: OIDC, Vault, and Secure GitHub Integration
description: Long-form guide for replacing long-lived OCI keys with OIDC, Vault brokering, and safe secret sharing strategies.
---

# OIDC, Vault, and Secure GitHub Integration

This long-form guide explains how to replace long-lived OCI API keys with modern, short-lived, auditable authentication flows for GitHub Actions, Codespaces, and local developer environments. It covers two main patterns:

- Direct OIDC federation (GitHub → Cloud provider) where supported.
- OIDC-to-Vault broker pattern (recommended for maximum control).

It also explains organizational options (org-level secrets, Environments), operational best practices (rotation, least privilege, auditing), and migration checklists.

## Motivation and threat model

Long-lived private keys (API keys, PEMs) are convenient but risky: if leaked, they grant ongoing access. Modern approaches reduce blast radius by using short-lived credentials, identity federation (OIDC), and a broker (Vault) to centralize policy, rotation, and auditing.

This guide assumes you want automated, reviewable CI/CD (GitHub Actions), reproducible developer environments (Codespaces / devcontainers), and the ability to securely share access across repositories or teams.

## Pattern A — Direct OIDC federation (cloud provider trusts GitHub)

Overview
:
GitHub Actions can mint an OpenID Connect (OIDC) token at runtime. Cloud providers that accept GitHub's OIDC tokens can exchange them for short-lived credentials or map them to a dynamic principal. The flow eliminates the need to store a long-lived private key in GitHub.

High-level steps
:
1. Create an Identity Provider or Federation Trust in the cloud that accepts GitHub's OIDC issuer (`https://token.actions.githubusercontent.com`).
2. Configure a role/mapper that inspects token claims (repository, branch, workflow, environment) and maps them to a cloud principal.
3. Assign least-privilege policies/permissions to that mapped principal.
4. In GitHub Actions, request an OIDC token for the job and exchange it for short-lived credentials.

Notes
:
- Direct federation is ideal where the cloud's IAM supports fine-grained claim mappings. In OCI, consider configuring an external identity provider or dynamic-group mapping if available. Cloud vendor-specific steps vary — consult the cloud provider's federation docs.

## Pattern B — OIDC → Vault broker (recommended)

Overview
:
Use GitHub Actions OIDC tokens to authenticate to a Vault instance (HashiCorp Vault or managed equivalent). Vault then returns short-lived credentials or a scoped secret (for example, an OCI API key) with a TTL. This centralizes policy, rotation, and auditing and allows teams to manage secrets centrally.

Why use Vault as a broker
:
- Centralized policy and auditability.
- Lease TTLs and automatic revocation.
- Versioned secrets and controlled access per role.

Vault broker architecture
:
1. GitHub Actions requests an OIDC token from GitHub's runtime.
2. The workflow exchanges that OIDC token for a Vault token by logging in to the Vault JWT/OIDC auth method.
3. Vault policies restrict which secrets the role can access and for how long.
4. Vault returns a short-lived token or directly returns secret payloads (the OCI private key or a temporary credential).

Detailed Vault setup (conceptual)
:
1. Provision Vault with TLS and audit logging.
2. Enable the JWT/OIDC auth method in Vault.
3. Create a Vault role that trusts GitHub's issuer and binds expected claims (repository, environment).
4. Create a Vault policy that grants read access to the secret path containing the OCI key.
5. Store the OCI private key in Vault at a well-known path and use ACLs/policies to control access.

Example (conceptual) Vault commands
:
```bash
vault auth enable jwt

vault write auth/jwt/role/github-actions \
  role_type="jwt" \
  bound_issuer="https://token.actions.githubusercontent.com" \
  user_claim="sub" \
  bound_repository="andiekobbietks/my-oracle-cloud-workspace" \
  policies="ci-oci-read"

vault policy write ci-oci-read - <<'EOF'
path "secret/data/oci/keys/my-repo" {
  capabilities = ["read"]
}
EOF
```

Important notes
:
- Use `bound_repository` and additional claim checks to limit what workflows can authenticate.
- Prefer short TTLs on Vault tokens and short-lived secret leases when possible.

Example GitHub Actions workflow (Vault broker)
:
This workflow illustrates authenticating to Vault using the GitHub OIDC token, fetching the OCI key, writing it to `~/.oci/oci_api_key.pem`, using it, and cleaning it up.

```yaml
name: oci-with-vault
on:
  workflow_dispatch:
  push:
    branches: [ main ]

jobs:
  run-oci:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Request OIDC token from GitHub
        id: idtoken
        run: |
          # GitHub automatically provides the token via the environment helpers
          echo "ID_TOKEN<<$(curl -sS --fail \"$ACTIONS_ID_TOKEN_REQUEST_URL\" -H \"Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN\")" >> $GITHUB_OUTPUT

      - name: Vault login with OIDC
        id: vault-login
        env:
          VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
        run: |
          set -euo pipefail
          ID_TOKEN=$(jq -r '.value' <<<"${{ steps.idtoken.outputs.ID_TOKEN }}")
          # Exchange OIDC token for Vault token
          VAULT_JSON=$(curl -sS -X POST "$VAULT_ADDR/v1/auth/jwt/login" -d '{"jwt":"'"$ID_TOKEN"'","role":"github-actions"}')
          VAULT_TOKEN=$(jq -r .auth.client_token <<<"$VAULT_JSON")
          echo "VAULT_TOKEN=$VAULT_TOKEN" >> $GITHUB_ENV

      - name: Fetch OCI key from Vault
        env:
          VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
          VAULT_TOKEN: ${{ env.VAULT_TOKEN }}
        run: |
          set -euo pipefail
          mkdir -p ~/.oci
          KEY_JSON=$(curl -sS -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/secret/data/oci/keys/my-repo")
          echo "$KEY_JSON" | jq -r .data.data.private_key > ~/.oci/oci_api_key.pem
          chmod 600 ~/.oci/oci_api_key.pem

      - name: Run OCI commands
        run: |
          oci os ns get

      - name: Cleanup OCI key
        if: always()
        run: |
          shred -u ~/.oci/oci_api_key.pem || rm -f ~/.oci/oci_api_key.pem || true
```

Notes on the example
:
- The workflow authenticates to Vault using the GitHub OIDC token. Vault returns a short-lived token scoped to the `ci-oci-read` policy.
- The secret is written to disk only for the job lifetime and then shredded.

## Sharing and gating: org-level secrets and Environments

Repo secrets
:
- Tied to a single repository. Easy to set and use in Actions and Codespaces for that repo.

Organization-level secrets
:
- Shared across multiple repositories. Useful when the same secret should be available to many repos. Requires organization admin rights to create.

Environments (repo-level feature)
:
- Environments let you gate access (e.g., require reviewers before a workflow can access secrets tied to an environment). Use Environments to protect production-level secrets behind manual approvals.

Recommended patterns
:
- Use Vault + OIDC for most CI workloads (no long-lived keys in GitHub).
- Use org-level secrets only for non-sensitive, cross-repo configuration or when Vault is unavailable.
- Use Environments to protect production operations and require approvals before secrets are exposed.

## Local developer and Codespaces behavior

Local machines
:
- Repo secrets are not available locally. Developers must authenticate once locally (generate/upload an OCI key, configure `~/.oci/config`) or use an interactive flow to get credentials.

Codespaces / devcontainers
:
- Codespaces can be configured to expose repository or organization secrets to the container. If the devcontainer `postCreateCommand` writes the secret into `~/.oci/oci_api_key.pem`, new Codespaces can run `oci` commands immediately.
- Security tradeoff: that file exists in the Codespace filesystem; prefer short-lived keys or a cleanup step.

## Operational best practices

- Rotate keys regularly and automate rotation where possible (see `docs/key-rotation.md`).
- Use least-privilege IAM roles for CI: only grant the exact permissions required.
- Audit every access: Vault audit logs, cloud audit logs, and GitHub Actions logs.
- Use TTLs for Vault tokens and short leases for returned secrets.
- Protect workflows (use `permissions` and `environments`) to limit which jobs can request sensitive secrets.

## Migration checklist

1. Inventory consumers that use the long-lived key.
2. Provision Vault or confirm cloud federation capabilities.
3. Implement the Vault role + policy or cloud federation role.
4. Update GitHub workflows to use OIDC + Vault or OIDC direct exchange.
5. Run canary workflows and smoke tests.
6. Revoke old keys once the new flow is validated.

## References & further reading

- HashiCorp Vault JWT/OIDC auth method documentation
- GitHub Actions OIDC documentation: using `id-token` permission
- Cloud provider federation docs and STS/OAuth APIs

---

File: docs/oidc-and-vault.md
