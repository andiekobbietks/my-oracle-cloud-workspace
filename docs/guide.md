# Relocate Guide — step-by-step

Overview
--------
This guide explains the safe relocate workflow used by the `relocate-file` Skill and the
`run-relocate` Skill wrapper. It converts the SKILL steps into concrete commands and
checks you can run locally or via CI.

Pre-flight checklist
--------------------
- Ensure your working tree is clean: `git status --porcelain` should be empty.
- Run `make validate` to check SKILL docs and references.
- Run `make backup-main` to produce a `git bundle` backup before large moves.

Dry-run (preview)
------------------
1. Preview a single file move:

```bash
make dry-run SOURCE=.devcontainer/README.md DEST=./
```

2. For glob patterns, always review the list of matched files first:

```bash
bash scripts/relocate-dryrun.sh "docs/*.md" docs/archive/
```

Apply (perform the move)
------------------------
1. Create a repo backup:

```bash
make backup-main
```

2. Run the apply step (explicit confirmation required):

```bash
make apply SOURCE=.devcontainer/README.md DEST=./ CONFIRM=yes
```

3. Commit the staged moves with an explanatory message:

```bash
git commit -m "Relocate: move .devcontainer/README.md to repo root (preserve history)"
```

Smoke-test (quick verification)
-------------------------------
- Run the simple smoke-test target to ensure destination files exist:

```bash
make smoke-test SOURCE=.devcontainer/README.md DEST=./
```

Link updates and larger refactors
--------------------------------
- If you requested `update_links`, make link edits in a separate PR so reviewers can
	review the diff for unintended breaks.

Revert & Recovery
-----------------
- If something goes wrong, you can revert the relocation commit via `git revert`.
- If you created a `git bundle` backup, restore it by cloning from the bundle or
	inspecting its contents: `git clone /tmp/main-backup.bundle repo-from-bundle`.

Permissions & Review
--------------------
- Require an explicit human review for `apply` operations on multi-file globs.
- Consider restricting who can run the apply target via repository policy.

References
----------
- Skill: [/.github/skills/relocate-file/SKILL.md](.github/skills/relocate-file/SKILL.md)
- Wrapper Skill: [/.github/skills/run-relocate/SKILL.md](.github/skills/run-relocate/SKILL.md)
- Makefile: [Makefile](../Makefile)
- Validator: [tools/validate_skill.py](../tools/validate_skill.py)

- Institutional agents doc: [docs/agents-institutional-knowledge.md](docs/agents-institutional-knowledge.md)

Workflow diagram
----------------
```mermaid
flowchart LR
	A[Start: Relocate request] --> B[Dry-run (make dry-run)]
	B --> C{Matches found?}
	C -- No --> D[Abort — adjust pattern]
	C -- Yes --> E[Backup (make backup-main)]
	E --> F{Apply now?}
	F -- No --> G[Open PR for review]
	F -- Yes --> H[Apply (make apply CONFIRM=yes)]
	H --> I[Smoke-test (make smoke-test)]
	I --> J[Done]
```

