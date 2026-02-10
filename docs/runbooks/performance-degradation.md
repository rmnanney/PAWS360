# Performance Degradation Runbook

**JIRA:** INFRA-474  
**Severity:** P2 - High  
**Last Updated:** 2024-01-XX

---

## Overview

This runbook provides step-by-step procedures for diagnosing and resolving runner performance degradation issues in the CI/CD infrastructure.

### Symptoms
- Increased workflow run times
- High resource utilization (CPU, memory, disk)
- Slow job queue processing
- Timeout failures in workflows

### Related Alerts
- `RunnerHighCPU`
- `RunnerHighMemory`
- `RunnerDiskPressure`
- `RunnerPerformanceDegradation`

---

## Quick Reference

| Severity | Response Time | Action Required |
|----------|--------------|-----------------|
| Critical | < 5 minutes | Immediate failover |
| High | < 15 minutes | Investigation + remediation |
| Medium | < 1 hour | Planned remediation |

---

## Diagnosis

### Step 1: Verify Alert

```bash
# Check active alerts for the runner
curl -s "http://192.168.0.200:9090/api/v1/alerts" \
  | jq '.data.alerts[] | select(.labels.instance | contains("runner-name"))'
```

### Step 2: Check Runner Health

```bash
# Run comprehensive health check
./scripts/ci-health-check.sh --comprehensive --verbose

# Check specific runner metrics
curl -s "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=100 - (avg(irate(node_cpu_seconds_total{mode="idle",instance=~"runner-name.*"}[5m])) * 100)'
```

**Expected Output:**
- CPU usage < 70%
- Memory usage < 80%
- Disk usage < 85%

### Step 3: Identify Root Cause

#### High CPU Usage

```bash
# SSH to affected runner
ssh runner-name

# Check top CPU consumers
top -bn1 | head -20

# Check for runaway processes
ps aux --sort=-%cpu | head -10

# Check system load
uptime
```

**Common Causes:**
- Build processes consuming excessive CPU
- Multiple concurrent jobs
- Background system processes
- Docker container issues

#### High Memory Usage

```bash
# Check memory consumers
ps aux --sort=-%mem | head -10

# Check for memory leaks
free -h
cat /proc/meminfo

# Check swap usage
swapon --show
```

**Common Causes:**
- Memory leaks in runner processes
- Large build artifacts in memory
- Insufficient cleanup between jobs
- Docker container memory usage

#### High Disk I/O

```bash
# Check disk I/O stats
iostat -x 1 5

# Check top I/O consumers
iotop -oPa -d 5

# Check disk usage
df -h
du -sh /home/*/actions-runner/* | sort -h | tail -10
```

**Common Causes:**
- Large log files
- Build artifact accumulation
- Docker image cache growth
- Insufficient disk cleanup

---

## Resolution

### Immediate Actions (Critical Severity)

#### 1. Initiate Failover

```bash
# Check backup runner availability
gh api /repos/rpalermodrums/PAWS360/actions/runners \
  --jq '.runners[] | select(.status=="online" and .busy==false)'

# If backup available, stop primary runner to force failover
ssh runner-name 'sudo systemctl stop actions.runner.*'
```

#### 2. Clear Job Queue

```bash
# Cancel queued workflows on degraded runner
gh run list --status queued --limit 10 --json databaseId \
  | jq -r '.[].databaseId' \
  | xargs -I {} gh run cancel {}
```

#### 3. Notify Team

```bash
# Post to Slack/communication channel
echo "🚨 Runner degradation detected on runner-name. Failover initiated."
```

### Remediation Actions (High/Medium Severity)

#### CPU Remediation

```bash
# Kill runaway processes (if identified)
ssh runner-name 'sudo pkill -f <process-name>'

# Restart runner service
ssh runner-name 'sudo systemctl restart actions.runner.*'

# Limit concurrent jobs (if needed)
# Edit runner labels to reduce capacity temporarily
```

#### Memory Remediation

```bash
# Clear caches
ssh runner-name '
  docker system prune -af
  sudo sync
  sudo echo 3 > /proc/sys/vm/drop_caches
'

# Restart runner to clear memory
ssh runner-name 'sudo systemctl restart actions.runner.*'

# Check for and kill memory-leaking processes
ssh runner-name 'ps aux --sort=-%mem | head -5'
```

#### Disk I/O Remediation

```bash
# Clean up old logs
ssh runner-name '
  find /home/*/actions-runner/_diag -name "*.log" -mtime +7 -delete
  find /var/log -name "*.log" -mtime +30 -delete
'

# Clean Docker resources
ssh runner-name '
  docker system prune -af --volumes
  docker image prune -af
'

# Remove old workflow artifacts
ssh runner-name '
  find /home/*/actions-runner/_work -type d -name ".artifacts" -mtime +3 -exec rm -rf {} +
'

# Force log rotation
ssh runner-name 'sudo logrotate -f /etc/logrotate.d/github-runner'
```

### Long-term Solutions

#### 1. Implement Automated Cleanup

