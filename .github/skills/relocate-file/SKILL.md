---
name: relocate-file
description: |
  Skill to relocate one or more files (docs, README, CONTRIBUTING, etc.) within a repository.
  Supports dry-run, globs, `git mv` for history preservation, optional symlink/redirect creation,
  and automated commit/PR creation when requested.
---

# Relocate File(s)

## Purpose

Provide a reusable, safe workflow to move or copy files (single or multiple via patterns) within
the repository while offering options for history preservation, backups, dry-runs, and link updates.

## When to use

- Moving documentation or other repository files to a new location (e.g., promote `.docs/CONTRIBUTING.md` to the repo root).
- Preserving compatibility by leaving a symlink or redirect at the old path.
- Performing bulk relocations using glob patterns with a preview step.

## Inputs

- `source` (required) — a path or glob pattern (e.g., `.devcontainer/README.md` or `docs/*.md`).
- `dest` (optional) — destination directory or explicit file path; default: repo root with original basename.
- `preserve_history` (bool, optional) — when true prefer `git mv` to preserve git history.
- `keep_copy` (bool, optional) — if true, leave the original file intact (creates copy).
- `create_symlink` (bool, optional) — if true, create a symlink at the original path pointing to the new path when supported.
- `create_redirect_file` (bool, optional) — fallback to a small Markdown redirect if symlinks are unsupported.
- `dry_run` (bool, optional) — list planned actions without making changes.
- `overwrite` (bool, optional) — allow overwriting existing destination files.
- `backup` (bool, optional) — if overwriting, keep a timestamped backup of the existing dest.
- `update_links` (bool, optional) — search and optionally update repo references to the old path(s).
- `commit_and_pr` (bool, optional) — when true, create a commit and open a PR with the changes.

## Steps

1. Resolve `source` (expand globs) and confirm matched files; abort if none match.
2. For each file: compute `dest` (preserve basename when `dest` is a directory).
3. Show a plan (dry-run). If `dry_run` is true: stop after presenting the plan.
4. If `preserve_history` and repo is git: use `git mv` where possible; otherwise copy then remove original.
5. If `keep_copy` is true: copy instead of moving.
6. If destination exists and `overwrite` is false: prompt for action (skip/overwrite/rename).
7. If `create_symlink` requested: create a symlink at the original path pointing to new location (if supported).
8. If `create_redirect_file` requested and symlink unsupported: write a small Markdown redirect at the old path.
9. If `update_links` requested: search repository for references to the old path and offer edits or staged changes.
10. If `commit_and_pr` requested: commit the changes and open a PR (if remote access/credentials available).
11. Run verification checklist.

## Decision points

- If many files match a glob, recommend running with `dry_run` first.
- If `preserve_history` is requested but the repo is not a git repository or user lacks git credentials, fall back to copy.
- If symlink creation fails due to permissions, offer `create_redirect_file` instead.

## Verification checklist

- All `dest` files exist and contents match originals (when moved or copied).
- If `keep_copy` was false, originals were removed or replaced by symlinks/redirects as requested.
- If `update_links` was used, a quick grep shows no remaining obvious references to old paths (or changes proposed in PR).

## Examples

- Move a single README to the repo root (preserve history):

  `source: .devcontainer/README.md`, `preserve_history: true`

- Copy all docs to `docs/archive/` with dry-run:

  `source: docs/*.md`, `dest: docs/archive/`, `dry_run: true`, `keep_copy: true`

- Move and leave symlink for compatibility:

  `source: docs/guide.md`, `dest: README.md`, `create_symlink: true`, `commit_and_pr: true`

## Implementation notes for agents

- Always present a dry-run plan when globs are used or multiple files match.
- Prefer `git mv` to keep history; if `git mv` is used, commit message should explain the relocation.
- Keep changes minimal; large-scale link updates should be proposed in a separate PR for review.

## Completion criteria

- All requested files are at `dest` and the user confirms the result or merges the PR created.