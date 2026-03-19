# OCI Bootstrap SOP (Terraform -> Resource Manager evolution)

This SOP outlines the recommended path from a CLI-based bootstrap to
Terraform + OCI Resource Manager + IAM federation.

1. Start with `scripts/oci-bootstrap.sh` for quick idempotent dry-run plans.
2. When stabilized, extract Terraform modules into `infra/oci/bootstrap/`.
3. Push Terraform source to a ZIP and create an OCI Resource Manager stack.
4. Migrate CI to use OIDC and ORM for runs (no long-lived API keys).
5. Replace developer API keys with federated IdP access and short-lived tokens.

See `docs/terraform-orm-sop.md` for Terraform examples and step-by-step commands.
