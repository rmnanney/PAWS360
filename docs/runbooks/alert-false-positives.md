# Alert False Positives Runbook

**JIRA:** INFRA-474  
**Severity:** P3 - Medium  
**Last Updated:** 2024-01-XX

---

## Overview

Guide for investigating and resolving false positive alerts in the CI/CD monitoring system.

### Definition
**False Positive:** Alert fires when no actual degradation/failure exists

### Common Causes
- Threshold too sensitive
- Metric spikes during normal operations
- Alert evaluation window too short
- Data collection issues

---

## Investigation Process

### Step 1: Verify False Positive

```bash
# Query raw metrics during alert time
ALERT_TIME="2024-01-01T12:00:00Z"

curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode "query=runner_health{instance=\"runner-name\"}" \
  --data-urlencode "time=${ALERT_TIME}" \
  | jq '.data.result[0].value'

# Check correlated metrics
curl -s "http://192.168.0.200:9090/api/v1/query_range" \
  --data-urlencode "query=100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\",instance=~\"runner-name.*\"}[5m])) * 100)" \
  --data-urlencode "start=$(date -u -d '${ALERT_TIME} - 30 minutes' +%s)" \
  --data-urlencode "end=$(date -u -d '${ALERT_TIME} + 30 minutes' +%s)" \
  --data-urlencode "step=60"
```

### Step 2: Check System Logs

```bash
# Check for legitimate system events
ssh runner-name "journalctl --since '${ALERT_TIME} - 10 minutes' --until '${ALERT_TIME} + 10 minutes' | grep -E 'error|warning|critical'"

# Check for scheduled tasks
ssh runner-name "cat /etc/crontab /etc/cron.d/* | grep -v '^#'"
```

### Step 3: Correlate with Workflows

```bash
# Check if workflows running during alert
gh run list --created "${ALERT_TIME}" --json startedAt,name,conclusion

# Check for resource-intensive workflows
gh workflow list --json name,state
```

---

## Common False Positive Scenarios

### Scenario 1: CPU Spike During Build

**Alert:** `RunnerHighCPU`  
**Cause:** Legitimate high CPU during compilation

**Diagnosis:**
```bash
# Check if spike correlates with job execution
gh run list --json startedAt,conclusion,name
```

**Resolution:**
```yaml
# Adjust alert rule - increase threshold or duration
- alert: RunnerHighCPU
  expr: avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) > 0.90  # Was 0.85
  for: 10m  # Was 5m - allow longer duration
```

### Scenario 2: Memory Spike During Cache Operations

**Alert:** `RunnerHighMemory`  
**Cause:** Docker cache operations or artifact downloads

**Diagnosis:**
```bash
# Check Docker events
ssh runner-name 'docker events --since ${ALERT_TIME} --until "${ALERT_TIME} + 5m"'
```

**Resolution:**
- Increase memory threshold from 85% to 90%
- Add alert suppression during known cache operations
- Implement memory pre-allocation checks in workflows

### Scenario 3: Disk I/O During Log Rotation

**Alert:** `RunnerDiskPressure`  
**Cause:** Logrotate running, creating temporary high I/O

**Diagnosis:**
```bash
# Check logrotate schedule
ssh runner-name 'grep -r logrotate /etc/cron.*'

# Check I/O during time period
ssh runner-name 'sar -d -s ${ALERT_TIME} -e ${ALERT_TIME_END}'
```

**Resolution:**
```yaml
# Add exception for scheduled maintenance windows
- alert: RunnerDiskPressure
  expr: |
    (rate(node_disk_io_time_seconds_total[5m]) > 0.8)
    unless on(instance) (
      hour() >= 2 and hour() <= 3  # Logrotate window
    )
```

### Scenario 4: Network Latency Spikes

**Alert:** `RunnerNetworkLatency`  
**Cause:** GitHub API rate limiting or CDN issues

**Diagnosis:**
```bash
# Test GitHub API latency
for i in {1..10}; do
  curl -o /dev/null -s -w "Time: %{time_total}s\n" https://api.github.com
  sleep 2
done

# Check for rate limiting
gh api rate_limit
```

**Resolution:**
- Increase latency threshold
- Add tolerance for intermittent spikes
- Implement retry logic in workflows

---

## Alert Tuning Guidelines

### Threshold Adjustment Process

