---
title: "CI/CD Monitoring Stack"
last_updated: "2025-12-11"
owner: "SRE Team"
services: ["ci-cd-dashboard", "metrics-collector", "runner-health-monitor"]
dependencies: ["prometheus", "grafana", "github-actions", "loki"]
jira_tickets: ["SCRUM-84", "INFRA-472", "INFRA-473", "INFRA-474", "INFRA-475"]
ai_agent_instructions:
  - "Use GitHub Actions API for workflow run data. Cache responses with ETag/If-Modified-Since."
  - "If adding new metrics endpoints, update monitoring discovery and dashboards."
  - "For runner metrics, use Ansible inventory variables for Prometheus/Grafana addresses (no hardcoded IPs)."
  - "Two primary dashboards: runner-health (US1) and deployment-pipeline (US2/US3)."
  - "12 Prometheus alerts cover runner health, deployment failures, rollbacks, health checks."
  - "Loki aggregates runner logs, Ansible logs, application logs for centralized search."
---

# CI/CD Monitoring Stack (metrics and discovery)

This file documents which CI/CD metrics are collected, how they are stored/published, and operational responsibilities.

## Purpose

- Provide observability into GitHub Actions usage, workflow durations, cache hit/miss rates, and quota consumption
- Drive alerting for quota thresholds and anomalous workflow behavior
- Back the static GitHub Pages dashboard with hourly-updated metrics JSON

## Metrics to Collect

### GitHub Actions Workflow Metrics
- workflow_runs_total (by workflow_name, trigger_type, branch)
- workflow_run_duration_seconds (histogram by workflow_name)
- actions_minutes_consumed (per-workflow and monthly aggregated)
- cache_hits_total / cache_misses_total (per cache_key)
- bypass_audit_count (by developer / time window)
- scheduled_job_minutes (per-schedule)

### Runner Health Metrics (INFRA-472)
- runner_availability_percent (gauge): Runner uptime over 24h
- deployment_success_rate (gauge): Success rate over 30 days
- deployment_duration_seconds (histogram): p50, p95, p99 deployment times
- failover_events_total (counter): Failover trigger count by reason
- preflight_check_failures_total (counter): By check type (disk, docker, network, secrets)
- health_gate_failures_total (counter): By service (api, db, redis)
- deployment_queue_depth (gauge): Number of queued production deployments

## Dataflow

1. GitHub Actions -> metrics fetcher (scheduled workflow) -> `monitoring/ci-cd-dashboard/data/metrics.json`
2. Dashboard (GitHub Pages) renders metrics.json and offers visualizations
3. Quota-monitor scheduled workflow evaluates metrics.json and creates `quota-alert` issues when thresholds hit

## Onboarding / Adding New Metrics

1. Add metric to `update-dashboard.yml` aggregation logic and `scripts/monitoring/calc-metrics.js`.
2. Add chart definition to `monitoring/ci-cd-dashboard/assets/`.
3. Update `contexts/infrastructure/monitoring-stack.md` with scrape or fetch changes.

## Operational Notes

- Use conditional requests (ETag / If-Modified-Since) for hourly fetches to avoid API overrun
- Keep pagination capped (page size + last N runs) for efficiency
- Archive metrics JSON history on a weekly cadence for long-term trend analysis

## Runner Monitoring Configuration (INFRA-472)

### Prometheus Address Discovery

**IMPORTANT**: Do not hardcode monitoring addresses in scripts or workflows. Use Ansible inventory variables.

```yaml
# infrastructure/ansible/inventories/production/group_vars/monitoring.yml
monitoring:
  prometheus:
    host: 192.168.0.200
    port: 9090
    pushgateway_port: 9091
  grafana:
    host: 192.168.0.200
    port: 3000
```

Scripts and workflows should reference these variables:
```bash
# GOOD: Use Ansible to retrieve address
PROMETHEUS_URL=$(ansible-inventory -i infrastructure/ansible/inventories/production/hosts \
  --host monitoring --yaml | yq '.monitoring.prometheus.host')

# BAD: Hardcoded address
PROMETHEUS_URL="http://192.168.0.200:9090"  # DON'T DO THIS
```

### Grafana Dashboard: GitHub Runners

Dashboard ID: `github-runners`
Dashboard JSON: `monitoring/grafana/dashboards/sre-overview.json`

**Access URL** (use Ansible inventory variable):
```bash
# Get Grafana URL from inventory
GRAFANA_URL=$(ansible-inventory -i infrastructure/ansible/inventories/production/hosts \
  --host monitoring --yaml | yq '.monitoring.grafana.host'):$(ansible-inventory -i infrastructure/ansible/inventories/production/hosts \
  --host monitoring --yaml | yq '.monitoring.grafana.port')

# Dashboard URL: http://${GRAFANA_URL}/d/github-runners
```

Panels:
1. **Deployment Success Rate**: Gauge showing 24h rolling success %
2. **Deployment Duration**: Histogram with p50/p95/p99
3. **Failover Events**: Counter by reason (primary_exit_code, primary_timeout, etc.)
4. **Runner Availability**: Uptime % for primary and secondary
5. **Preflight Failures**: Counter by type (disk, docker, network, secrets)
6. **Health Gate Failures**: Counter by service (api, db, redis)

### Grafana Dashboard: Deployment Pipeline (INFRA-474)

Dashboard ID: `deployment-pipeline`
Dashboard JSON: `monitoring/grafana/dashboards/deployment-pipeline.json`

