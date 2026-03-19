**Always Free Maximization Guide**

Purpose: This guide helps you use Oracle Cloud Infrastructure (OCI) Always Free resources effectively for development, demos, and long-term experiments while avoiding accidental paid usage. It assumes you already have access to a tenancy and the OCI CLI configured (we validated a working `~/.oci/config` earlier).

Table of contents
- Why focus on Always Free
- Core Always Free strategy
- Resource hygiene and organization
- Network and VCN patterns for Always Free
- Compute choices: capacity, shapes and cost control
- Storage and databases: Always Free-friendly options
- Secrets, keys, and vaults
- Automation: IaC, CI, dry-runs and resource lifecycle
- Monitoring, budgets and alerts
- Backup, snapshot and restore patterns
- Security posture and least privilege
- Practical examples and scripts
- Runbook: start / stop / destroy safely
- Appendix: troubleshooting and next steps

Why focus on Always Free
------------------------
- Cost certainty: Always Free gives predictable free capacity you can run long-term without billing surprises.
- Rapid iteration: keep sandbox environments available 24/7 for demos, PoCs and CI smoke-tests.
- Learning & reproducibility: Always Free encourages building automatable, repeatable infra that can be recreated quickly.

Core Always Free strategy (high level)
--------------------------------------
1. Define a single dedicated compartment for Always Free resources. Treat it as a sandbox with constrained IAM policies.
2. Use minimal, Always Free-compatible shapes and services only. Where a paid resource is required, isolate it and use short-lived workflows.
3. Automate creation and destruction via idempotent IaC with dry-run first. Never create long-lived ad-hoc resources manually.
4. Enforce tagging, budgets, and alerts to detect drift from Always Free usage.

Resource hygiene and organization
--------------------------------
- Compartment structure: create `compartment/always-free` and restrict who can create resources there.
- Tags: require tags for `owner`, `purpose`, `lifecycle` (`ephemeral`/`persistent`), and `cost-center`. Example tag namespace `team:andiekobbi` with keys `owner,purpose,lifecycle`.
- Naming: adopt a concise naming convention: `af-<service>-<purpose>-<short-id>` (e.g., `af-vm-smoke-01`).
- Quota policing: keep a small, documented number of resources per service (e.g., 2 VMs, 2 DB instances) and enforce via a repo-level check or manual policy/CI check.

Network and VCN patterns for Always Free
---------------------------------------
- Single small VCN per compartment is typically adequate. Create minimal subnets and keep security lists locked down.
- Use private subnets where possible; avoid public IPs unless required for demos. If you need public access, use a NAT gateway or ephemeral bastion.
- Keep route tables minimal and avoid complex gateway chains.

Compute choices: capacity, shapes and cost control
-------------------------------------------------
- Prefer Always Free-eligible shapes. If unsure which shapes are Always Free in your region, query OCI console docs or run a shapes/availability check via CLI.
- For workloads: use the smallest shapes that satisfy the workload, prefer burstable or micro shapes for low-cost continuous workloads.
- Stop rather than terminate: When pausing work, stop VMs (not destroy) to preserve configuration but reduce runtime charges (note: some resources still incur storage costs).

Storage and databases: Always Free-friendly options
-------------------------------------------------
- Object Storage: Always Free tiers usually include a free object-storage allowance suitable for logs, artifacts and small datasets.
- Databases: Use Always Free Autonomous Databases or Free-tier DB instances. Keep automated backups but prune old snapshots to avoid paid storage.
- Block volumes: Use small volumes for Always Free VMs. Snapshots can incur storage costs; delete or copy snapshots to a compact store as needed.

Secrets, keys, and vaults
------------------------
- Always keep API keys, PEMs and secrets out of the repo. Use Vault or the OCI Secrets service to store keys, and `do_not_edit_paths` to protect PEM files.
- Rotate keys regularly and store fingerprints in `~/.oci/config` as we did. Never commit private key files.

