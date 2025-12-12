# Data Model: Stabilize Prod Deployments via CI Runners

## Entities

### Runner
- **Attributes**: id/name, role (primary|secondary), status (online|degraded|offline), last_check_in, health_metrics (cpu, mem, disk), network_reachability (prod endpoints), authorized_for_prod (bool), tags (environment, capacity), secrets_version.
- **States/Transitions**:
  - online → degraded (health threshold breach or connectivity loss)
  - degraded → online (health restored)
  - online/degraded → offline (service stopped/unreachable)
  - offline → online (service restored and health checks pass)

### DeploymentJob
- **Attributes**: job_id, artifact/version, target_env (prod), runner_id, status (queued|running|succeeded|failed|rolled_back|aborted), start_time, end_time, duration, fail_reason, retry_count, concurrency_key, logs_pointer.
- **States/Transitions**:
  - queued → running (runner picks job)
  - running → succeeded
  - running → failed (with fail_reason)
  - running → aborted (manual stop or health gate)
  - failed/aborted → rolled_back (if rollback executed)
  - failed/aborted → queued (retry)

### ProductionEnvironment
- **Attributes**: env_id, endpoints, deploy_credentials_ref, rollback_strategy (idempotent/rollback), maintenance_window, policy (serialization rules), monitoring_refs.

### SecretCredential
- **Attributes**: secret_id, purpose (deploy token/ssh), source (GitHub secrets/vault), expiry, rotation_policy, mask_in_logs (bool), last_validation.

### ObservabilitySignal
- **Attributes**: signal_id, source (runner host, pipeline), metric (uptime, job success rate, duration), threshold, alert_targets, dashboard_refs.

## Relationships
- Runner 1..n handles DeploymentJob 0..n.
- DeploymentJob targets ProductionEnvironment (1).
- DeploymentJob uses SecretCredential (1..n) for auth.
- Runner emits ObservabilitySignal 0..n; DeploymentJob emits ObservabilitySignal 0..n.
