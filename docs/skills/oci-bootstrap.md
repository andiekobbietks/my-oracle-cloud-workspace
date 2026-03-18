# OCI Bootstrap — deep doc

Details and implementation notes for the `oci-bootstrap` Skill, focused on Always Free-aware, idempotent provisioning.

Design goals
------------
- Idempotent: re-running produces no additional resources when not needed.
- Safe defaults: minimal open networking, explicit tags, and audit logging.
- Cost-aware: use Always Free resource types where practical for demos and tests.

Always Free considerations
-------------------------
- Prefer small VM shapes, block storage, and the OCI Always Free object storage in examples.
- Warn when requested resources are not Always Free in the target region.

Terraform vs CLI
-----------------
- Use Terraform for long-lived infra; use CLI for quick bootstraps in ephemeral dev environments.

CI usage
--------
- Use service principals or automation users with least privilege to run bootstrap in CI.
- Store any generated credentials in `vault-integration` managed secrets.
