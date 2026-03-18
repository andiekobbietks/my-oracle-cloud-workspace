 # Smoke Test

 Purpose: Fast, lightweight checks that verify relocated files are present and the repo is healthy after applying changes.

 Checks:
 - Dest files exist and are readable.
 - When `keep_copy` is false, originals are removed or replaced by symlinks/redirects as expected.
 - If `create_symlink` used: symlink targets resolve to dest.
 - Basic content sanity (non-empty, expected frontmatter).
 - `git status --porcelain` is clean after committing (or branch contains intended changes).

 Local example commands:
 - `bash scripts/relocate-dryrun.sh docs/README.md docs/archive/README.md` (verify plan)
 - After applying changes: `test -f docs/archive/README.md && echo OK`
 - `git status --porcelain`

 When to run:
 - Run in CI after the relocate step; run locally when verifying manual moves.
