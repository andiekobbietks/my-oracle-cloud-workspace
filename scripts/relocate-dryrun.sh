#!/bin/bash
set -euo pipefail
# relocate-dryrun.sh — simple, non-destructive preview of a planned relocation
# Usage: ./scripts/relocate-dryrun.sh <source> <dest>
# - `source` may be a single path or a shell glob (quoted when needed).
# - `dest` is the destination path or directory.

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <source> <dest>"
  exit 2
fi
src="$1"
dest="$2"

echo "DRY-RUN: plan to move '$src' -> '$dest'"

# If the source is a glob, show the expanded list so users can verify matches.
shopt -s nullglob
matches=( $src )
if [ ${#matches[@]} -gt 1 ]; then
  echo "Matches (${#matches[@]}):"
  for m in "${matches[@]}"; do
    echo " - $m"
  done
elif [ ${#matches[@]} -eq 1 ]; then
  echo " - source exists: ${matches[0]}"
else
  # Not a glob or no matches — fall back to literal check
  if [ -e "$src" ]; then
    echo " - source exists: $src"
  else
    echo " - source MISSING: $src"
  fi
fi

if [ -e "$dest" ]; then
  echo " - destination exists: $dest"
else
  echo " - destination would be created: $dest"
fi

echo "No changes made (dry-run)."