Create cron job on runner:

```bash
# Add to /etc/cron.daily/runner-cleanup.sh
#!/bin/bash
# Clean old logs
find /home/*/actions-runner/_diag -name "*.log" -mtime +7 -delete
# Clean Docker resources
docker system prune -af --volumes
# Clean work directories
find /home/*/actions-runner/_work -type d -mtime +3 -exec rm -rf {} +
```

#### 2. Optimize Workflow Definitions

```yaml
# Add cleanup steps to workflows
- name: Cleanup artifacts
  if: always()
  run: |
    docker system prune -af
    rm -rf ${GITHUB_WORKSPACE}/.cache
```

#### 3. Increase Runner Capacity

- Evaluate adding more runners
- Upgrade runner hardware (CPU, RAM, disk)
- Implement job distribution improvements

---

## Verification

### Step 1: Confirm Metrics Return to Normal

```bash
# Check runner metrics
./scripts/ci-health-check.sh

# Query Prometheus for trends
curl -s "http://192.168.0.200:9090/api/v1/query_range" \
  --data-urlencode 'query=100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)' \
  --data-urlencode "start=$(date -u -d '1 hour ago' +%s)" \
  --data-urlencode "end=$(date -u +%s)" \
  --data-urlencode "step=60"
```

**Success Criteria:**
- CPU usage < 70% for 10+ minutes
- Memory usage < 80%
- Disk I/O < 50% utilization
- No active alerts

### Step 2: Validate Workflow Performance

```bash
# Trigger test workflow
gh workflow run ci-quick.yml --ref main

# Monitor execution time
gh run list --limit 1 --json status,conclusion,duration

# Compare to baseline
# Expected: < 10 minutes for ci-quick workflow
```

### Step 3: Restore Full Capacity

```bash
# Restart primary runner (if stopped)
ssh runner-name 'sudo systemctl start actions.runner.*'

# Verify both runners online
gh api /repos/rpalermodrums/PAWS360/actions/runners \
  --jq '.runners[] | {name, status, busy}'
```

---

## Prevention

### Monitoring Improvements

1. **Set up predictive alerts:**
   ```yaml
   # Add to prometheus rules
   - alert: RunnerCPUTrending
     expr: predict_linear(node_cpu_usage[1h], 3600) > 85
     annotations:
       summary: "Runner CPU trending toward degradation"
   ```

2. **Enable capacity alerts:**
   ```yaml
   - alert: RunnerCapacityLow
     expr: count(runner_health{busy="true"}) / count(runner_health) > 0.8
     annotations:
       summary: "Runner capacity at 80%"
   ```

### Capacity Planning

- **Review metrics weekly:**
  - Peak usage times
  - Average job duration
  - Queue wait times

- **Trigger thresholds for adding capacity:**
  - Average queue time > 5 minutes
  - Concurrent job utilization > 80%
  - More than 2 degradation incidents per week

### Maintenance Schedule

- **Daily:** Automated cleanup scripts
- **Weekly:** Review performance metrics
- **Monthly:** Runner OS updates and restarts
- **Quarterly:** Capacity planning review

---

## Escalation

### When to Escalate

- Degradation persists > 30 minutes
- Backup runner also degraded
- Multiple simultaneous workflow failures
- Unable to identify root cause

### Escalation Contacts

1. **Primary:** SRE On-Call (Slack: @sre-oncall)
2. **Secondary:** Infrastructure Team Lead
3. **Emergency:** CTO

### Escalation Procedure

1. Post in #infrastructure-alerts Slack channel
2. Include:
   - Alert details
   - Actions taken
   - Current runner status
   - Impact assessment
3. Page SRE on-call if no response in 10 minutes

---

## Post-Incident

### Required Actions

1. **Document incident:**
   - Root cause identified
   - Timeline of events
   - Actions taken
   - Resolution details

2. **Update runbook if needed:**
   - New symptoms discovered
   - More effective remediation steps
   - Prevention measures

3. **Review with team:**
   - Incident review meeting
   - Identify improvements
   - Update monitoring/alerting

### Incident Template

```markdown
## Performance Degradation Incident Report

**Date:** YYYY-MM-DD
**Duration:** X minutes
**Affected Runner:** runner-name
**Impact:** X workflows delayed

### Timeline
- HH:MM - Alert fired
- HH:MM - Investigation started
- HH:MM - Root cause identified
- HH:MM - Remediation applied
- HH:MM - Resolved

### Root Cause
[Description]

### Resolution
[Steps taken]

### Prevention
[Measures implemented]

### Action Items
- [ ] Item 1
- [ ] Item 2
```

---

## Related Resources

- [Failure Reproduction Guide](./failure-reproduction.md)
- [CI Health Check Script](../../scripts/ci-health-check.sh)
- [Monitoring Dashboard](http://192.168.0.200:3000)
- [Alert Rules](../../infrastructure/monitoring/prometheus/rules/)

---

**Maintained By:** SRE Team  
**Review Schedule:** Monthly  
**Last Incident:** N/A
