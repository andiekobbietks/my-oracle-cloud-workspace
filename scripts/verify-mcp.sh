#!/usr/bin/env bash
set -euo pipefail
PORT=${1:-9222}
URL="http://127.0.0.1:$PORT/json"
echo "Checking MCP debug endpoint at $URL"
if curl -sS "$URL" | jq . >/dev/null 2>&1; then
  echo "OK: MCP debug endpoint returned JSON."
  curl -sS "$URL" | jq .
else
  echo "ERROR: Could not fetch JSON from $URL" >&2
  curl -sS "$URL" || true
  exit 2
fi
