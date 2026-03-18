# Oracle Cloud (OCI) — Comprehensive Explainer for Newcomers

This document explains the Oracle Cloud Infrastructure (OCI) landscape, how the OCI CLI and Terraform compare, how to install and configure the OCI CLI non-interactively (useful for Codespaces/devcontainers and CI), plugins and automation, security best practices, and an overview of the "Always Free" tier — written for someone new to cloud or OCI.

## 1. Quick OCI Overview
- OCI (Oracle Cloud Infrastructure) is Oracle's public cloud offering with compute, networking, storage, identity, and managed services.
- Key concepts:
  - Tenancy: your top-level account boundary (an OCID).
  - Compartment: a namespace inside your tenancy for organizing resources.
  - OCID: Oracle's resource identifier (e.g., user, tenancy, compartment).

## 2. "Always Free" tier
- Oracle provides an "Always Free" offering that includes certain resources at no cost indefinitely for eligible accounts (examples: small compute VMs, Autonomous Database, block/object storage). Always Free availability and limits vary by region and over time.
- Important notes:
  - Always Free resources are limited in capacity and count — suitable for learning, demos, and small workloads.
  - You still need to provide a payment method when creating an account in many regions; Oracle will not charge for Always Free-eligible resources but will charge for resources outside the free limits.
  - Review the official Always Free page in the OCI Console for the current list and limits.

## 3. OCI CLI vs Terraform — when to use each

CLI (oci):
- Imperative: run commands to perform operations.
- Great for: bootstrapping, ad-hoc tasks, automation scripts, one-off migrations, developer workflows.
- Pros: immediate, flexible, scriptable.
- Cons: you must handle idempotency and state yourself.

Terraform (provider: OCI):
- Declarative: describe desired state, run `terraform plan` and `terraform apply`.
- Great for: long-lived infrastructure, team workflows, drift detection, reproducibility, reviews via plans.
- Pros: state management, idempotent plans, easier auditing and review.
- Cons: provider coverage lags at times; not ideal for detailed imperative actions.

Hybrid approach (recommended):
- Use CLI scripts for bootstrapping and lightweight automation (create compartments, upload keys, seed data).
- Use Terraform for long-term infrastructure management.

## 4. Installing OCI CLI non-interactively (why it matters)
- Interactive installers prompt for input and will block provisioning (bad for Codespaces, devcontainers, or CI).
- Non-interactive installs accept flags and default answers so provisioning can run unattended.

Key installation options:
- Official installer script supports `--accept-all-defaults` and `--install-dir` to avoid prompts.
- Alternative: `pip install oci-cli` into a Python virtual environment (good for reproducible dev envs).

## 5. Non-interactive install script (what it does)
- Creates `$HOME/.oci` and writes `config` & `oci_api_key.pem` (from environment variables if provided).
- Downloads and runs the OCI installer with `--accept-all-defaults --install-dir`.
- Sets permissions on keys/config to `600` and suggests adding `INSTALL_DIR/bin` to `PATH`.
- Leaves the environment ready for `oci` commands; you still must upload the public key to the Console.

## 6. Generating and uploading API keys
1. Generate a private key (PEM):
   ```bash
   openssl genrsa -out ~/.oci/oci_api_key.pem 2048
   chmod 600 ~/.oci/oci_api_key.pem
   openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
   ```
2. Upload `oci_api_key_public.pem` in the OCI Console -> User settings -> API Keys.
3. Compute the fingerprint to put into `~/.oci/config`:
   ```bash
   openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -c
   ```

## 7. `~/.oci/config` minimal template
Replace the OCID placeholders with values from the Console and the fingerprint from the previous step.

```
[DEFAULT]
user=ocid1.user.oc1..REPLACE_WITH_USER_OCID
fingerprint=aa:bb:cc:...   # from openssl md5 -c
key_file=/home/vscode/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..REPLACE_WITH_TENANCY_OCID
region=us-ashburn-1
```

Ensure the file and key are `chmod 600`.

## 8. Plugins and Python packages
- The OCI CLI can be extended with Python packages (plugins). Plugins must be installed into the same Python environment used by the CLI.
- If you used the installer with `--install-dir`, use that `bin/pip` to install plugins:
  ```bash
  /home/vscode/oci-toolkit/bin/pip install <plugin-package>
  ```
- If you installed via `pip` into a venv, activate the venv and `pip install` the plugin.

## 9. Codespaces / devcontainer automation
- Make the installer run during provisioning using `postCreateCommand` or a `dotfiles` script; use non-interactive installation and Codespaces secrets to provide `OCI_CONFIG_CONTENT` and `OCI_PRIVATE_KEY`.
- Example `postCreateCommand` snippet (devcontainer.json):
  ```json
  "postCreateCommand": "bash ./.devcontainer/install-oci-noninteractive.sh"
  ```
- Provide secrets via Codespaces or environment variables: `OCI_CONFIG_CONTENT`, `OCI_PRIVATE_KEY`. The script should write these to `~/.oci` safely and set `chmod 600`.

## 10. CI usage
- Store `OCI_CONFIG_CONTENT` and `OCI_PRIVATE_KEY` as encrypted secrets in your CI provider.
- In a pipeline job, restore them into `~/.oci/config` and `~/.oci/oci_api_key.pem`, set permissions, and run `oci` commands. Do not echo secret contents to logs.

## 11. Security best practices
- Never commit private keys or full config files to source control.
- Use fine-grained compartments and least-privilege policies for automated users.
- Rotate API keys periodically and remove unused keys.
- Limit who can run destructive `apply` scripts; prefer reviewed PRs for multi-file moves.

## 12. Examples: common commands
- Get object storage namespace:
  ```bash
  oci os ns get
  ```
- Create a compartment (imperative):
  ```bash
  oci iam compartment create --name dev-bootstrap --compartment-id $TENANCY_OCID
  ```

## 13. Choosing a workflow
- For learning and quick tasks: CLI + scripts + Always Free resources.
- For production infrastructure: Terraform (or OCI Resource Manager) with remote state and code review.

## 14. Troubleshooting
- "config file is invalid" — check that `~/.oci/config` includes `user`, `tenancy`, `fingerprint`, `key_file`, `region` and that `key_file` exists.
- "Missing option(s) --compartment-id" — some `oci` commands require `--compartment-id` even if your config is valid.
- If a command fails after install, confirm `PATH` points to the installed `oci` binary and the `oci` binary's Python environment contains required plugins.

## 15. Further reading
- OCI docs: https://docs.oracle.com/en-us/iaas/Content/home.htm
- OCI CLI repo and install docs: https://github.com/oracle/oci-cli
- Always Free info: see the OCI Console or Oracle's Always Free marketing pages for current details.

---
File created: `docs/oci-explainer.md`
