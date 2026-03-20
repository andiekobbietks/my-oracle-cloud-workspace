#!/usr/bin/env bash
set -euo pipefail
# Store an OCI private key PEM into Vault KV v2. Usage:
# VAULT_ADDR=https://vault.example.com VAULT_TOKEN=<token> ./scripts/vault/store_oci_key_in_vault.sh /path/to/oci_api_key.pem

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 /path/to/oci_api_key.pem" >&2
  exit 2
fi

KEYFILE=$1
if [ ! -f "$KEYFILE" ]; then
  echo "Key file not found: $KEYFILE" >&2
  exit 3
fi

KEY_CONTENT=$(sed 's/\\/\\\\/g; s/"/\\"/g' "$KEYFILE")
vault kv put secret/oci/keys/my-repo private_key=@$KEYFILE
echo "Stored $KEYFILE at secret/oci/keys/my-repo"
