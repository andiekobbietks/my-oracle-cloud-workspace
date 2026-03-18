# API Key Rotation — strategy, automation, and scenarios

This document captures a recommended, exhaustive approach to rotating OCI API keys (user or service keys), including the personal conclusion reached during the conversation: weekly rotation is typically excessive; prefer an automated cadence (default recommended: 90 days) unless your threat model requires shorter intervals. It describes step-by-step workflows, scripts, automation architectures, rollback patterns, and a scenario catalogue so teams of any size can choose an appropriate plan.

Contents
- Summary recommendation
- Threat model & when to shorten cadence
- Rotation workflow (scriptable) — step-by-step
- Safe automation architecture (Vault + Scheduler + Functions)
- Practical scripts and examples (CLI + Vault placeholders)
- Verification, canarying, and rollback
- Policy, auditing, and access control
- Scenario catalogue (exhaustive list and recommended cadence)
- Appendix: sample cron/CI job and minimal script skeleton

Summary recommendation
----------------------
- Default cadence: 90 days — balances operational cost and security. This is a common, industry-accepted baseline.
- If you can fully automate rotation (Vault + automated consumers), consider 30 days.
- Monthly (30 days) is reasonable if you have automation, CI/CD and solid smoke testing.
- Weekly is operationally heavy and normally unnecessary except for very high-risk keys used by untrusted parties, public automation, or incident response.

Threat model & when to shorten cadence
-------------------------------------
- Shorten cadence (30d or 7d) when:
  - Keys run in widely distributed or third-party environments where exposure risk is higher.
  - Keys protect very high-value resources and compromise impact is immediate and severe.
  - You cannot use instance principals, dynamic groups, or federated auth.
- Prefer alternate mitigations instead of ultra-short rotation where possible:
  - Use instance principals / dynamic groups instead of user keys for compute workloads.
  - Use OCI Vault to store and distribute private keys programmatically to consumers.

Rotation workflow (scriptable)
------------------------------
Goal: generate a new key, upload its public half to the user, update secrets for consumers, verify, and then remove the old key.

Assumptions (you should adapt to your infra):
- You have a user/service OCID and permission to upload/delete API keys for that user.
- You have a secret store (OCI Vault, or GitHub/GitLab/CI secrets) to hold private keys securely.

Step-by-step (atomic steps a script should implement):

1. Preparations
   - Ensure the current `~/.oci/config` or Vault configuration contains the correct `user`, `tenancy`, and `compartment` values.
   - Identify the `USER_OCID` and the `FALLBACK_KEY` (previous private key) if you keep one for emergency rollback.

2. Generate a new keypair (temporary local file)
   ```bash
   openssl genrsa -out /tmp/new_api_key.pem 2048
   chmod 600 /tmp/new_api_key.pem
   openssl rsa -pubout -in /tmp/new_api_key.pem -out /tmp/new_api_key.pub
   ```

3. Upload public key to OCI
   - Use OCI CLI: `oci iam user api-key upload --user-id $USER_OCID --key-file /tmp/new_api_key.pub`
   - Capture fingerprint from the CLI output or use `oci iam user api-keys list --user-id $USER_OCID`.

4. Store the private key securely
   - Preferred: write the private key to OCI Vault as a secret (or other secret manager). Do NOT write to logs.
   - Example placeholder (Vault specifics vary): upload `/tmp/new_api_key.pem` to a named secret `user/<username>/api_key/current`.

5. Deploy the new key to consumers
   - Update CI secret values, container images' secrets, or signal services to re-fetch the key from Vault.
   - If consumers read a file path (`~/.oci/oci_api_key.pem`), update that path atomically (write to a temp file and `mv` into place with `chmod 600`).

6. Update local/agent config (optional)
   - If you keep a central `~/.oci/config` that references a specific key fingerprint, update the `fingerprint` value for the `DEFAULT` profile or create a new profile name for the new key and switch consumers.

7. Verification / smoke tests
   - Run `oci os ns get` or another harmless read API using the new key from each consumer environment.
   - Accept success only when all critical consumers succeed.

8. Revoke old key(s)
   - Once verification completes, delete the old API key(s) via `oci iam user api-key delete --user-id $USER_OCID --fingerprint OLD:FINGER:PRINT`.
   - Retain a backup for a short rollback window only if operationally required.

9. Audit and record
   - Log the rotation (who/what/when/fingerprints) to centralized audit logs (Cloud Audit, SIEM).

Safe automation architecture
---------------------------
High-level pattern (recommended):

- OCI Vault (secrets) — central store for private keys.
- Rotation orchestrator — periodic job (GitHub Actions, OCI DevOps pipeline, or OCI Functions + Scheduler) that runs the rotation workflow.
- Health-checker — after rotation, runs a set of smoke tests against critical consumers and reports status to a monitoring channel.
- Canary ring — for widespread consumer fleets, roll the new key to a small subset first.

Flow:
1. Scheduler triggers rotation job every N days.
2. Job generates keypair, uploads public key to user, stores private key in Vault under a new version.
3. Job updates a pointer (Vault secret name) or rotates secret version.
4. Consumers (pull-based) fetch new secret and restart/reload.
5. Health-checker validates; if OK, job removes old key; if not, job rolls back to previous secret version.

