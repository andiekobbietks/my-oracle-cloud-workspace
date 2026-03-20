#!/usr/bin/env bash
set -euo pipefail
KEYFILE=/home/vscode/.oci/oci_api_key.pem
if [ -f "$KEYFILE" ]; then
  if command -v shred >/dev/null 2>&1; then
    shred -u "$KEYFILE" || rm -f "$KEYFILE"
  else
    dd if=/dev/urandom of="$KEYFILE" bs=4096 count=1 conv=notrunc 2>/dev/null || true
    rm -f "$KEYFILE"
  fi
  echo "Removed $KEYFILE"
else
  echo "No OCI key to remove at $KEYFILE"
fi
