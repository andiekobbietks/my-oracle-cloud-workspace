# Terraform + OCI Resource Manager SOP

Reference example files and a high-level SOP for migrating to Terraform Cloud /
OCI Resource Manager with IAM federation (no long-lived API keys in repos).

Key steps
---------
1. Write Terraform modules in `infra/oci/bootstrap/` and parameterize everything.
2. Create an OCI Resource Manager Stack pointing to a zip of the Terraform code.
3. Use GitHub Actions with OIDC to trigger ORM jobs (no secrets required).
4. Map IdP groups to OCI policies for least-privilege access.

This document is a pointer; implementation files are in `terraform/` when ready.
