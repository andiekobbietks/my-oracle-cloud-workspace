#!/usr/bin/env bash
set -euo pipefail

echo "Bootstrap example: requires 'oci' on PATH and that ~/.oci/config exists"

if ! command -v oci >/dev/null 2>&1; then
  echo "ERROR: 'oci' CLI not found on PATH. Install it or run scripts/install-oci-noninteractive.sh" >&2
  exit 1
fi

if [ -z "${TENANCY_OCID:-}" ]; then
  echo "Please set TENANCY_OCID environment variable (your tenancy OCID)." >&2
  exit 1
fi

echo "Creating compartment 'dev-bootstrap' (this is idempotent if re-run carefully)..."
compartment_id=$(oci iam compartment create \
  --name dev-bootstrap \
  --compartment-id "$TENANCY_OCID" \
  --description "Bootstrap compartment for demos" \
  --query 'data.id' --raw-output)

echo "Compartment created: $compartment_id"

echo "Creating object storage bucket 'bootstrap-bucket'..."
oci os bucket create --name bootstrap-bucket --compartment-id "$compartment_id" --public-access-type NoPublicAccess >/dev/null
echo "Bucket created (verify with: oci os bucket get --bucket-name bootstrap-bucket --namespace \\$(oci os ns get --query 'data' --raw-output) --compartment-id $compartment_id)"

cat <<'EOF'

--- Terraform snippet (example) ---
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

resource "oci_identity_compartment" "dev" {
  name           = "dev-bootstrap"
  compartment_id = var.tenancy_ocid
}

--- end snippet ---

Notes:
- The CLI approach above is imperative: it performs actions immediately.
- Prefer Terraform for long-lived infra; use the CLI for quick bootstraps.

EOF

echo "Done. Review resources in the Console or with additional 'oci' list/get commands."
