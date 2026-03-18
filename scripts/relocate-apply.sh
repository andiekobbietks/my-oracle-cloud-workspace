#!/usr/bin/env bash
set -euo pipefail

# relocate-apply.sh — performs git moves for matched source files.
# Safety notes:
# - This script requires CONFIRM=yes set in the environment (or via Makefile).
# - It uses `git mv` to preserve history when possible and stages the changes
#   but does not create the commit automatically. This gives the user a chance
#   to review the staged changes before committing.
#
# Usage (recommended via Makefile):
#   make backup-main
#   make apply SOURCE="docs/*.md" DEST=docs/archive/ CONFIRM=yes

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

# Expand globs safely and show counts for clarity
shopt -s nullglob
matches=( $src )
if [ ${#matches[@]} -eq 0 ]; then
  echo "No files match source pattern: $src" >&2
  exit 2
fi

echo "Applying relocation for ${#matches[@]} file(s)..."
for f in "${matches[@]}"; do
  if [ -d "$dest" ]; then
    target="$dest/$(basename "$f")"
  else
    target="$dest"
  fi

  echo " - git mv: '$f' -> '$target'"
  git mv -- "$f" "$target"
done

echo "Staged moves. Review the staged changes and then commit, for example:"
echo "  git commit -m 'Relocate files via scripts/relocate-apply.sh'"
