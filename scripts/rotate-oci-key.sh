#!/usr/bin/env bash
set -euo pipefail

################################################################################
# rotate-oci-key.sh
#
# Purpose:
#   Safe, scriptable skeleton to rotate an OCI user/service API key. This script is
#   intentionally descriptive and conservative — it is meant to be adapted to your
#   environment (Vault, CI, orchestration). It supports a preview (dry-run) mode
#   and requires explicit confirmation to perform destructive actions.
#
# Usage examples:
#   Dry-run (preview only):
#     ./scripts/rotate-oci-key.sh --user ocid1.user.oc1..AAAA --dry-run
#
#   Execute (perform rotation):
#     ./scripts/rotate-oci-key.sh --user ocid1.user.oc1..AAAA --confirm yes
#
# NOTES:
# - This script does NOT hard-delete keys until successful verification.
# - It intentionally contains placeholders for secret-store (Vault) operations
#   and consumer update steps. Replace those placeholders with your secure flow.
# - Required tools: `oci`, `openssl`. `jq` is recommended for JSON parsing.
################################################################################

print_usage() {
  cat <<EOF
Usage: $0 --user USER_OCID [--old-fingerprint OLD] [--vault-secret VAULT_NAME] [--dry-run] [--confirm yes]

Options:
  --user USER_OCID         (required) the OCI user OCID whose API key will be rotated
  --old-fingerprint OLD    (optional) the fingerprint of the old key to delete after verification
  --vault-secret NAME      (optional) logical name for storing the new private key (placeholder)
  --dry-run                show planned steps but do not change any state
  --confirm yes            actually perform the rotation (must be exactly "yes")
  -h, --help               show this help
EOF
}

if [ "$#" -eq 0 ]; then
  print_usage
  exit 2
fi

# Arg defaults
USER_OCID=""
OLD_FP=""
VAULT_SECRET=""
DRY_RUN=false
CONFIRM=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      USER_OCID="$2"; shift 2;;
    --old-fingerprint)
      OLD_FP="$2"; shift 2;;
    --vault-secret)
      VAULT_SECRET="$2"; shift 2;;
    --dry-run)
      DRY_RUN=true; shift;;
    --confirm)
      CONFIRM="$2"; shift 2;;
    -h|--help)
      print_usage; exit 0;;
    *)
      echo "Unknown arg: $1" >&2; print_usage; exit 2;;
  esac
done

if [ -z "$USER_OCID" ]; then
  echo "ERROR: --user USER_OCID is required" >&2
  exit 2
fi

# Check prerequisites
if ! command -v oci >/dev/null 2>&1; then
  echo "ERROR: 'oci' CLI not found on PATH. Install it first." >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  echo "ERROR: 'openssl' not found on PATH. Install it first." >&2
  exit 1
fi

JQ=0
if command -v jq >/dev/null 2>&1; then
  JQ=1
fi

PLAN_MSG=()
add_plan() { PLAN_MSG+=("$1"); }

add_plan "Will generate a new RSA keypair (2048-bit) in a temporary location."
add_plan "Will upload the public key to OCI for user: $USER_OCID and capture its fingerprint."
add_plan "Will store the new private key in secret store: ${VAULT_SECRET:-'<not-specified>'} (placeholder)."
add_plan "Will update consumer configuration / CI secrets (placeholder step)."
add_plan "Will run smoke tests to verify the new key works."
if [ -n "$OLD_FP" ]; then
  add_plan "On success, will delete old key fingerprint: $OLD_FP"
else
  add_plan "On success, will NOT delete any old keys (no --old-fingerprint provided)."
fi

echo "===== rotate-oci-key plan ====="
for p in "${PLAN_MSG[@]}"; do
  echo " - $p"
done
echo "================================"

if [ "$DRY_RUN" = true ]; then
  echo "Dry-run requested; no changes will be made."; exit 0
fi

if [ "$CONFIRM" != "yes" ]; then
  echo "To perform the rotation, re-run with: --confirm yes" >&2
  exit 2
