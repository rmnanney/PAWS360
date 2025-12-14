---
title: "Runner Log Query Templates"
last_updated: "2025-01-11"
owner: "SRE Team"
jira_tickets: ["INFRA-474"]
related_runbooks:
  - "runner-offline-restore.md"
  - "runner-degraded-resources.md"
  - "network-unreachable-troubleshooting.md"
  - "secrets-expired-rotation.md"
---

# GitHub Runner Log Query Templates

This document provides reusable log query templates for common runner issues using Loki (LogQL) and Prometheus queries. These templates help diagnose and troubleshoot GitHub Actions runner problems efficiently.

## Prerequisites

- Access to Loki at `http://192.168.0.200:3100`
- Access to Prometheus at `http://192.168.0.200:9090`
- Basic familiarity with LogQL and PromQL syntax

## Quick Access

### Grafana Explore URLs

- **Loki**: `http://192.168.0.200:3000/explore?orgId=1&left={"datasource":"loki"}`
- **Prometheus**: `http://192.168.0.200:3000/explore?orgId=1&left={"datasource":"prometheus"}`

---

## 1. Runner Offline Events

### Purpose
Identify when runners go offline due to service stops, connection loss, or crashes.

### Loki Query (LogQL)

```logql
{job="github-runner",hostname=~".*"} 
| pattern `<_> <level> <message>`
| level =~ "ERROR|FATAL"
| message =~ "(?i)(connection.*lost|service.*stop|disconnected|terminated|exit.*code)"
```

### Refined Query (Last 24 Hours)
```logql
{job="github-runner",hostname=~".*"} 
| json
| level =~ "ERROR|FATAL"
| line_format "{{.timestamp}} {{.hostname}} {{.level}} {{.message}}"
| regexp `(?i)(connection.*lost|service.*stop|disconnected|terminated|exit.*code)`
```

### Time Range Queries

**Last Hour:**
```logql
{job="github-runner"} [1h]
| regexp `(?i)(offline|disconnected|service.*stop)`
| unwrap duration
| rate() > 0
```

**Aggregate by Runner:**
```logql
sum by (hostname) (
  count_over_time(
    {job="github-runner"} 
    | regexp `(?i)(offline|connection.*lost)` [24h]
  )
)
```

### Expected Results
- Timestamp of service stop/disconnect
- Runner hostname
- Exit code or error message
- Duration offline (if reconnected)

### Remediation
See: `docs/runbooks/runner-offline-restore.md`

---

## 2. Job Failures by Runner

### Purpose
Aggregate job failures by runner to identify problematic hosts or capacity issues.

### Prometheus Query (PromQL)

```promql
# Total job failures by runner (last 24h)
sum by (runner_name) (
  increase(github_actions_workflow_job_failures_total{environment="production"}[24h])
)
```

```promql
# Failure rate by runner (%)
(
  sum by (runner_name) (
    rate(github_actions_workflow_job_failures_total{environment="production"}[1h])
  ) / 
  sum by (runner_name) (
    rate(github_actions_workflow_job_total{environment="production"}[1h])
  )
) * 100
```

### Loki Query (LogQL)

```logql
{job="github-runner",hostname=~".*"} 
| json
| status="failed"
| line_format "{{.timestamp}} {{.hostname}} job={{.job_id}} workflow={{.workflow_name}} reason={{.failure_reason}}"
```

### Aggregate by Failure Reason
```logql
sum by (failure_reason) (
  count_over_time(
    {job="github-runner"} 
    | json 
    | status="failed" [24h]
  )
)
```

### Top 5 Failing Runners
```promql
topk(5, 
  sum by (runner_name) (
    increase(github_actions_workflow_job_failures_total[24h])
  )
)
```

### Expected Results
- Runner hostname/name
- Number of failures
- Failure reasons (timeout, exit code, resource exhaustion)
- Failure rate percentage

### Remediation
- If >20% failure rate: Check runner resources → `docs/runbooks/runner-degraded-resources.md`
- If single runner high failures: Investigate specific host issues
- If widespread: Check network, secrets, or deployment issues

---

## 3. Network Connectivity Issues

