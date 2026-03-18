# Docs (Doc-as-Code)

This `docs/` folder holds repository documentation as code. Keep docs small, reviewable, and versioned alongside source.

Guidelines
- Write plain Markdown files.
- Keep a single-sentence summary at the top.
- Open a PR for larger edits; small fixes may be committed directly if team policy allows.
- Link docs from the repository root README when appropriate.

Files
- `symbolic-links.md` — reference about symbolic links and usage in this repo.

- `dry-run.md` — how to preview relocation plans before making changes.
- `smoke-test.md` — quick verification steps to validate relocations.
- `mcp-lint.md` — linting and secret-detection guidance for MCPs and relocated content.
 - `owasp-mapping.md` — mapping of repo artifacts to OWASP Top 10, ASVS, and Proactive Controls.
 - `security-origins.md` — provenance, background, and first-instance history for this security work.

How to edit
1. Create or update a file under `docs/`.
2. Commit with a short message describing the doc change.
3. Optionally open a PR for review.
