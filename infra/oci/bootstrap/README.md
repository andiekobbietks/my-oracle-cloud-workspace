OCI Bootstrap Terraform module (scaffold)
======================================

What this module provides
-------------------------
This directory contains a safe scaffold for Phase 2: Terraform-based provisioning
of minimal OCI resources. The initial goal is to create Network (VCN + subnet)
and a Vault (KMS) for storing sensitive outputs.

Design decisions
----------------
- State backend: use OCI Object Storage with locking or Terraform Cloud; this
  scaffold does not configure a backend automatically — the operator must
  configure the backend appropriate for their environment.
- Isolation: one workspace (or backend namespace) per client/tenant is
  recommended so state files are isolated.

How to use
----------
1. Configure provider credentials locally (see `.devcontainer/setup-oci.sh` for
   developer guidance) or configure CI to authenticate via OIDC/ORM.
2. Add a backend configuration suitable for your environment (Terraform Cloud
   workspace, or manual OCI Object Storage + locking). If you choose OCI Object
   Storage, create a bucket and use a supported mechanism to store the state.
3. Uncomment and adapt the example resource blocks in `main.tf` to your needs.
4. Run:

```bash
terraform init
terraform plan -var="compartment_id=ocid1.compartment.oc1..xxxxx"
```

Notes and safety
----------------
- This scaffold intentionally avoids creating resources automatically; it
  provides commented examples so reviewers can inspect planned resources before
  enabling them.  
- For production, prefer OCI Resource Manager (ORM) stacks or Terraform Cloud
  remote runs with OIDC to avoid storing long-lived API keys in repos.

Next steps (suggested)
----------------------
- Implement `oci_core_vcn` and `oci_core_subnet` resources and test in a
  sandbox compartment.  
- Add Terraform `backend.tf` with instructions to configure OCI Object Storage
  for remote state if you want to manage state there.  
- Wire Terraform runs into CI using ORM or GitHub Actions with OIDC (no long
  lived secrets).