**Access URL**:
```bash
# Dashboard URL: http://${GRAFANA_URL}/d/deployment-pipeline
```

Panels:
1. **Deployment Success/Fail Rate by Environment**: Time series graph
2. **Deployment Duration (p50/p95/p99)**: Percentile histogram
3. **Active Deployment Jobs**: Gauge (current running jobs)
4. **Deployment Queue Depth**: Gauge (queued deployments)
5. **Deployment Failure Reasons**: Pie chart breakdown
6. **Runner Utilization During Deployments**: Heatmap
7. **Secrets Validation Status**: Status history map
8. **Deployment Success Rate Trend (7d)**: Line graph
9. **Deployment by Runner**: Stat panel
10. **Recent Deployment Failures (Last 10)**: Table

### Log Query Templates (INFRA-474)

**Loki Access**: `http://${LOKI_HOST}:3100`
**Documentation**: `docs/runbooks/runner-log-queries.md`

Common query templates:

**1. Runner Offline Events**:
```logql
{job="github-runner",hostname=~".*"} 
| regexp `(?i)(connection.*lost|service.*stop|disconnected|terminated|exit.*code)`
```

**2. Job Failures by Runner**:
```logql
{job="github-runner",hostname=~".*"} 
| json
| status="failed"
| line_format "{{.timestamp}} {{.hostname}} job={{.job_id}} workflow={{.workflow_name}} reason={{.failure_reason}}"
```

**3. Network Connectivity Issues**:
```logql
{job="github-runner",hostname=~".*"} 
| regexp `(?i)(timeout|connection.*refused|no route to host|network.*unreachable|dns.*resolution.*failed)`
```

**4. Secret Validation Failures**:
```logql
{job="github-runner",hostname=~".*"} 
| regexp `(?i)(auth.*fail|permission denied|invalid.*credential|expired.*token|secret.*validation.*fail|unauthorized|forbidden|401|403)`
```

**Grafana Explore Links**:
- **Loki**: `http://${GRAFANA_URL}/explore?orgId=1&left={"datasource":"loki"}`
- **Prometheus**: `http://${GRAFANA_URL}/explore?orgId=1&left={"datasource":"prometheus"}`

### Troubleshooting: Runner Exporter (INFRA-474)

If runner metrics are missing in Prometheus:

**1. Check runner-exporter service status**:
```bash
# On runner host
sudo systemctl status runner-exporter

# Expected: Active: active (running)
```

**2. Verify exporter endpoint**:
```bash
# Test exporter metrics endpoint
curl http://localhost:9101/metrics | grep runner_

# Expected: runner_status, runner_cpu_usage_percent, runner_memory_usage_percent, etc.
```

**3. Check Prometheus scrape configuration**:
```bash
# Query Prometheus targets
curl -sf http://192.168.0.200:9090/api/v1/targets \
  | jq '.data.activeTargets[] | select(.labels.job == "runner-exporter")'

# Expected: "health": "up" for all runner targets
```

**4. Check firewall rules**:
```bash
# Verify port 9101 (primary) and 9102 (secondary) are open
sudo iptables -L INPUT -n | grep 910[12]

# Allow if blocked:
sudo iptables -A INPUT -p tcp --dport 9101 -j ACCEPT  # Primary
sudo iptables -A INPUT -p tcp --dport 9102 -j ACCEPT  # Secondary
```

**5. Restart exporter if needed**:
```bash
sudo systemctl restart runner-exporter
sudo systemctl status runner-exporter
```

**6. Check Ansible deployment**:
```bash
# Re-deploy runner exporter via Ansible
cd infrastructure/ansible
ansible-playbook -i inventories/production/hosts \
  playbooks/deploy-runner-exporter.yml
```

### Grafana Dashboard: GitHub Runners

Dashboard ID: `github-runners` (to be created in INFRA-474)

Panels:
1. **Deployment Success Rate**: Gauge showing 24h rolling success %
2. **Deployment Duration**: Histogram with p50/p95/p99
3. **Failover Events**: Counter by reason (primary_exit_code, primary_timeout, etc.)
4. **Runner Availability**: Uptime % for primary and secondary
5. **Preflight Failures**: Counter by type (disk, docker, network, secrets)
6. **Health Gate Failures**: Counter by service (api, db, redis)

### Alerts (INFRA-474)

- **PrimaryRunnerDown** (P2): `runner_availability_percent{runner="primary"} < 50 for 15m`
- **BothRunnersDown** (P1): `runner_availability_percent < 50 for 5m` (all runners)
- **DeploymentFailureRate** (P1): `rate(deployment_failure_total[5m]) > 0.1` (>10% failures)
- **FailoverFrequency** (P2): `increase(failover_events_total[24h]) > 5`

### Metrics Push Gateway

- Runner deployment scripts push metrics to Prometheus Push Gateway
- Address: `{monitoring.prometheus.host}:{monitoring.prometheus.pushgateway_port}`
- Job label: `github-actions-deployments`
- Instance label: `runner-{primary|secondary}`

Example:
```bash
cat <<EOF | curl --data-binary @- http://${PROMETHEUS_PUSHGATEWAY}/metrics/job/github-actions-deployments/instance/runner-primary
# TYPE deployment_success_total counter
deployment_success_total{workflow="ci",branch="main"} 1
# TYPE deployment_duration_seconds histogram
deployment_duration_seconds_bucket{le="60"} 0
deployment_duration_seconds_bucket{le="300"} 1
deployment_duration_seconds_sum 245
deployment_duration_seconds_count 1
EOF
```