1. **Collect baseline data:**
   ```bash
   # Get 7-day percentiles
   curl -s "http://192.168.0.200:9090/api/v1/query" \
     --data-urlencode 'query=quantile(0.95, avg_over_time(metric_name[7d]))'
   ```

2. **Set threshold:**
   - P95 value + 10% buffer
   - Must allow normal operations
   - Must catch actual degradation

3. **Test threshold:**
   ```bash
   # Replay historical data
   ./scripts/test-alert-threshold.sh --metric runner_cpu_usage --threshold 85
   ```

4. **Deploy and monitor:**
   - Apply new threshold
   - Watch for 7 days
   - Iterate if needed

### Duration Tuning

**Guidelines:**
- **Transient spikes:** Increase `for` duration to 10-15 minutes
- **Persistent issues:** Keep `for` duration at 5 minutes
- **Flapping alerts:** Add hysteresis via different thresholds for firing/resolving

**Example:**
```yaml
# Before: Fires on brief spikes
- alert: RunnerHighCPU
  expr: cpu_usage > 85
  for: 2m

# After: Only fires on sustained degradation
- alert: RunnerHighCPU
  expr: cpu_usage > 85
  for: 10m
  # AND sustained over evaluation window
  annotations:
    description: "CPU > 85% for 10+ minutes"
```

---

## Silencing Alerts

### Temporary Silence (Maintenance)

```bash
# Silence alert for 2 hours
ALERT_NAME="RunnerHighCPU"
RUNNER="runner-name"

curl -X POST http://192.168.0.200:9093/api/v2/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {"name": "alertname", "value": "'${ALERT_NAME}'", "isRegex": false},
      {"name": "instance", "value": "'${RUNNER}'", "isRegex": false}
    ],
    "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "endsAt": "'$(date -u -d '+2 hours' +%Y-%m-%dT%H:%M:%SZ)'",
    "comment": "Planned maintenance",
    "createdBy": "sre-team"
  }'
```

### Permanent Disable (If Determined Non-Critical)

```yaml
# Comment out or remove from alert rules
# File: infrastructure/monitoring/prometheus/rules/runners.yml
# 
# - alert: RunnerMinorAlert
#   expr: some_metric > threshold
#   labels:
#     severity: info
```

---

## Documentation Requirements

### False Positive Log

Maintain log of false positives:

```markdown
| Date | Alert | Root Cause | Resolution | Threshold Change |
|------|-------|------------|------------|------------------|
| 2024-01-15 | RunnerHighCPU | Docker build | Increased duration to 10m | 85% → 90% |
```

### Alert Rule Comments

```yaml
# Alert added: 2024-01-XX
# Last tuned: 2024-01-XX (increased threshold due to false positives)
# False positive rate: 5% (acceptable)
- alert: RunnerHighCPU
  expr: avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) > 0.90
  for: 10m
```

---

## Prevention

### Alert Design Best Practices

1. **Use appropriate evaluation windows:**
   - Fast detection: 1-5 minutes for critical issues
   - Noise reduction: 10-15 minutes for performance degradation

2. **Implement rate-of-change alerts:**
   ```yaml
   # Alert on sudden changes, not absolute values
   - alert: RunnerCPUSuddenIncrease
     expr: deriv(cpu_usage[5m]) > 20  # 20% increase per 5 minutes
   ```

3. **Add context to alerts:**
   ```yaml
   annotations:
     description: "CPU usage {{ $value }}% (threshold: 85%)"
     runbook: "https://docs/runbooks/performance-degradation.md"
   ```

4. **Test alerts before deployment:**
   ```bash
   # Use promtool to validate rules
   promtool check rules infrastructure/monitoring/prometheus/rules/*.yml
   ```

### Monitoring Alert Quality

```promql
# Alert false positive rate (requires manual tagging)
sum(increase(alerts_false_positive_total[7d])) / sum(increase(alerts_total[7d]))

# Alert resolution time
histogram_quantile(0.95, alert_resolution_duration_seconds)
```

---

## Review Process

### Weekly Review
- Review all false positives from past week
- Identify patterns
- Propose threshold adjustments

### Monthly Review
- Audit all alert rules
- Remove unused alerts
- Update documentation
- Review false positive rate (target: < 10%)

---

## Related Resources
- [Prometheus Alert Rules](../../infrastructure/monitoring/prometheus/rules/)
- [Monitoring Dashboard](http://192.168.0.200:3000)
- [Alert Manager Configuration](../../infrastructure/monitoring/alertmanager/)
