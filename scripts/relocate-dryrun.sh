#!/bin/bash
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <source> <dest>"
  exit 2
fi
src="$1"
dest="$2"

echo "DRY-RUN: would move '$src' -> '$dest'"
if [ -e "$src" ]; then
  echo " - source exists: $src"
else
  echo " - source MISSING: $src"
fi
if [ -e "$dest" ]; then
  echo " - destination exists: $dest"
else
  echo " - destination would be created: $dest"
fi

echo "No changes made (dry-run)."
