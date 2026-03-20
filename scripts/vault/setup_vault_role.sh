#!/usr/bin/env bash
set -euo pipefail
# Example helper to create a Vault JWT role and policy for GitHub Actions
# Usage: VAULT_ADDR=https://vault.example.com VAULT_TOKEN=<root-or-admin-token> ./scripts/vault/setup_vault_role.sh

ROLE_NAME=${ROLE_NAME:-github-actions}
REPO=${REPO:-andiekobbietks/my-oracle-cloud-workspace}
SECRET_PATH=${SECRET_PATH:-secret/data/oci/keys/my-repo}

echo "Creating Vault role '$ROLE_NAME' bound to repo '$REPO' and policy 'ci-oci-read'"

vault auth enable -path=jwt jwt || true

vault write auth/jwt/role/$ROLE_NAME \
  role_type="jwt" \
  bound_issuer="https://token.actions.githubusercontent.com" \
  user_claim="sub" \
  bound_repository="$REPO" \
  policies="ci-oci-read"

cat <<'EOF' > /tmp/ci-oci-read-policy.hcl
path "${SECRET_PATH}" {
  capabilities = ["read"]
}
EOF

vault policy write ci-oci-read /tmp/ci-oci-read-policy.hcl
rm -f /tmp/ci-oci-read-policy.hcl

echo "Vault role and policy created. Store your OCI key at: $SECRET_PATH"
