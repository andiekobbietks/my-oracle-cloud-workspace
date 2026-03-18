 # MCP Lint

 Purpose: Lint and validate MCP-related files and relocated content to ensure policy compliance and prevent accidental secrets/format regressions.

 Responsibilities:
 - Validate MCP files conform to expected schema (fields like `name`, `deny`, `allow`, `metadata`).
 - Detect likely secrets in changed files (heuristics: `AKIA...`, `BEGIN .*PRIVATE KEY`, `password=`, `token=`, `secret` near `:`/=`). 
 - Validate required frontmatter when policies require it.
 - Run markdown/link linters on relocated docs.

 Example checks:
 - Secret grep:
   grep -RIn --exclude-dir=.git -E "AKIA[0-9A-Z]{16}|BEGIN .*PRIVATE KEY|password\s*=|token\s*=|\bsecret\b" || true
 - Markdown lint:
   npx markdownlint-cli '**/*.md' || true

 Action on failure:
 - Fail CI, surface failing lines in the PR, require fixes before merge.

 Guidance:
 - Keep the lint fast and focused; escalate to manual review when high-confidence secrets are detected.
