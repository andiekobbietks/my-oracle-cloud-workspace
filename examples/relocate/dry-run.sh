#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <source> <dest>"
  exit 2
fi
src="$1"
dest="$2"

echo "Relocate dry-run: $src -> $dest"
bash scripts/relocate-dryrun.sh "$src" "$dest"
