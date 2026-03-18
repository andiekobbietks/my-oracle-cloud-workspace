# Devcontainer — Quickstart & Notes

Purpose
-------
This devcontainer provides a reproducible development environment for this repository
— useful for VS Code, Codespaces, or local container-based development. It installs
the tools and runtime used by the relocate workflow and validator.

How to open
-----------
- In VS Code: `Remote-Containers: Open Folder in Container...` or open in Codespaces.

Quick setup
-----------
- Build and open container (VS Code): use the built-in command palette action.
- From inside container, install Python deps for local tools:

```bash
pip install -r /workspaces/my-oracle-cloud-workspace/requirements.txt
```

Environment / secrets
---------------------
- Do NOT store secrets in this file. Document required env vars here instead.
- Example vars the devcontainer expects (examples only):
	- `OCI_API_KEY_PATH` — path to local OCI API key (mounted or stored securely)
	- `GITHUB_TOKEN` — optional for automation that opens PRs (use Codespaces secrets)

Common developer commands
-------------------------
- `make install-deps` — install required Python packages from `requirements.txt`.
- `make validate` — run `tools/validate_skill.py` to validate SKILL docs.
- `make dry-run SOURCE=... DEST=...` — preview a relocation plan.
- `make backup-main` — create a `git bundle` backup of the repo before large ops.

Lifecycle hooks
---------------
- If the devcontainer runs any `postCreateCommand` or init scripts, list them here
	and explain how to re-run them (e.g., `./scripts/setup-devcontainer.sh`).

Troubleshooting
---------------
- If `pip` fails, check network/proxy and retry.
- If `git` operations fail inside the container, ensure your workspace has access
	to the local git config and credentials.

Pointers
--------
- Repo root: [README.md](../README.md)
- Docs: [docs/README.md](../docs/README.md)

