## Engineering Journey & Problem Solving
This project evolved from a simple management shell into a **Repeatable Infrastructure Framework**. Key challenges overcome:

- **Resource Constraints:** Bypassed OCI Cloud Shell's 160-hour monthly cap by migrating to a containerized GitHub Codespaces environment.
- **Dependency Conflicts:** Diagnosed and resolved build failures caused by the Debian 'Trixie' release (upstream conflict with Docker-in-Docker features).
- **Scalability:** Refactored the bootstrap process to support **Multi-Tenancy**. This repo now functions as a **Template**, allowing 5-minute deployment for new clients by injecting fresh API secrets.

## How it Works
1. **GitHub Secrets** act as the "Vault" for OCI API keys.
2. **DevContainer Lifecycle Hooks** run `setup-oci.sh` on every boot.