fi

# Create safe temporary files
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
NEW_KEY="$TMP_DIR/new_api_key.pem"
NEW_PUB="$TMP_DIR/new_api_key.pub"

echo "Generating new RSA keypair..."
openssl genrsa -out "$NEW_KEY" 2048
chmod 600 "$NEW_KEY"
openssl rsa -pubout -in "$NEW_KEY" -out "$NEW_PUB"

echo "Uploading new public key to OCI..."
# The `oci` command outputs JSON. Use jq when available, otherwise basic parsing.
UPLOAD_OUT=$(oci iam user api-key upload --user-id "$USER_OCID" --key-file "$NEW_PUB" --raw-output 2>&1) || {
  echo "ERROR: failed to upload public key to OCI" >&2; echo "$UPLOAD_OUT" >&2; exit 1; }

if [ "$JQ" -eq 1 ]; then
  NEW_FP=$(echo "$UPLOAD_OUT" | jq -r '.data.fingerprint')
else
  # Fallback parse: look for fingerprint string in JSON
  NEW_FP=$(echo "$UPLOAD_OUT" | sed -n 's/.*"fingerprint"[[:space:]]*:[[:space:]]*"\([^"]\+\)".*/\1/p' | head -n1)
fi

if [ -z "$NEW_FP" ]; then
  echo "ERROR: could not determine new fingerprint from OCI response:" >&2
  echo "$UPLOAD_OUT" >&2
  exit 1
fi

echo "Uploaded new key; fingerprint: $NEW_FP"

# Store private key in secret store (placeholder). Replace with your Vault/API call.
if [ -n "$VAULT_SECRET" ]; then
  echo "[placeholder] Storing private key in secret store under name: $VAULT_SECRET"
  echo "  -> Implement this: upload $NEW_KEY securely to your Vault and set appropriate ACLs."
  # Example (pseudo):
  # oci vault secret create --vault-id $VAULT_OCID --compartment-id $COMP_OCID --secret-content file://<(base64 -w0 $NEW_KEY) --display-name "$VAULT_SECRET"
else
  echo "[warning] No --vault-secret provided; private key is left only in temporary file. Move it to secure storage now."
fi

echo "Updating consumers (placeholder)..."
echo "  -> Replace this block with steps to update CI secrets, configuration management, or pull-based secret rotation agents."
echo "  -> Example: update GitHub Actions secret, or write new key to /etc/oci/active_key.pem on target hosts via an orchestrator."

echo "Running smoke test(s) using the new key..."
# For smoke tests we rely on the environment being configured to use the new key if applicable.
# If you store the key in Vault and consumers pull on startup, ensure they have reloaded the new secret.

SMOKE_OK=true
if ! oci os ns get >/dev/null 2>&1; then
  echo "Smoke test failed: 'oci os ns get' did not succeed using the configured credentials." >&2
  SMOKE_OK=false
else
  echo "Smoke test passed: 'oci os ns get' succeeded." 
fi

if [ "$SMOKE_OK" != true ]; then
  echo "Verification FAILED; leaving old key active and not deleting anything. Perform investigation and rollback as needed." >&2
  exit 1
fi

echo "Verification succeeded. Proceeding to revoke old key (if provided)."
if [ -n "$OLD_FP" ]; then
  echo "Deleting old fingerprint: $OLD_FP"
  if oci iam user api-key delete --user-id "$USER_OCID" --fingerprint "$OLD_FP" --force >/dev/null 2>&1; then
    echo "Old key removed: $OLD_FP"
  else
    echo "WARNING: failed to delete old key fingerprint: $OLD_FP -- investigate manually." >&2
  fi
else
  echo "No old fingerprint provided; skipping deletion." 
fi

echo "Rotation complete. New fingerprint: $NEW_FP"
echo "Important: ensure the new private key has been moved from $NEW_KEY into your secure store and that only authorized principals can access it."

exit 0
