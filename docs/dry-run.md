 # Dry-run

 Purpose: Preview the exact, per-file plan for a relocation without changing the working tree.

 How it works (steps):
 1. Expand globs and compute candidate source files.
 2. Compute destination paths for each candidate (preserve basename unless explicit dest provided).
 3. Detect conflicts (dest exists, name collisions, permissions).
 4. Produce a machine- and human-readable plan listing per-file actions (move/copy/symlink/redirect/skip), source, computed dest, and notes.
 5. Exit non-zero on critical errors; otherwise exit zero after printing plan.

 Assumptions:
 - Repo is readable and globs resolve relative to repo root.
 - `git` metadata is available for `preserve_history` requests.
 - Symlink behavior depends on host OS and git client.

 Example (script): `bash scripts/relocate-dryrun.sh docs/README.md docs/archive/README.md`

 Verification checklist:
 - Plan lists all matched sources.
 - No unexpected collisions unless `overwrite` is set.
 - For each action: source path, dest path, action type, notes.
 - Include the plan in PR description or as an artifact.

 Notes:
 - Dry-runs are intended to be machine- and human-reviewable artifacts.
 - Attach the plan to PRs or CI artifacts for reviewer verification.
