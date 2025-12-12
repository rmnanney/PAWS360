# Research: Stabilize Prod Deployments via CI Runners

## Decisions

### 1) Runner failover approach
- **Decision**: Fail fast on primary; allow production deploys to run only on pre-approved secondary runner(s) after health checks pass.
- **Rationale**: Maintains availability while enforcing controlled, audited runner access to production.
- **Alternatives considered**: (a) Block all deploys until primary recovers (hurts availability); (b) free-form manual override to any runner (too risky for prod).
- **Implementation**: Use runner groups ("production-primary", "production-secondary") with label-based routing; primary runners use `[self-hosted, production, primary]` labels, secondary use `[self-hosted, production, secondary]`. GitHub job queuing handles failover automatically when primary offline.

### 2) Monitoring and diagnostics
- **Decision**: Expose runner host metrics (CPU/memory/disk, service status) and pipeline deploy metrics (success/fail counts, duration, fail reasons) to existing Prometheus/Grafana stack; add alerts for runner offline, deploy failure spike, and deploy duration >10m.
- **Rationale**: Aligns with constitutional monitoring mandate; provides fast detection and operator guidance.
- **Alternatives considered**: (a) Rely solely on GitHub Actions UI (insufficient observability); (b) add new monitoring stack (unnecessary complexity).
- **Implementation**: Create custom Prometheus exporter parsing runner `_diag/` logs and systemd status; export metrics for runner status (online/idle/active/offline), job success/fail/duration, queue depth. Add Grafana dashboard with panels for runner health timeline, job throughput, success rate. Configure alerts: runner offline >5min, deploy failures >3 in 1h, deploy duration >10m.

### 3) Deployment serialization and retry
- **Decision**: Use GitHub workflow concurrency controls to serialize production deploy jobs; on failure, permit safe rerun with idempotent scripts or rollback path.
- **Rationale**: Prevents conflicting prod changes; supports controlled recovery per FR-004/FR-007.
- **Alternatives considered**: (a) Allow parallel prod deploys (risk of conflict); (b) manual locks outside CI (operational overhead).
- **Implementation**: Add concurrency group to production deploy workflow:
  ```yaml
  concurrency:
    group: production-deploy
    cancel-in-progress: false  # Queue rather than cancel
  ```
  Use environment protection rules (required reviewers, branch restrictions). Implement idempotent deployment scripts or rollback-on-failure pattern with health checks post-deploy.

### 4) Secrets handling
- **Decision**: Use GitHub encrypted secrets for deploy creds; mask output; add preflight check for secret presence/expiry and fail before execution if missing.
- **Rationale**: Satisfies FR-006 zero-leakage requirement; early detection reduces failed runs.
- **Alternatives considered**: (a) Inline secrets in workflow env (leak risk); (b) manual prompts (non-automatable).
- **Implementation**: 
  - Store deployment credentials as environment-level secrets (Settings → Environments → production)
  - Add preflight validation step checking secret presence and expiry (for JWT/tokens with expiry metadata)
  - Use `::add-mask::` for any runtime-derived secrets (e.g., temporary tokens from API calls)
  - Implement post-deployment log audit scanning for leaked patterns
  - Consider OIDC for cloud provider auth to eliminate long-lived credentials
  - Set up quarterly secret rotation workflow with blue-green rollover pattern

### 5) JIRA linkage
- **Decision**: Require valid JIRA epic/story IDs to be provided before execution and annotate workflows/docs accordingly.
- **Rationale**: Constitutional Article I mandate; cannot fabricate IDs.
- **Alternatives considered**: None (blocked until provided).

---

## Additional Research: Runner Health & Lifecycle

### Runner Health Monitoring Best Practices
- **Runner states**: Idle (connected, ready), Active (executing job), Offline (disconnected/not running)
- **Health checks**: Use `./config.sh --check` to verify connectivity to all required GitHub services; monitor systemd service status via `systemctl show -p ActiveState`
- **Common health indicators**: Time since last job, runner uptime, failed job count, auto-update lag (version delta from latest release), network check failures
- **Recommended monitoring**: Custom Prometheus exporter parsing `_diag/` logs and systemd journal; alert on offline >5min, version drift >7 days, network failures

### Runner Lifecycle & Auto-scaling
- **Ephemeral runners**: Use `--ephemeral` flag for single-job runners that auto-deregister after execution; prevents persistent compromise and limits secret exposure
- **JIT (Just-in-Time) runners**: Create via REST API for auto-deregistering runners with clean environments
- **Graceful shutdown**: `sudo systemctl stop actions.runner.<org>-<repo>.<name>.service` finishes current job before stopping
- **Critical for ephemeral/JIT**: Forward logs externally before deregistration (logs deleted after runner removed)
- **Auto-update handling**: Runners must update within 30 days or jobs stop queueing; subscribe to actions/runner releases, automate updates, alert on version drift
- **Network requirements**: Verify egress to `github.com`, `api.github.com`, `objects.githubusercontent.com`, `*.actions.githubusercontent.com`; health checks should fail fast and alert if blocked
- **Service supervision**: Use systemd with `Restart=always` and `StartLimitIntervalSec` tuned to avoid flapping; monitor `journalctl -u actions.runner.*` for crash loops and auto-restart noise
- **Kubernetes-based scaling (ARC)**: If runner demand bursts, consider Actions Runner Controller (ARC) to provision ephemeral runners on Kubernetes with HPA tied to `workflow_job` queue depth; keep production runner group isolated with stricter policies.

