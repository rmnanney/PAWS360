Artifact reporting & CI annotations
=================================

What this does
---------------
- The CI workflow now includes an "Artifact storage — report & annotations" job (runs after the existing artifact cleanup step).
- It lists repository artifacts using the GitHub Actions REST API, computes totals (count and total bytes), uploads a JSON summary as a short-lived artifact, and writes a human-readable job summary.
- When configured thresholds are exceeded the job emits a workflow annotation (warning) so the failing or alerted run is visible in the Actions UI.

Configuration
-------------
You can control thresholds using two environment variables defined in the workflow:

- ARTIFACT_COUNT_THRESHOLD (default: 30)
- ARTIFACT_SIZE_THRESHOLD_BYTES (default: 500000000 — 500 MB)

If you want a different behavior (e.g., smaller thresholds or different retention) edit .github/workflows/ci.yml to change values or move them to repository secrets / environment if you prefer.

Where to look
-------------
- The job summary will be visible in the workflow run under job summaries for the job named "Artifact storage — report & annotations".
- If thresholds are exceeded the workflow will create an annotation (warning) that is visible at the top of the workflow run.
- A JSON snapshot of the current artifact inventory (artifact-summary.json) is uploaded as an artifact (retention: 7 days) for audit/debugging.

Pre-flight stage & additional metrics
------------------------------------
- The CI workflow arranges cleanup + reporting as a pre-flight stage. The `cleanup-artifacts` step runs first and the `artifact-report` job runs after it. The main build job now depends on the artifact-report job so the pre-flight completes before builds start.
- The artifact-report job now also checks GitHub API rate limits via the /rate_limit endpoint. It adds a human-readable note to the job summary and emits a warning annotation if the remaining quota is below the configured percent threshold.

Configuration & thresholds
--------------------------
- ARTIFACT_COUNT_THRESHOLD — default 30
- ARTIFACT_SIZE_THRESHOLD_BYTES — default 500000000 (500 MB)
- API_RATE_LIMIT_PCT_THRESHOLD — default 20 (emit a warning if remaining core API % is less than this)

Scheduled cleanup
-----------------
There is also a separate scheduled workflow `.github/workflows/artifact-cleanup.yml` that runs weekly (removes artifacts older than 7 days). The in-CI cleanup (3-day cutoff) plus the weekly job complement each other to help manage storage.

Notes & caveats
--------------
- The job uses the repository GITHUB_TOKEN to call the Actions artifacts API. On certain fork/PR workflows that token may not have permission to read the repository-level artifacts; the step is resilient and will report nothing rather than failing.
- The repository already has a short-lived automatic cleanup job (3 days) — this report provides visibility and will alert if more cleanup is needed.

Production deployment strategy (starter plan)
------------------------------------------
This is a pragmatic, low-friction plan to move the artifact-reporting workflow into production monitoring for your org.

1) Make the report reusable
	- Consider extracting the artifact-report logic to a composite action (./.github/actions/artifact-report) or a small script under .github/scripts so it can be reused by multiple workflows (CI, scheduled jobs).
	- The composite action can expose inputs for thresholds, run mode (dry-run vs auto-clean), and outputs for dashboards.

2) Scheduled runs + run-on-demand
	- Add a scheduled workflow (we added `.github/workflows/artifact-report-schedule.yml`) that runs daily and uploads an artifact snapshot. This reduces noisy per-push annotations while giving dependable daily telemetry.
	- Keep the in-CI pre-flight run for push/PRs that may need fast-fail behavior.

3) Permissions & billing endpoints
	- Some org-level billing/usage endpoints require elevated permissions — the default GITHUB_TOKEN may not have org billing access. If you need org-level billing/storage metrics, use a PAT with appropriate permissions stored in repo/org secrets, or a GitHub App with billing access.

4) Notifications & automated cleanups
	- For repeated threshold violations, consider automated actions: open a GitHub issue, send a Slack notification, or trigger an approval workflow that requires a human to confirm mass deletions.
	- Use conservative auto-clean policies (e.g., remove artifacts older than X days) and keep a short retention for non-critical artifacts.

5) Tests & dry-run
	- Add a small CI test or workflow-dispatch run that simulates artifacts (or mocks the API) to validate the report logic before enabling destructive cleanup.

6) Observability & dashboards
	- Export the daily artifact-summary.json to a central storage (S3 / internal logging) and wire to a small dashboard (or GitHub Pages) for historical trend analysis.

7) Rollout plan
	- Start by running the daily scheduled job for 2 weeks and monitor alerts. Tune thresholds.
	- If results are stable, add an automated cleanup policy (with team approvals for bulk deletes) and notify the repo owners of new retention policy.

Security & operational cautions
--------------------------------
- Do not store admin PATs in public repos. Use repository or organization secrets scoped correctly.
- For cross-repo or org-level metrics, prefer a GitHub App with the least privilege necessary.

Stage deployment from CI
------------------------
We added an optional `deploy-to-stage` flow to `.github/workflows/ci.yml` to help you promote builds into your staging environment after tests pass.

How it works
- `build-and-push-images` — builds backend and frontend Docker images, tags them with `staging-<git-sha>` and pushes to `ghcr.io/${{ github.repository }}`. This job runs after UI tests succeed and only on `master` or when manually dispatched.
- `deploy-to-stage` — runs an Ansible dry-run (check) against `infrastructure/ansible/inventories/staging` using the new images. By default this job runs in check-mode and will not perform changes.
- To perform an actual deployment, set the repository secret `AUTO_DEPLOY_TO_STAGE` to `true` (or dispatch manually with that secret) and provide an SSH key in `STAGING_SSH_PRIVATE_KEY` so CI can connect to staging nodes.

Required secrets and permissions
- `GITHUB_TOKEN` — already used to push images to GHCR (if allowed); ensure repository has packages write enabled so the CI runner can push.
- `STAGING_SSH_PRIVATE_KEY` — an SSH private key with access to your staging inventory hosts (used by Ansible/ssh). If empty, CI will perform only the Ansible --check dry-run.
- `STAGING_SSH_USER` (optional) — SSH username for staging hosts (defaults to `admin` if not provided).
- `AUTO_DEPLOY_TO_STAGE` — set to `true` to enable actual non-dry-run deploys (otherwise CI will run check-mode only).

Security and rollout guidance
- Start with `AUTO_DEPLOY_TO_STAGE` unset (or false) so CI only runs the dry-run checks and publishes the image tags.
- When you're ready, add the SSH key (as a repository secret) then enable `AUTO_DEPLOY_TO_STAGE=true` to allow automatic deploys on `master` merges.
- If you need stronger auth (recommended), create a GitHub App with narrow permissions or a short-lived PAT and store it in secrets. For GHCR pushes you can also use a PAT with `write:packages` if your org policy requires it.


