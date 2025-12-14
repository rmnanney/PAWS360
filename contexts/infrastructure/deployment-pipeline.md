---
title: "Production Deployment Pipeline"
last_updated: "2025-01-XX"
owner: "DevOps Team"
services: ["ci-cd", "github-actions"]
dependencies: ["github-runners", "ansible", "docker"]
jira_tickets: ["INFRA-472", "INFRA-473"]
ai_agent_instructions:
  - "Use GitHub Actions for all deployment automation."
  - "Enforce concurrency control: only one production deployment at a time."
  - "Validate preflight checks before deployment execution."
  - "Implement failover to secondary runner on primary failure."
  - "Collect metrics and publish to Prometheus."
---

# Production Deployment Pipeline

This file documents the CI/CD pipeline for production deployments via GitHub Actions.

## Purpose

- Automate production deployments with reliability and consistency
- Enforce safety guardrails (branch protection, approval gates)
- Provide failover capability for critical deployments
- Enable rapid incident response through diagnostics

## Pipeline Architecture

### Workflow: `.github/workflows/ci.yml`

The production deployment is orchestrated via the `deploy-to-production` job (lines 960-1092).

#### Current Configuration (To Be Enhanced)

```yaml
deploy-to-production:
  runs-on: [self-hosted, linux, x64]
  needs: [build, test]
  steps:
    - name: Deploy to production
      run: ansible-playbook -i infrastructure/ansible/inventories/production/hosts \
           infrastructure/ansible/playbooks/deploy.yml
```

#### Target Configuration (Post-Implementation)

```yaml
deploy-to-production:
  runs-on: [self-hosted, linux, x64, production]
  environment:
    name: production
    url: https://paws360.edu
  concurrency:
    group: production-deploy
    cancel-in-progress: false  # Queue instead of cancel
  needs: [build, test]
  steps:
    - name: Preflight checks
      run: ./scripts/deployment/preflight-checks.sh
    
    - name: Deploy to production
      run: ./scripts/deployment/deploy-with-failover.sh
    
    - name: Health gates
      run: ./scripts/deployment/health-gates.sh
    
    - name: Collect metrics
      run: ./scripts/monitoring/collect-deployment-metrics.sh
```

## Deployment Flow

### Phase 1: Validation

1. **Branch Check**: Verify branch is `main` or `release/*`
2. **Approval Gate**: Require manual approval from SRE team
3. **Concurrency Check**: Ensure no other production deployment active
4. **Preflight Checks**: Validate runner health, Docker, network, secrets

### Phase 2: Execution

1. **Primary Runner**: Attempt deployment on primary runner
2. **Failover Logic**: On primary failure, trigger secondary runner
3. **Deployment Steps**: Execute Ansible playbook for infrastructure updates
4. **Progress Logging**: Stream logs to centralized logging system

### Phase 3: Validation

1. **Health Gates**: Validate critical services (API, DB, Redis)
2. **Smoke Tests**: Run service-specific validation
3. **Metrics Collection**: Publish deployment success/duration to Prometheus
4. **Audit Logging**: Record deployment attribution and timestamp

## Preflight Checks

Script: `scripts/deployment/preflight-checks.sh`

### Checks Performed

1. **Runner Health**
   - CPU usage <80%
   - Memory usage <80%
   - Disk space >10GB available
   - Exit code 1 if any threshold exceeded

2. **Docker Daemon**
   - `docker ps` succeeds
   - Docker Compose available
   - Exit code 2 if Docker unavailable

3. **Network Connectivity**
   - Ping all deployment targets (from Ansible inventory)
   - DNS resolution working
   - Exit code 3 if network issues

4. **Secrets Validation**
   - Required secrets present (no content inspection)
   - Secrets: `DB_PASSWORD`, `REDIS_PASSWORD`, `API_KEY`
   - Exit code 4 if secrets missing

5. **Concurrency**
   - No other production deployment active (via GitHub API)
   - Exit code 5 if concurrent deployment detected

### Threshold Configuration

```yaml
Thresholds:
  cpu_percent_max: 80
  memory_percent_max: 80
  disk_gb_min: 10
  network_timeout_seconds: 5
  secrets_required:
    - DB_PASSWORD
    - REDIS_PASSWORD
    - API_KEY
```

## Health Gates

Script: `scripts/deployment/health-gates.sh`

### Services Validated

1. **API Service**
   - Endpoint: `http://api.paws360.local/health`
   - Expected: HTTP 200 with `{"status": "healthy"}`
   - Timeout: 5 minutes
   - Retries: 3 with exponential backoff

2. **Database (PostgreSQL)**
   - Command: `pg_isready -h db.paws360.local -U paws360`
   - Expected: "accepting connections"
   - Timeout: 5 minutes

3. **Cache (Redis)**
   - Command: `redis-cli -h redis.paws360.local ping`
   - Expected: "PONG"
   - Timeout: 5 minutes

4. **Service-Specific Smoke Tests**
   - Login endpoint: `POST /api/auth/login` (test user)
   - Course listing: `GET /api/courses` (sample data)
   - Database query: `SELECT 1` (connectivity)

### Timeout Handling

- Each service has independent 5-minute timeout
- Retries with exponential backoff (1s, 2s, 4s)
- If timeout exceeded, mark deployment as FAILED
- Alert on-call and log failure details

