## Engineering Journey & Problem Solving
This project evolved from a simple management shell into a **Repeatable Infrastructure Framework**. Key challenges overcome:

- **Resource Constraints:** Bypassed OCI Cloud Shell's 160-hour monthly cap by migrating to a containerized GitHub Codespaces environment.
- **Dependency Conflicts:** Diagnosed and resolved build failures caused by the Debian 'Trixie' release (upstream conflict with Docker-in-Docker features).
- **Scalability:** Refactored the bootstrap process to support **Multi-Tenancy**. This repo now functions as a **Template**, allowing 5-minute deployment for new clients by injecting fresh API secrets.


## Documentation

- See [docs/README.md](docs/README.md) for doc-as-code guidelines.
- See [docs/symbolic-links.md](docs/symbolic-links.md) for how and why symbolic links are used in this repo, especially for safe file relocation and compatibility.
 - Agents practice guide: [docs/agents-practice.md](docs/agents-practice.md)

## How it Works
1. **GitHub Secrets** act as the "Vault" for OCI API keys.
2. **DevContainer Lifecycle Hooks** run `setup-oci.sh` on every boot.

## Repeatable Infrastructure Framework — what it means

"Repeatable Infrastructure Framework" describes a set of practices, templates, and automation that let teams recreate a known-good cloud environment reliably, consistently, and with minimal manual steps. In this repository the framework is embodied by:

- Idempotent bootstrap scripts and plan-first workflows (`scripts/oci-bootstrap.sh`) that support `--dry-run` and produce machine-readable plans in `outputs/oci-bootstrap/`.
- Policy and safety controls: `do_not_edit_paths` in SKILL.md files, CI checks to block non-allowed compute shapes, and workflows that gate changes to sensitive paths.
- Developer onboarding automation: a `devcontainer.json` with `postCreateCommand` to provision CLI credentials automatically for Codespaces and a cleanup hook to remove keys on stop.
- Secret handling and migration patterns: guidance and automation to move from long-lived PEMs to Vault-backed secrets or OIDC-issued short-lived credentials (`docs/oidc-and-vault.md`, `docs/oidc-vault-setup.md`, `.github/workflows/oidc-vault.yml`).
- Operational tooling: helper scripts to provision Vault roles and to store/retrieve secrets (`scripts/vault/*`), plus a shape-whitelist checker and Makefile targets for CI integration.
- Documentation and auditability: detailed docs, runbooks, and `SKILL.md` metadata that require explicit confirmation and audits for destructive actions.

Together these elements make infrastructure provisioning repeatable (same inputs produce same plans), reviewable (plans and CI checks), and safer (secrets managed centrally and least-privilege enforced).

## Historical background — how this repo became a Repeatable Infrastructure Framework

This repository evolved through iterative changes to solve specific problems and harden the developer and CI experience:

1. Started as a simple bootstrap and example repo for OCI automation and developer onboarding.
2. Introduced idempotent `scripts/oci-bootstrap.sh` with `--dry-run` to produce JSON plan files so changes can be reviewed before apply.
3. Added `SKILL.md` metadata and a canonical `do_not_edit_paths` list to prevent automated agents from editing sensitive resources; created a propagate script and sanitized YAML frontmatter for consistent enforcement.
4. Built CI safety: a shape-whitelist checker (`tools/check_shapes_pr.py`) and GitHub Actions workflow to reject non-Always-Free shapes and unsafe changes.
5. Hardened secrets handling: removed accidentally committed PEMs, added `.gitignore`, and stored the Codespace private key in a repository secret for controlled usage.
6. Added a `devcontainer.json` `postCreateCommand` and cleanup script so new Codespaces are immediately usable and keys are cleaned up on teardown.
7. Designed and documented a migration to short-lived credentials: wrote `docs/oidc-and-vault.md` and `docs/oidc-vault-setup.md`, scaffolded `.github/workflows/oidc-vault.yml`, and added Vault helper scripts so Actions can request secrets via OIDC and fetch keys with Vault policies.
8. Implemented docs, runbooks, and admin scripts so operators can provision Vault roles and policies, store keys, and run canary tests and smoke-tests before revoking old keys.

These steps produced a codebase where infrastructure provisioning is repeatable (templated and idempotent), reviewable (plans + CI), and auditable (Vault + docs + cleanup). Treat this repository as a reference implementation and operational template for small-to-medium OCI deployments.