### Runner Security & Isolation
- **Ephemeral mode** (highest priority): Use `--ephemeral` + clean environment per job to prevent persistent compromise
- **Never use self-hosted runners for public repos**: Fork PRs can execute malicious code; limit to private repos with controlled fork access
- **Runner groups & access control**: Isolate production runners in dedicated group with restricted repository access; use environment secrets with required reviewers
- **Container isolation**: Ensure Docker installed with runner user permissions; use container actions for job isolation
- **Secret handling**: Never pass secrets as CLI args (visible in `ps`); use env vars and register derived secrets with `::add-mask::`
- **OIDC for cloud auth**: Use OpenID Connect for cloud provider access to avoid long-lived credentials
- **Trusted images**: Pin runner base images and docker executor images; scan images regularly; disable auto-update inside containers and roll controlled image versions.

---

## Additional Research: Concurrency & Serialization

### GitHub Actions Concurrency Controls
- **Syntax**: 
  ```yaml
  concurrency:
    group: <string-or-expression>
    cancel-in-progress: <true|false>
  ```
- **Behavior**: At most one running + one pending job per group; cancel-in-progress=false queues new runs, cancel-in-progress=true cancels in-progress runs
- **Environment-specific patterns**:
  ```yaml
  concurrency:
    group: deploy-${{ inputs.environment || 'staging' }}
    cancel-in-progress: ${{ inputs.environment != 'production' }}
  ```
- **Queue observability**: Use `workflow_job` webhook to emit queued timestamp and calculate wait; alert if wait > N minutes for prod; scale runners (ARC or add secondary) when threshold breached.

### Idempotency & Rollback Patterns
- **State checks before deployment**: Query infrastructure/service state, set output flag to conditionally run deploy step
- **Automatic rollback on failure**:
  ```yaml
  - name: Deploy
    id: deploy
    run: deploy.sh
  - name: Health check
    id: health
    run: health-check.sh
  - name: Rollback on failure
    if: failure() && steps.deploy.outcome == 'success'
    run: rollback.sh
  ```
- **Manual rollback via workflow_dispatch**: Accept deployment_version and environment inputs, trigger rollback workflow
- **Webhook-driven scale/queue signals**: Use `workflow_job` webhook to emit queue depth and start/complete events; feed into autoscaling or alerting if queue wait exceeds threshold

### Environment Protection Rules
- **Required reviewers**: Configure in Settings → Environments → production (up to 6 people/teams); job waits until approved
- **Wait timers**: Delay job execution by specified minutes (configured in environment settings)
- **Deployment branch/tag restrictions**: Support wildcard patterns (e.g., `main`, `release/*`, `v*.*.*`)
- **Combined with concurrency**: Environment secrets + required reviewers + concurrency group = robust production deploy gate
- **Wait timers**: For prod, set environment wait timer (e.g., 10-15 minutes) to add manual pause when needed; keep `cancel-in-progress: false` to queue instead of cancel

---

## Additional Research: Secrets Management & Leak Prevention

### Secret Masking & Leak Detection
- **Automatic masking**: GitHub Actions masks registered `secrets.*` variables in logs
- **Manual masking**: Use `::add-mask::$TEMP_TOKEN` for runtime-derived secrets
- **Common leak vectors**: Secrets in step names, branch names, or exposed via echo/printf; avoid `echo "${{ secrets.FOO }}"`
- **Preflight secret scanning**: Use trufflesecurity/trufflehog action to scan code for leaked secrets before deployment
- **Post-deployment log audit**: Scan workflow logs for patterns (API keys, tokens, passwords) and fail if detected

### Secret Presence & Expiry Validation
- **Presence check**:
  ```yaml
  - name: Preflight - Validate secrets exist
    run: |
      for secret_name in DEPLOY_TOKEN SSH_KEY DB_PASSWORD; do
        if [ -z "${!secret_name}" ]; then
          echo "::error::Required secret $secret_name is not set"
          exit 1
        fi
      done
    env:
      DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
      SSH_KEY: ${{ secrets.SSH_KEY }}
  ```
- **JWT expiry check**: Decode token, extract `.exp` claim, compare to current timestamp
- **API credential health check**: Test credentials against API healthz endpoint before deployment

