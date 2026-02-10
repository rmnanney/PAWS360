Stage deployment: enabling CI-driven deployment
=============================================

This file explains the minimal steps and secrets required to enable CI-driven deployments to the staging inventory in `infrastructure/ansible/inventories/staging`.

What we added
-------------
- `build-and-push-images` job: builds backend & frontend images and pushes to `ghcr.io/${{ github.repository }}` with staging tags.
- `deploy-to-stage` job: performs an Ansible dry-run by default, and can perform a real deploy when configured.

Repository secrets to set (minimum)
---------------------------------
- `STAGING_SSH_PRIVATE_KEY` — an SSH private key that has access to the staging hosts in `inventories/staging` (PEM format). Without it, CI will only run an Ansible --check dry-run.
- `STAGING_SSH_USER` — optional SSH user (defaults to `admin` if not provided).
- `AUTO_DEPLOY_TO_STAGE` — set to the string `true` to allow CI to perform real deployments (i.e., non-dry-run). Until set, CI will run check-mode only.
- `GITHUB_TOKEN` — (automatically present) used to push artifacts to GHCR. If your org requires a PAT with packages write, create a PAT with `write:packages` and store as `GHCR_PAT` and update the workflow accordingly.

Permissions required
--------------------
- CI job uses the `packages: write` permission to push container images. Verify your repository/organization allows package publishing from workflows.

How to validate deployment in a safe way
---------------------------------------
1) Ensure `STAGING_SSH_PRIVATE_KEY` is not set. Queue the workflow on `master` or dispatch it manually — it will run a full Ansible dry-run and produce logs.
2) Review the job outputs (image tags pushed to GHCR and Ansible check-mode output) for expected behavior.
3) When confident, add `STAGING_SSH_PRIVATE_KEY` as a secret and re-run the workflow — it will still run in dry-run until `AUTO_DEPLOY_TO_STAGE` is set.
4) Finally, set `AUTO_DEPLOY_TO_STAGE = true` (as a secret) to allow live deploys on `master` merges.

Rollback & safety
-----------------
- The Ansible playbooks include `rolling-update.yml` and `rollback.yml` in `infrastructure/ansible` — use them for controlled rollouts and automated rollbacks.
- Consider protecting secrets at the organization level and restricting which branches / actions can write to GHCR.

Questions / Next steps
---------------------
- Want me to extract the build/push/deploy steps into a reusable composite action for reuse across workflows?
- Want notifications (Slack/GitHub Issue) when an AUTO_DEPLOY_TO_STAGE deployment completes or fails?

Manual dry-run workflow
-----------------------
There's a manual workflow you can run from the Actions tab to validate the staging deploy path without enabling secrets or live deploys:

- Workflow name: "Deploy to stage — dry-run (manual)" (.github/workflows/deploy-stage-check.yml)
- Use it to build images and run the Ansible playbook in check-mode against the staging inventory. It is safe to dispatch without providing `STAGING_SSH_PRIVATE_KEY`.

How to use:
1. Open the repository Actions page in GitHub and pick "Deploy to stage — dry-run (manual)".
2. Click "Run workflow" and start the check-run. Review logs and artifacts after it completes.

If you want to validate a full end-to-end deploy (non-dry-run):
1. Add `STAGING_SSH_PRIVATE_KEY` and (optionally) `STAGING_SSH_USER` repository secrets.
2. For automated live deployments set `AUTO_DEPLOY_TO_STAGE=true` in repository secrets; or for manual control, leave `AUTO_DEPLOY_TO_STAGE` off and manually edit the job / run commands.

Security reminder: do not store wide-scope tokens in public repos. Use minimal-scoped PATs or a GitHub App where possible.
