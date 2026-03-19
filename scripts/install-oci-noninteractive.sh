#!/usr/bin/env bash
set -euo pipefail

OCI_DIR="$HOME/.oci"
INSTALL_DIR="${INSTALL_DIR:-$HOME/oci-toolkit}"

mkdir -p "$OCI_DIR"
chmod 700 "$OCI_DIR"

# Write config from env or stdin
if [ -n "${OCI_CONFIG_CONTENT:-}" ]; then
  printf "%s\n" "$OCI_CONFIG_CONTENT" > "$OCI_DIR/config"
else
  if [ -t 0 ]; then
    echo "No OCI_CONFIG_CONTENT set. To run non-interactively, set OCI_CONFIG_CONTENT environment variable." >&2
  else
    cat > "$OCI_DIR/config"
  fi
fi
chmod 600 "$OCI_DIR/config" || true

# Write private key from env or stdin
if [ -n "${OCI_PRIVATE_KEY:-}" ]; then
  printf "%s\n" "$OCI_PRIVATE_KEY" > "$OCI_DIR/oci_api_key.pem"
else
  if [ -t 0 ]; then
    echo "No OCI_PRIVATE_KEY set. To run non-interactively, set OCI_PRIVATE_KEY environment variable." >&2
  else
    cat > "$OCI_DIR/oci_api_key.pem"
  fi
fi
chmod 600 "$OCI_DIR/oci_api_key.pem" || true

# Download and run the official installer non-interactively
TMP_INSTALL="/tmp/oci-install.sh"
curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh -o "$TMP_INSTALL"
bash "$TMP_INSTALL" --accept-all-defaults --install-dir "$INSTALL_DIR"

echo
echo "OCI CLI installed to: $INSTALL_DIR"
echo "Add to PATH for current session:"
echo "  export PATH=\"$INSTALL_DIR/bin:\$PATH\""
echo "Add the export to your shell profile to persist it."

echo "Verifying installation..."
export PATH="$INSTALL_DIR/bin:$PATH"
oci --version || true

echo "If you see 'config file is invalid', ensure ~/.oci/config contains user, tenancy, fingerprint, key_file, and region, and that the key file exists and has permissions 600."