### Purpose
Detect network-related failures: timeouts, connection refused, DNS resolution failures.

### Loki Query (LogQL)

```logql
{job="github-runner",hostname=~".*"} 
| regexp `(?i)(timeout|connection.*refused|no route to host|network.*unreachable|dns.*resolution.*failed|name.*resolution.*failure)`
| line_format "{{.timestamp}} {{.hostname}} {{.level}} {{.message}}"
```

### Connection Refused Errors
```logql
{job="github-runner"} 
| regexp `(?i)connection.*refused`
| json
| line_format "{{.timestamp}} {{.hostname}} target={{.target_host}} port={{.port}}"
```

### DNS Resolution Failures
```logql
{job="github-runner"} 
| regexp `(?i)(dns.*fail|name.*resolution|could not resolve host)`
| json
| line_format "{{.timestamp}} {{.hostname}} target={{.target}}"
```

### Timeout Errors by Service
```logql
sum by (target_service) (
  count_over_time(
    {job="github-runner"} 
    | json 
    | regexp `(?i)timeout` [1h]
  )
)
```

### Prometheus Query - Network Health

```promql
# Ping success rate to production hosts
avg_over_time(probe_success{job="blackbox"}[5m])

# Network latency to production
histogram_quantile(0.95, 
  rate(probe_duration_seconds_bucket{job="blackbox"}[5m])
)
```

### Expected Results
- Affected runner(s)
- Target host/service that failed
- Error type (timeout, connection refused, DNS)
- Frequency and duration of network issues

### Remediation
See: `docs/runbooks/network-unreachable-troubleshooting.md`

---

## 4. Secret Validation Failures

### Purpose
Identify authentication and credential validation failures during deployments.

### Loki Query (LogQL)

```logql
{job="github-runner",hostname=~".*"} 
| regexp `(?i)(auth.*fail|permission denied|invalid.*credential|expired.*token|secret.*validation.*fail|unauthorized|forbidden|401|403)`
| line_format "{{.timestamp}} {{.hostname}} {{.level}} secret={{.secret_name}} {{.message}}"
```

### SSH Key Failures
```logql
{job="github-runner"} 
| regexp `(?i)(ssh.*authentication.*fail|permission denied.*publickey|host key verification failed)`
| json
| line_format "{{.timestamp}} {{.hostname}} target={{.target_host}} key={{.key_path}}"
```

### API Token Expiration
```logql
{job="github-runner"} 
| regexp `(?i)(token.*expired|invalid.*token|401.*unauthorized)`
| json
| line_format "{{.timestamp}} {{.hostname}} api={{.api_endpoint}} token={{.token_name}}"
```

### Aggregate by Secret Type
```logql
sum by (secret_type) (
  count_over_time(
    {job="github-runner"} 
    | json 
    | level="ERROR"
    | regexp `(?i)auth|secret|credential` [24h]
  )
)
```

### Prometheus Query - Secret Health

```promql
# Secret validation failures (last 24h)
sum by (secret_name) (
  increase(github_actions_secret_validation_failures_total[24h])
)

# Secrets expiring in next 7 days
github_actions_secret_expiry_days < 7
```

### Expected Results
- Secret name or type
- Expiration status
- Affected runner and workflow
- Timestamp of failure

### Remediation
See: `docs/runbooks/secrets-expired-rotation.md`

---

## 5. Advanced Queries

### Runner Degradation Detection

```promql
# High CPU usage (>80%)
runner_cpu_usage_percent > 80

# High memory usage (>85%)
runner_memory_usage_percent > 85

# Low disk space (<15%)
runner_disk_free_percent < 15

# Combined degradation score
(
  (runner_cpu_usage_percent > 80) * 1 +
  (runner_memory_usage_percent > 85) * 2 +
  (runner_disk_free_percent < 15) * 3
) > 0
```

### Deployment Duration Anomalies

```promql
# Deployments >2x average duration
deployment_duration_seconds > 
  (2 * avg_over_time(deployment_duration_seconds[7d]))
```

### Job Queue Depth

