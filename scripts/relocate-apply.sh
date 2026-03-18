#!/usr/bin/env bash
set -euo pipefail
if [ "${1-}" = "" ] || [ "${2-}" = "" ]; then
  echo "Usage: $0 <source> <dest>" >&2
  exit 2
fi
src="$1"
dest="$2"

if [ "${CONFIRM-}" != "yes" ]; then
  echo "CONFIRM not set to 'yes'. To apply, set CONFIRM=yes in environment or use the Makefile (CONFIRM=yes)." >&2
  exit 2
fi

# If source is a glob, expand it
shopt -s nullglob
matches=( $src )
if [ ${#matches[@]} -eq 0 ]; then
  echo "No files match source pattern: $src" >&2
  exit 2
fi

for f in "${matches[@]}"; do
  if [ -d "$dest" ]; then
    target="$dest/$(basename "$f")"
  else
    target="$dest"
  fi

  echo "Applying: git mv '$f' -> '$target'"
  git mv -- "$f" "$target"
done

echo "Staged moves. Commit with: git commit -m 'Relocate files via scripts/relocate-apply.sh'" 
