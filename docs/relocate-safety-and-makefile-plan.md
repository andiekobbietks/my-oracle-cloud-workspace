# Relocate: Safety, Risks, Mitigations, and Makefile Plan

Summary
-------
This document captures the operational risks and mitigations for the `relocate-file` workflow, and a concise Makefile plan to run safe, repeatable dry-run/apply/verify flows.

Risks
-----
- Validator coverage: `tools/validate_skill.py` is helpful but not exhaustive.
- CI / cloud quotas: long jobs or large pushes may hit GitHub/Oracle limits.
- Large files or binary blobs: `git mv` and pushes can fail or be slow.
- Permissions / RBAC: scripts that modify the repo require proper credentials and review.
- Symlink portability: symlink behavior differs across OSes and containers.
- Human error: accidental `apply` or merge conflicts can cause loss without backups.

Mitigations (what we have / recommended)
--------------------------------------
- Keep `dry_run` as the default; never `apply` automatically.
- Run the validator locally and in CI (`.pre-commit-config.yaml`, `.github/workflows/validate-skills.yml`).
- Create repo backups before large operations: `git bundle` and mailbox patches.
- Add smoke-tests to CI to verify basic repo integrity after changes.
- Enforce PR review or limited ACLs for `apply` targets.
- Add size/time guards to Make/CI targets to avoid quota overruns.

Recommended Makefile targets
----------------------------
- `install-deps`: install tool dependencies (e.g., `pip install -r requirements.txt`).
- `validate`: run `tools/validate_skill.py` across SKILLs and docs.
- `validate-skill FILE=...`: validate a single SKILL file.
- `dry-run SOURCE=... DEST=...`: run the relocator in preview mode.
- `apply SOURCE=... DEST=... CONFIRM=yes`: perform the actual relocation (requires explicit `CONFIRM=yes`).
- `backup-main`: create a bundle backup: `git bundle create /tmp/main-backup.bundle --all`.
- `smoke-test`: quick checks after apply (files exist, no obvious broken links).

Example usage
-------------
Run a preview:

```bash
make dry-run SOURCE=.devcontainer/README.md DEST=./
```

Apply with explicit confirmation:

```bash
make backup-main
make apply SOURCE=.devcontainer/README.md DEST=./ CONFIRM=yes
make smoke-test
```

Skill behaviour guidance (for `run-relocate` Skill)
-------------------------------------------------
- Default `dry_run=true`.
- Require an explicit `apply` flag and a `CONFIRM` token or human approval step to run destructive actions.
- If many files match a glob, always require manual confirmation.

Next steps (I can implement these on confirmation)
------------------------------------------------
- Add `Makefile` with the targets above and safe guards.
- Scaffold `/.github/skills/run-relocate/SKILL.md` that maps user inputs to `make` targets and enforces `dry_run` by default.
- Add a CI job to run `smoke-test` after merges where `apply` ran.

Location
--------
This document: [docs/relocate-safety-and-makefile-plan.md](docs/relocate-safety-and-makefile-plan.md)
