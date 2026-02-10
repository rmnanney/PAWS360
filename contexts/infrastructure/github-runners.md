---
title: "GitHub Actions Self-Hosted Runners"
last_updated: "2025-12-11"
owner: "SRE Team"
services: ["github-actions-runner"]
dependencies: ["docker", "github-api", "prometheus", "ansible"]
jira_tickets: ["INFRA-472", "INFRA-473", "INFRA-474", "INFRA-475"]
ai_agent_instructions:
  - "Use GitHub API for runner registration, lifecycle management, and health checks."
  - "Never hardcode runner registration tokens - retrieve from GitHub Secrets."
  - "Monitor runner availability via Prometheus metrics (runner_status, runner_cpu_usage_percent, runner_memory_usage_percent)."
  - "Respect concurrency limits for production deployments (1 active at a time via concurrency group)."
  - "Primary runner has label 'primary', secondary has label 'secondary' for failover selection."
  - "All 3 user stories complete: US1 (reliable deploys), US2 (diagnostics), US3 (safeguards)."
  - "7 deployment safeguards operational: concurrency control, health gate, state capture, transaction safety, health checks, enhanced rollback, incident tracking."
---

# GitHub Actions Self-Hosted Runners

This file documents the self-hosted GitHub Actions runner infrastructure used for production deployments.

## Purpose

- Provide reliable execution environment for production deployments
- Enable automatic failover capability for critical deployment workflows (≤30s)
- Maintain security boundaries (runners isolated from public internet)
- Support serialized deployment concurrency (prevent concurrent production deploys)

## Architecture

### Runner Groups

#### Primary Runner (production-runner-01)
- **Host**: production-runner-01.paws360.local
- **Labels**: `self-hosted`, `linux`, `x64`, `production`, `primary`
- **Concurrency**: 1 (via GitHub Actions concurrency group: production-deployment)
- **Role**: Default runner for all production deployments
- **Health Monitoring**: Prometheus runner-exporter on port 9100
- **SLA**: <30s failover to secondary on failure

#### Secondary Runner (production-runner-02)
- **Host**: production-runner-02.paws360.local
- **Labels**: `self-hosted`, `linux`, `x64`, `production`, `secondary`
- **Concurrency**: 1 (activated only when primary unavailable)
- **Role**: Failover runner for production deployments
- **Health Monitoring**: Prometheus runner-exporter on port 9100
- **Activation**: Automatic via GitHub Actions runner selection when primary offline

### Failover Policy

**Automatic Failover Behavior**:
1. Workflow specifies `runs-on: [self-hosted, production, primary]`
2. GitHub Actions attempts to assign job to primary runner
3. If primary runner offline/unavailable: GitHub automatically selects secondary runner with `[self-hosted, production, secondary]` labels
4. No manual intervention required (GitHub Actions handles runner selection)
5. Failover latency: ≤30s (GitHub Actions built-in retry + runner polling interval)
6. Prometheus alerts fire if failover occurs (see Monitoring section)

**Manual Failover Testing**:
```bash
# Disable primary runner for testing
ssh production-runner-01.paws360.local
sudo systemctl stop actions.runner.paws360-runner-01.service

# Trigger deployment - should automatically use secondary
# Monitor via GitHub Actions UI: workflow run will show secondary runner name

# Re-enable primary after test
sudo systemctl start actions.runner.paws360-runner-01.service
```

### Runner Lifecycle

```bash
# Provisioning (Ansible)
ansible-playbook -i infrastructure/ansible/inventories/production/hosts \
  infrastructure/ansible/playbooks/runner-provision.yml

# Registration (GitHub API)
./scripts/runner-management/register-runner.sh --group=primary --labels=production,primary

# Health Check Commands (Prometheus Queries)
# Query runner status (1=online, 0=offline)
curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_status{environment="production"}' | jq

# Query runner CPU usage
curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_cpu_usage_percent{hostname="production-runner-01"}' | jq

# Query runner memory usage
curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_memory_usage_percent{hostname="production-runner-01"}' | jq

# Query runner disk usage
curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_disk_usage_percent{hostname="production-runner-01"}' | jq

# Direct health check on runner host
ssh production-runner-01.paws360.local "systemctl status actions.runner.paws360-runner-01.service"

# Check runner connectivity to GitHub
ssh production-runner-01.paws360.local "curl -sf https://api.github.com/zen"

# View runner logs
ssh production-runner-01.paws360.local "journalctl -u actions.runner.paws360-runner-01.service -n 50"

# Decommissioning
./scripts/runner-management/decommission-runner.sh --runner-id=$RUNNER_ID
```

## Configuration

### Runner Requirements

- **OS**: Linux (Ubuntu 22.04 LTS recommended)
- **Arch**: x64
- **CPU**: 4 cores minimum
- **Memory**: 8GB minimum
- **Disk**: 50GB minimum (deployments + Docker images)
- **Network**: 1Gbps to production infrastructure

### Docker Configuration