## Failover Mechanism

Script: `scripts/deployment/deploy-with-failover.sh`

### Failover Logic

```bash
# Attempt primary runner
if deploy_to_primary_runner; then
  log_success "Primary deployment succeeded"
  exit 0
fi

# Log failover event
log_failover "Primary runner failed, triggering secondary"

# Wait 30 seconds for transient issues to resolve
sleep 30

# Attempt secondary runner
if deploy_to_secondary_runner; then
  log_success "Secondary deployment succeeded after failover"
  exit 0
fi

# Both runners failed
log_critical "Both primary and secondary runners failed"
alert_oncall "CRITICAL: Production deployment failed on all runners"
exit 1
```

### Failover Triggers

- Primary runner exit code ≠ 0
- Primary runner timeout (30 minutes max)
- Primary runner unreachable (health check fails)
- Manual failover (emergency only)

### Failover Metrics

- `failover_events_total` (counter): Incremented on each failover
- `failover_reason` (label): primary_exit_code, primary_timeout, primary_unreachable, manual

## Concurrency Control

### GitHub Actions Concurrency

```yaml
concurrency:
  group: production-deploy
  cancel-in-progress: false  # Queue instead
```

- Only one production deployment active at a time
- Subsequent deployments queued (not canceled)
- Queue timeout: 30 minutes
- Concurrent attempts logged as violations

### Queue Management

- Queued deployments wait for active deployment to complete
- If queue timeout exceeded, fail with error message
- On-call alerted if queue depth >3
- Queue depth metric: `deployment_queue_depth`

## Metrics Collection

Script: `scripts/monitoring/collect-deployment-metrics.sh`

### Metrics Published

1. **deployment_success_total** (counter)
   - Labels: `workflow`, `branch`, `runner_group`
   - Incremented on successful deployment

2. **deployment_failure_total** (counter)
   - Labels: `workflow`, `branch`, `runner_group`, `failure_reason`
   - Incremented on failed deployment

3. **deployment_duration_seconds** (histogram)
   - Labels: `workflow`, `branch`, `runner_group`
   - Buckets: 60, 300, 600, 1200, 1800 (1min, 5min, 10min, 20min, 30min)

4. **deployment_failover_total** (counter)
   - Labels: `reason`
   - Incremented when secondary runner activated

5. **preflight_check_failures_total** (counter)
   - Labels: `check_type`
   - Incremented when preflight check fails

6. **health_gate_failures_total** (counter)
   - Labels: `service`
   - Incremented when health gate fails

### Prometheus Push Gateway

- Metrics pushed to Prometheus at 192.168.0.200:9091
- Job label: `github-actions-deployments`
- Instance label: `runner-{primary|secondary}`

## Audit Trail

### Events Logged

1. **Deployment Start**
   - Timestamp, user, branch, commit SHA
   - Workflow run ID, runner ID

2. **Preflight Check Results**
   - Each check result (pass/fail)
   - Failure details if applicable

3. **Deployment Execution**
   - Start time, end time, duration
   - Runner used (primary/secondary)
   - Exit code

4. **Failover Events**
   - Timestamp, reason, runner switched from/to

5. **Health Gate Results**
   - Each service check result (pass/fail)
   - Failure details if applicable

6. **Deployment Completion**
   - Final status (success/failure)
   - Metrics collected
   - Audit log ID

### Log Retention

- Audit logs retained for 1 year minimum
- Logs stored in centralized logging system (Grafana Loki)
- Logs tagged with `deployment_id`, `workflow_run_id`, `runner_id`

## Safety Guardrails

### Branch Protection

- Production deployments restricted to: `main`, `release/*`
- Protected branches require: 2 approvals, passing CI, no force push
- Branch validation enforced in workflow

### Approval Gates

- GitHub Environment: `production`
- Required reviewers: SRE team (`@sre-team`)
- Approval timeout: 4 hours (fail if not approved)
- Approval decision logged to audit trail

### Secrets Management

- All secrets in GitHub Secrets (no plaintext)
- Secret rotation: 90 days maximum age
- Sensitive output masking enabled
- Secret access audited

## Troubleshooting

### Deployment Stuck in Queue

- Check active deployment status via GitHub Actions UI
- Verify concurrency group not blocked
- Manual queue clear: Cancel active deployment (emergency only)

### Preflight Checks Failing

- Review preflight log for specific failure
- Common issues: disk space, Docker daemon, network
- Thresholds configurable in `scripts/deployment/preflight-checks.sh`

### Health Gates Timing Out

- Increase timeout per service (default 5min)
- Check service logs for slow startup
- Validate database connections and Redis memory

### Failover Not Triggering

- Verify secondary runner healthy (GitHub Actions settings)
- Check workflow concurrency configuration
- Review deployment script logs

## Related Documentation

- JIRA: INFRA-472 (Epic), INFRA-473 (User Story 1)
- Context: `contexts/infrastructure/github-runners.md`
- Runbook: `docs/runbooks/runner-failover.md`
- Ansible Playbooks: `infrastructure/ansible/playbooks/deploy.yml`

## Recent Changes

- 2025-01-XX: Initial context file creation for deployment pipeline stabilization
