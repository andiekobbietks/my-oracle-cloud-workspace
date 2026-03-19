#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <user-ocid>"
  exit 2
fi
user_ocid="$1"

echo "Key-rotation dry-run for $user_ocid"
echo "This script will only list current API keys and print a recommended plan."

if ! command -v oci >/dev/null 2>&1; then
  echo "SKIP: oci CLI not installed"
  exit 0
fi

echo "Listing API keys for user (dry):"
oci iam user list-api-keys --user-id "$user_ocid" --query 'data' --raw-output || echo "(listing failed)"

echo "Plan: create replacement key, stage in vault, verify with canary consumer, rotate consumers, revoke old key after verification."
