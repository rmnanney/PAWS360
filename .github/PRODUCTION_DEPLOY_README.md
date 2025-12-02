Production deployment: enabling CI-driven production rollout
====================================================

This document explains how the CI-driven production deployment was configured, which secrets are required, and how we route the public DNS to the internal production host.

Summary
-------
- The CI workflow now supports building & pushing production images and running Ansible deployments against the `infrastructure/ansible/inventories/production` inventory.
- Jobs are safe by default: the workflow performs an Ansible dry-run (check-mode) unless explicitly instructed to run a real deployment.

Required repository secrets
---------------------------
- `PRODUCTION_SSH_PRIVATE_KEY` — an SSH private key (PEM) that can SSH into production hosts as the production user. Without it, CI will only run check-mode.
- `PRODUCTION_SSH_USER` — optional SSH username for production hosts (defaults to `admin` if not provided).
- `AUTO_DEPLOY_TO_PRODUCTION` — set to the string `true` to enable the real deploy step. Until set, CI runs check-mode only.
- `GHCR_PAT` (optional) — a short-lived PAT with `write:packages` if your org disallows pushing packages via `GITHUB_TOKEN`. If absent, the workflows will attempt to use `GITHUB_TOKEN`.

Safety & rollout
----------------
1. Keep `AUTO_DEPLOY_TO_PRODUCTION` unset while you validate the new workflows.
2. Run the `Deploy to production — dry-run (manual)` workflow (.github/workflows/deploy-prod-check.yml) from the Actions tab to build images and run Ansible in check mode — this requires no secrets and is safe.
3. When ready, add `PRODUCTION_SSH_PRIVATE_KEY` and set `AUTO_DEPLOY_TO_PRODUCTION=true` to allow the CI to perform live deploys (consider protecting this with an environment wait/approval step).

Health checking & DNS notes
---------------------------
- After a deploy completes, the CI job runs health checks by SSHing into each production webserver from the inventory and calling `http://localhost/actuator/health`.

Public DNS routing (your note)
------------------------------
- The external DNS name is: `paws360.ryannanney.com`.
- External DNS resolves to your public IP, which on your current network setup forwards to the internal production host at 192.168.0.75.
- Ensure firewall/NAT rules forward requests for `paws360.ryannanney.com` to the internal machine(s) running the production stack.

Network & security checklist (recommended)
-------------------------------------------
- TLS termination: Use a reverse proxy or load balancer with TLS certs for `paws360.ryannanney.com` — terminate TLS at the edge and forward traffic internally over HTTP (or maintain mTLS if desired).
- Protect the `AUTO_DEPLOY_TO_PRODUCTION` secret and limit who can update it — ideally use GitHub Environments with required reviewers for production deploy approvals.
- Use a scoped GHCR PAT or GitHub App for pushing images if organization policy requires stricter package controls.

Would you like me to:
- (A) Create a production environment protection in CI that requires manual approval before AUTO_DEPLOY_TO_PRODUCTION runs, or
- (B) Add an optional GitHub Actions approval gate and a notification (Slack/Issue) when production deploy completes (or fails)?

Security note: do not store wide-scope tokens in public repositories. Use minimal-scoped PATs or a short-lived GitHub App instead.

Lint & validation
-----------------
We added a dedicated workflow linter to run on PRs and pushes: `.github/workflows/workflow-lint.yml`. This validates workflow syntax and will appear as a status check on PRs and pushes — fix any linter findings before enabling production deploys.
