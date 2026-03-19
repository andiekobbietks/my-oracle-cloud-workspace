#!/usr/bin/env bash
set -euo pipefail

echo "OCI smoke test (non-destructive)"

if ! command -v oci >/dev/null 2>&1; then
  echo "SKIP: oci CLI not installed"
  exit 0
fi

echo "Checking OCI namespace (dry):"
if oci os ns get --query 'data' --raw-output >/dev/null 2>&1; then
  echo "OK: OCI CLI can query namespace (credentials likely present)"
else
  echo "WARN: OCI CLI failed to query namespace or no credentials available"
fi

echo "Done (non-destructive)."