Practical scripts and examples
------------------------------
The following are minimal, opinionated examples and placeholders you can adapt. They assume the `oci` CLI and `jq` are available and that you have permissions.

1) Minimal local rotation script (unsafe for production — for illustration only)

```bash
# rotate-local.sh
set -euo pipefail
USER_OCID=${USER_OCID:?}

TMPKEY=/tmp/new_api_key.pem
TMPPUB=/tmp/new_api_key.pub
openssl genrsa -out "$TMPKEY" 2048
chmod 600 "$TMPKEY"
openssl rsa -pubout -in "$TMPKEY" -out "$TMPPUB"

UPLOAD=$(oci iam user api-key upload --user-id "$USER_OCID" --key-file "$TMPPUB" --query 'data.{fingerprint:fingerprint, timeCreated:time-created}' --raw-output)
echo "Uploaded new key: $UPLOAD"

# You should now move the private key to a secret store and confirm consumers can read it.
echo "Store $TMPKEY securely and update consumers before deleting old keys."
```

2) Vault upload placeholder (example, pseudo-commands)

```bash
# pseudo: adapt to your Vault API/CLI
vault write secret/data/oci/user-api-key value@/tmp/new_api_key.pem
```

Verification, canarying, and rollback
------------------------------------
- Canary: deploy to a small set of consumers first (1–5%) and run the smoke suite.
- Health checks: for example `oci os ns get`, `oci iam user get --user-id $USER_OCID` or application-specific REST checks.
- Rollback strategy: do NOT delete old keys until verification; keep an older key available for a bounded rollback window (e.g., 1 hour) so you can restore quickly if the new key fails.

Policy, auditing, and access control
----------------------------------
- IAM: limit who can upload/delete API keys — create a dedicated automation user with just the `iam:api-keys` and Vault permissions needed.
- Auditing: enable Cloud Audit logs and send to SIEM; alert on unexpected key uploads or deletes.
- Secrets: rotate Vault encryption keys and minimize access via policies.

Scenario catalogue (exhaustive)
------------------------------
Below are many common deployment scenarios and recommended cadence / approach.

1) Single developer local machine
   - Cadence: 90 days (manual) or 180 days if low risk.
   - Approach: manual generation and upload; store private key locally with `chmod 600`.

2) CI/CD runner using secrets (small team)
   - Cadence: 90 days (automate via CI secret update) or 30 days if you can fully automate rollout.
   - Approach: generate key, upload public key, update CI secret (encrypted), run smoke tests, revoke old key.

3) Production services with few consumers (3–10 services)
   - Cadence: 30–90 days.
   - Approach: central Vault + scheduled rotation; orchestrate consumer restart/load balancing to pick up keys.

4) Large fleet of containers or VMs (hundreds/thousands)
   - Cadence: 30 days or longer with canarying.
   - Approach: secret distribution (Vault + sidecar or pull agent), Canary deployment, automated health checks, staggered rollout.

5) Serverless / Functions
   - Cadence: 90 days (functions can fetch from Vault) or 30 days if automation is fully mature.
   - Approach: store private key in Vault; Functions fetch at runtime or on cold-start; rotate secret version and verify.

6) Instance Principals / Dynamic Groups (no key) — preferred
   - Cadence: N/A (no API key to rotate). Use dynamic groups to avoid keys entirely.
   - Approach: migrate workloads to instance principals for compute resources.

7) External or third-party consumers (partners)
   - Cadence: 30 days or fewer depending on trust boundary.
   - Approach: rotate and coordinate with partners; prefer short-lived tokens and scoped service accounts.

8) Emergency/incident-driven rotation
   - Cadence: as-needed.
   - Approach: generate new key, perform canary, swap, revoke old key, and run incident postmortem.

9) Compliance-driven rotation (policy requires specific intervals)
   - Cadence: follow policy (e.g., 90 days, 60 days, etc.). Automate to ensure compliance and evidence recording.

10) Highly sensitive keys (access to billing, KMS keys, root-level tasks)
   - Cadence: 30 days or less; combine with multi-person approval for rotation.

Appendix: sample CI job (GitHub Actions) skeleton
------------------------------------------------
```yaml
name: rotate-oci-key
on:
  schedule:
    - cron: '0 2 */90 * *' # every 90 days at 02:00 UTC
jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Install OCI CLI
        run: |
          curl -fsSL https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh -o /tmp/oci-install.sh
          bash /tmp/oci-install.sh --accept-all-defaults --install-dir $HOME/oci-toolkit
          export PATH="$HOME/oci-toolkit/bin:$PATH"
      - name: Rotate key (placeholder)
        env:
          USER_OCID: ${{ secrets.USER_OCID }}
          # store encrypted Vault credentials etc.
        run: |
          # run a rotation script that uploads the public key and stores private key into Vault
          bash scripts/rotate-oci-key.sh
```

Final notes & operational checklist
----------------------------------
- Automate everything you can: generation, upload, secret storage, consumer update, tests, and delete.
- Keep a short rollback window; do not delete old keys until tests pass.
- Prefer instance principals / dynamic groups where possible to avoid long-lived private keys.
- Use OCI Vault or an equivalent secrets manager to centralize private key distribution and rotation.

File created: `docs/key-rotation.md`
