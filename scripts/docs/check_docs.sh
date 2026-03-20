#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
DOCS_DIR="$ROOT_DIR/docs"
echo "Running docs audit against $DOCS_DIR"

missing=0

echo "Checking referenced files inside markdown for existence..."
# Find local file references in docs (patterns like docs/... or scripts/... or .github/...) and verify they exist
grep -R --line-number -E "\b(docs|scripts|\.github|examples|.devcontainer|.github|infra|terraform)/[A-Za-z0-9_./-]+" "$DOCS_DIR" || true

while IFS= read -r line; do
  # extract path-like tokens
  for token in $(echo "$line" | grep -oE "\b(docs|scripts|\.github|examples|.devcontainer|infra|terraform)/[A-Za-z0-9_./-]+" || true); do
    # normalize
    path="$ROOT_DIR/$token"
    if [ ! -e "$path" ]; then
      echo "MISSING: $token referenced in docs but not found at $path"
      missing=$((missing+1))
    fi
  done
done < <(grep -R --line-number -E "\b(docs|scripts|\.github|examples|.devcontainer|.github|infra|terraform)/[A-Za-z0-9_./-]+" "$DOCS_DIR" || true)

echo
if command -v markdownlint >/dev/null 2>&1; then
  echo "Running markdownlint..."
  markdownlint "$DOCS_DIR" || true
else
  echo "markdownlint not installed; skipping lint step"
fi

if [ $missing -ne 0 ]; then
  echo "Docs audit found $missing missing references"
  exit 2
fi

echo "Docs audit passed — no missing file references found."
exit 0
