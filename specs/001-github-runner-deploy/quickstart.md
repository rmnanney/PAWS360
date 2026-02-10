# Quickstart: Stabilize Prod Deployments via CI Runners

1) Verify prerequisites
- Ensure GitHub self-hosted primary runner online; secondary runner pre-approved and registered.
- Obtain valid JIRA epic/story IDs for this work.
- Confirm deploy secrets present and unexpired in GitHub secrets.

2) Health checks and monitoring
- Validate runner host health (cpu/mem/disk) and network reachability to prod endpoints.
- Add/verify Prometheus scrape targets for runner host and pipeline metrics; set alerts for runner offline, deploy failures, deploy duration >10m.

3) Configure workflow gates
- Add concurrency key to production deploy workflow to serialize deploys.
- Add preflight checks: runner health, secret presence/expiry, prod reachability.
- Implement fail-fast on unhealthy primary; enable failover only to pre-approved secondary runner(s).

4) Run validation
- Execute `make ci-quick` (or `make ci-local`) to ensure pipeline health.
- Trigger a production deployment dry-run; expect success or clear diagnostics.
- Simulate runner failure to confirm failover policy and alerts.

5) Document and signal
- Update `contexts/` entries (runner, monitoring, sessions) with YAML frontmatter and current details.
- Record session status in `contexts/sessions/<owner>/current-session.yml`.
- Link workflows/docs to the correct JIRA IDs.
