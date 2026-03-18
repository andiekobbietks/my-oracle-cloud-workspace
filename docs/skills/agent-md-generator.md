# Agent MD Generator

This document explains the `agent-md-generator` SKILL which scaffolds
`.agent.md` files from a small interactive flow or from CLI-provided inputs.

When to use
- Creating a new agent metadata file with consistent fields and verification
  guidance.
- Onboarding new agents where maintainers prefer templated metadata.

Usage
- Interactive: run without `--apply` to preview the generated file (dry-run).
- Automated: provide `--agent-name` and `--description` to run non-interactively.

Template fields
- `name`: short identifier
- `description`: one-line summary
- `maintainer`: contact
- `triggers`: example invocation phrases

Safety
- Do not include credentials in generated files. Reference vault paths when
  runtime credentials are required.

Integration notes
- Provide a thin CLI wrapper for CI usage. Support `--apply` to write files
  and return the file path on success.

Example CLI
```
agent-md-gen --agent-name infra-deployer --description "Deploy infra stacks" --apply
```