```logql
{job="github-runner"} 
| json
| status="queued"
| line_format "{{.timestamp}} {{.workflow_name}} queue_time={{.queue_duration_seconds}}s"
```

---

## 6. Query Best Practices

### Performance Optimization

1. **Use specific time ranges**: Avoid unbounded queries
   ```logql
   {job="github-runner"} [1h]  # Good
   {job="github-runner"}        # Bad - unbounded
   ```

2. **Filter early**: Apply filters before parsing
   ```logql
   {job="github-runner",level="ERROR"} | json  # Good
   {job="github-runner"} | json | level="ERROR"  # Bad - parses all logs first
   ```

3. **Use label matchers**: Leverage indexed labels
   ```logql
   {job="github-runner",hostname="serotonin-paws360"}  # Good - uses index
   {job="github-runner"} | hostname="serotonin-paws360"  # Bad - scans all logs
   ```

### Query Patterns

**Template for New Queries:**
```logql
{job="<job_name>",<label_filters>} [<time_range>]
| <parser> (json|pattern|regexp)
| <filter_conditions>
| line_format "<output_template>"
| <aggregation>
```

**Example:**
```logql
{job="github-runner",environment="production"} [1h]
| json
| level="ERROR"
| line_format "{{.timestamp}} {{.hostname}}: {{.message}}"
| count_over_time([5m])
```

---

## 7. Saved Dashboards

### Grafana Dashboard: Runner Diagnostics

**Import JSON**: `monitoring/grafana/dashboards/runner-diagnostics.json`

**Panels:**
1. Runner Offline Events (last 24h)
2. Job Failures by Runner
3. Network Errors by Type
4. Secret Validation Failures
5. Runner Resource Usage
6. Deployment Duration Trends

---

## 8. Alerting Rules

### Prometheus Alerts

```yaml
groups:
  - name: runner_health
    rules:
      - alert: RunnerOffline
        expr: runner_status == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Runner {{ $labels.hostname }} is offline"
          query: '{job="github-runner",hostname="{{ $labels.hostname }}"} | regexp `offline|disconnected`'

      - alert: HighJobFailureRate
        expr: |
          (sum by (runner_name) (rate(github_actions_workflow_job_failures_total[5m])) / 
           sum by (runner_name) (rate(github_actions_workflow_job_total[5m]))) > 0.2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Runner {{ $labels.runner_name }} has >20% job failure rate"
          query: '{job="github-runner",hostname="{{ $labels.runner_name }}"} | json | status="failed"'
```

---

## 9. Troubleshooting Tips

### Loki Not Returning Results?

1. Check Loki is reachable: `curl http://192.168.0.200:3100/ready`
2. Verify log ingestion: `curl http://192.168.0.200:3100/loki/api/v1/label/job/values`
3. Check Promtail is running on runners: `systemctl status promtail`
4. Verify log file permissions: `ls -l /var/log/github-runner/`

### Prometheus Metrics Missing?

1. Check runner-exporter status: `systemctl status runner-exporter`
2. Verify Prometheus scrape config: `curl http://192.168.0.200:9090/api/v1/targets`
3. Check firewall rules: `sudo iptables -L | grep 9101`
4. Test exporter endpoint: `curl http://<runner_ip>:9101/metrics`

---

## 10. Related Documentation

- **Runbooks**: `docs/runbooks/`
  - `runner-offline-restore.md`
  - `runner-degraded-resources.md`
  - `network-unreachable-troubleshooting.md`
  - `secrets-expired-rotation.md`

- **Monitoring Stack**: `contexts/infrastructure/monitoring-stack.md`
- **Grafana Dashboards**: `monitoring/grafana/dashboards/`
- **Prometheus Alerts**: `infrastructure/prometheus/alerts/`

---

## Support

For questions or issues with log queries:
1. Check query syntax in Grafana Explore
2. Review Loki documentation: https://grafana.com/docs/loki/latest/logql/
3. Contact SRE team: `#sre-on-call` Slack channel
4. Create JIRA ticket: https://jira.example.com/projects/INFRA

---

*Last Updated: 2025-01-11*  
*JIRA: INFRA-474*  
*Owner: SRE Team*