Automation: IaC, CI, dry-runs and resource lifecycle
--------------------------------------------------
- Idempotent IaC: Use Terraform/Resource Manager or scripted OCI CLI steps that are idempotent and support `--dry-run` or `plan` outputs.
- Always run dry-run first: our repo script `scripts/oci-bootstrap.sh` produces JSON plans. Treat plans as reviewable artifacts and include them in PRs.
- CI smoke-tests: add a `smoke-test` skill that validates resource reachability and uses ephemeral credentials. Run smoke-tests in PRs but gate actions that create resources behind maintainers.
- Destroy automation: create `make destroy` or `terraform destroy` targets and protect execution behind approvals to avoid accidental deletes.

Monitoring, budgets and alerts
----------------------------
- Budgets: Create a budget for your tenancy or Always Free compartment with a low threshold (even 0) that alerts on any forecasted spend.
- Alerts and notifications: Connect budgets to email/Slack. Add Cloud Guard and basic logging to detect anomalous resource creation.

Backup, snapshot and restore patterns
-----------------------------------
- Keep backup retention short for Always Free: weekly snapshots are often enough; prune after 30 days unless required.
- Prefer configuration as code over long retention of heavy snapshots — it's cheaper to recreate infrastructure from IaC.

Security posture and least privilege
-----------------------------------
- IAM: grant only necessary rights in the Always Free compartment. Use group-based policies and temporary tokens.
- Network ACLs: lock down inbound and outbound connectivity by default. Use bastions for administrative access.

Practical examples and scripts
------------------------------
- Create Always Free compartment (CLI example):

```bash
# Create compartment (replace display-name and description)
oci iam compartment create --compartment-id <root-tenancy-ocid> --name always-free --description "Always Free sandbox"
```

- Minimal VM creation (pseudo-example):

```bash
# Note: pick an Always Free-compatible image and shape for your region
oci compute instance launch --compartment-id $COMPARTMENT_OCID --availability-domain $AD --shape <always-free-shape> \
  --display-name af-vm-smoke-01 --source-details '{"sourceType":"image","imageId":"<image-ocid>"}' --subnet-id $SUBNET_OCID
```

- Use `scripts/oci-bootstrap.sh --dry-run` (already in the repo) before any create/apply.

Runbook: start / stop / destroy safely
-------------------------------------
1. Dry-run and review plan artifact.
2. Confirm with human reviewer if changes include resource creation outside Always Free-compatible shapes.
3. Apply changes with explicit `--apply` and capture OCIDs to a secure vault.
4. For day-to-day cost control: stop non-critical instances at night and destroy test resources after each CI run.

Appendix: Troubleshooting and CLI upgrade
----------------------------------------
- If the `vault` or other commands behave differently across environments (as we saw), prefer the JSON output fallback and parse with `jq` or Python, as implemented in `scripts/oci-bootstrap.sh`.
- Upgrade OCI CLI (same method as installed in Codespaces):

```bash
# Upgrade pip-installed oci-cli in the same environment
/home/vscode/lib/oracle-cli/bin/python3 -m pip install --upgrade oci-cli
```

Final recommendations (operational checklist)
-------------------------------------------
- Create a guarded `always-free` compartment and a small set of IAM policies.
- Add repo-level checks (CI) that detect creation of non-Always-Free shapes and fail PRs.
- Use the repo's `scripts/oci-bootstrap.sh` with `--dry-run` by default and commit plan artifacts to PRs for review.
- Add budgets and alerts, and require manual approval for applies that would exceed Always Free allowances.
- Document and automate start/stop/destroy actions so you can use Always Free capacity 24/7 without surprise charges.

If you want, next I will:
- Add a `Makefile` target that runs `scripts/oci-bootstrap.sh --dry-run` and opens the plan JSON in your editor, and
- Add a CI check (lightweight) that prevents PRs that attempt to modify protected `do_not_edit_paths` or create non-Always-Free shapes (we already added a sensitive-file checker earlier).

---
Document created by repository assistant on behalf of the maintainer. Place this file at `docs/always-free-maximization.md` and update as policies or available Always Free services change.