- Docker Engine 20.10+ required
- Daemon listening on unix:///var/run/docker.sock
- User `runner` added to `docker` group
- Docker Compose 2.x installed

### Secrets Management

- Runner registration tokens stored in GitHub Secrets
- Tokens rotated every 90 days via scheduled workflow
- Secret access audited and logged
- No secrets in runner filesystem (retrieved at runtime)

## Preflight Checks

Before each deployment, the following checks must pass:

1. **Runner Health**: CPU <80%, Memory <80%, Disk >10GB
2. **Docker Daemon**: `docker ps` succeeds
3. **Network Connectivity**: Ping all deployment targets
4. **Secrets Validation**: Required secrets present (no content inspection)
5. **Concurrency**: No other production deployment active

Script: `scripts/deployment/preflight-checks.sh`

## Health Gates

After deployment, validate critical services:

1. **API Service**: `curl http://api.paws360.local/health` returns 200
2. **Database**: `pg_isready -h db.paws360.local` succeeds
3. **Redis**: `redis-cli -h redis.paws360.local ping` returns PONG
4. **Service-Specific**: Smoke tests per application

Script: `scripts/deployment/health-gates.sh`

## Monitoring

### Metrics Collected

- `runner_availability_percent` (gauge): Uptime percentage over 24h
- `deployment_success_rate` (gauge): Success rate over 30 days
- `deployment_duration_seconds` (histogram): p50, p95, p99
- `failover_events_total` (counter): Failover trigger count
- `preflight_failures_total` (counter): By failure type

### Dashboards

- **Primary**: Grafana dashboard at monitoring stack (192.168.0.200:3000)
- **Panels**: Success rate, duration trends, failover events, runner health

### Alerts

- `PrimaryRunnerDown` (P2): Primary runner offline >15min
- `BothRunnersDown` (P1): Both runners offline (immediate page)
- `DeploymentFailureRate` (P1): >10% failures in 5min window
- `FailoverFrequency` (P2): >5 failovers in 24h

## Operational Procedures

### Adding a New Runner

1. Provision host via Ansible playbook
2. Register runner via GitHub API (generate token first)
3. Validate runner appears in GitHub Actions settings
4. Test runner with non-production workflow
5. Update monitoring dashboards

### Replacing a Failed Runner

1. Decommission failed runner (remove from GitHub)
2. Provision replacement host
3. Register new runner with same labels
4. Validate health checks pass
5. Update Ansible inventory

### Rotating Runner Secrets

1. Generate new registration token via GitHub API
2. Store token in GitHub Secrets (replace old)
3. Re-register runner with new token
4. Verify runner appears healthy
5. Log rotation event to audit trail

### Emergency Runner Failover Test

1. Disable primary runner in GitHub Actions settings
2. Trigger production deployment (non-critical)
3. Verify secondary runner executes deployment
4. Validate failover logged to monitoring
5. Re-enable primary runner

## Troubleshooting

### Runner Not Appearing in GitHub

- Verify registration token is valid (not expired)
- Check network connectivity to api.github.com
- Review runner logs: `journalctl -u github-runner`
- Ensure runner user has correct permissions

### Preflight Checks Failing

- **Disk Space**: Prune Docker images (`docker system prune`)
- **Docker Daemon**: Restart Docker (`systemctl restart docker`)
- **Network**: Verify DNS resolution and routing
- **Secrets**: Re-generate and update in GitHub Secrets

### Health Gates Timing Out

- Increase timeout per service (default 5min)
- Check service logs for slow startup
- Verify database connection pool settings
- Review Redis memory usage

### Failover Not Triggering

- Verify secondary runner is registered and healthy
- Check workflow concurrency settings
- Review failover logic in deployment script
- Ensure monitoring detects primary failure

## Security

### Runner Isolation

- Runners on dedicated hosts (no shared workloads)
- Firewall rules restrict outbound connections
- No public IP addresses (internal network only)
- Secrets never logged or persisted to disk

### Audit Trail

- All deployments logged with: user, timestamp, commit SHA
- Failover events logged with reason
- Manual overrides logged with justification
- Audit logs retained 1 year minimum

## Dependencies

- GitHub Organization admin access (runner registration)
- Ansible inventory: `infrastructure/ansible/inventories/production/hosts`
- GitHub Secrets: `RUNNER_TOKEN_PRIMARY`, `RUNNER_TOKEN_SECONDARY`
- Monitoring stack: Prometheus/Grafana at 192.168.0.200

## Related Documentation

- JIRA: INFRA-472 (Epic), INFRA-473 (User Story 1)
- Spec: `specs/001-github-runner-deploy/spec.md`
- Runbook: `docs/runbooks/runner-failover.md`
- Ansible Playbooks: `infrastructure/ansible/playbooks/runner-*.yml`

## Recent Changes

- 2025-12-10: Updated with primary/secondary runner configuration, Prometheus health check commands, and automatic failover policy for INFRA-473 (T036)
- 2025-01-XX: Initial context file creation for runner deployment stabilization