### OIDC for Cloud Providers
- **AWS**: Use `aws-actions/configure-aws-credentials@v4` with `role-to-assume` (no AWS_ACCESS_KEY_ID/SECRET needed)
- **Azure**: Use `azure/login@v1` with federated credentials (no client secret)
- **Google Cloud**: Use `google-github-actions/auth@v2` with workload identity provider
- **Benefits**: No long-lived credentials stored in secrets; automatic token expiry (~1 hour); auditable via cloud provider IAM logs

### Secret Rotation & Age Monitoring
- **Rotation strategy**: Quarterly scheduled workflow that generates new credentials, updates GitHub secret, revokes old credentials
- **Secret age monitoring**: Check secret `updated_at` via GitHub API, warn when >90 days old
- **Blue-green rotation**: Maintain two secret versions during rotation window for zero-downtime transition
- **Post-rotation verification**: Test new credentials before revoking old ones
- **Least-privilege GITHUB_TOKEN**: Set default `permissions` to read-only; elevate narrowly per job (e.g., `contents: read`, `deployments: write`); avoid `GITHUB_TOKEN` use on public forks for self-hosted runners
- **Secret scoping**: Prefer environment secrets for production; restrict org secrets to selected repos; avoid repo secrets when environment protections needed
- **Log forwarding**: For ephemeral/JIT runners, forward logs to centralized store before runner removal to preserve auditability without persisting secrets locally
- **Credential provenance**: Record source and issue/expiry timestamps in secret metadata or log output (masked) to speed validation/rotation decisions.

---

## Implementation Sketches

### Minimal Prometheus Exporter Outline
- Collect runner service state via systemd: `systemctl show -p ActiveState,SubState actions.runner.<org>-<repo>.<name>.service`
- Parse `_diag/Runner_*.log` for heartbeat, job start/end, update events.
- Emit gauges: `runner_online{runner="name"}=1/0`, `runner_jobs_total{status="success|failed"}`, `runner_job_duration_seconds` (summary), `runner_queue_wait_seconds` (from workflow_job webhook payloads).
- Export as HTTP endpoint (e.g., Python/Go) scraped by Prometheus; tag metrics with labels `role=primary|secondary`, `environment=production`.

### Monitoring/Alerting Targets
- Alert: runner offline >5m (primary) or >10m (secondary)
- Alert: deploy job failure count >3 in 60m for prod
- Alert: deploy duration p95 >10m
- Alert: runner version drift >7 days behind latest release
- Alert: queue wait for prod deploy >5m

### ARC Autoscaling Trigger (if Kubernetes is available)
- Ingest `workflow_job` webhook; compute queued jobs for `production` labels.
- Set HPA target: 1 runner per active prod deployment job + 1 buffer, max small count (e.g., 3) to control blast radius.
- Use ephemeral runners with image pinning and OIDC; ensure teardown after job completion.

---

## Additional Research: Production Environment & Monitoring

### Production Environment Details
- **Management**: Infrastructure is managed via Ansible (`infrastructure/ansible`).
- **Inventory Source**: `infrastructure/ansible/inventories/production/hosts`.
- **Current State**: The production inventory currently points to `localhost`. This must be updated to reflect the authoritative infrastructure addresses defined in `infrastructure/ansible/inventories/staging/hosts` (e.g., `dell-r640-01` at `192.168.0.51`) or the specific production hardware.
- **Deployment Policy**: "No rollback" is strictly enforced. Fix-forward strategy must be used for all production issues.
- **Configuration**: `docker-compose.production.yml` defines the containerized services and environment variables.

### Monitoring Wiring
- **Infrastructure Stack**:
  - **Prometheus/Grafana**: Addresses must be derived from Ansible inventory (e.g., `{{ groups['monitoring'][0] }}`) rather than hardcoded.
  - **Reference IPs**: Staging inventory uses `192.168.0.51` (dell-r640-01). Constitution references `192.168.0.200`.
  - **IaC Mandate**: All runner configurations for monitoring endpoints must use Ansible template variable substitution to ensure consistency with the authoritative inventory.
- **Integration**:
  - Ansible roles `cloudalchemy.prometheus`, `cloudalchemy.grafana`, and `cloudalchemy.node_exporter` are used to deploy and configure the monitoring stack.
  - Runners should be configured to export metrics to the Prometheus instance defined in the inventory.
- **CI/CD Metrics**:
  - Documented in `contexts/infrastructure/monitoring-stack.md`.
  - Dataflow: GitHub Actions -> metrics fetcher -> `metrics.json` -> GitHub Pages Dashboard.
  - Key metrics: `workflow_runs_total`, `workflow_run_duration_seconds`, `actions_minutes_consumed`.

### Secrets Inventory
- **Identified Secrets** (currently in plain text/defaults in `inventories/production/hosts`):
  - `postgres_password`
  - `redis_password`
  - `jwt_secret`
  - `saml_keystore_password`
  - `admin_default_password`
- **Action Item**: These secrets must be migrated from the inventory file to a secure store (Ansible Vault or GitHub Secrets) before the runner deployment is finalized. The current values are marked as "development only".
