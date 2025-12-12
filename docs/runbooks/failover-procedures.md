# Failover Procedures Runbook

**JIRA:** INFRA-474  
**Severity:** P1 - Critical  
**Last Updated:** 2024-01-XX

---

## Overview

Procedures for managing automatic and manual failover between GitHub Actions runners.

### When to Use
- Primary runner offline/degraded
- Planned maintenance
- Emergency capacity needs

### Quick Actions

**Automatic Failover:** Triggered automatically when primary runner unhealthy for > 5 minutes  
**Manual Failover:** Follow this runbook

---

## Manual Failover Procedure

### Step 1: Verify Backup Runner Health

```bash
# Check backup runner status
gh api /repos/rpalermodrums/PAWS360/actions/runners \
  --jq '.runners[] | select(.name=="Serotonin-paws360") | {name, status, busy}'

# Check backup metrics
./scripts/ci-health-check.sh --verbose
```

**Requirements:**
- Status: `online`
- Busy: `false` or acceptable load
- CPU < 50%, Memory < 60%, Disk < 70%

### Step 2: Stop Primary Runner

```bash
# Stop runner service
ssh dell-r640-01-runner 'sudo systemctl stop actions.runner.*'

# Verify stopped
ssh dell-r640-01-runner 'sudo systemctl status actions.runner.*'
```

### Step 3: Monitor Failover

```bash
# Watch jobs move to backup
watch -n 10 'gh run list --limit 5 --json status,name,conclusion'

# Check runner assignment
gh api /repos/rpalermodrums/PAWS360/actions/runs/XXXXX \
  --jq '.run_started_at, .runner_name'
```

**Expected:** New jobs route to backup within 2 minutes

### Step 4: Validate Backup Performance

```bash
# Trigger test workflow
gh workflow run ci-quick.yml --ref main

# Monitor duration (should be < 15 minutes)
gh run watch
```

---

## Failback Procedure

### Step 1: Verify Primary Runner Ready

```bash
# Check primary health
ssh dell-r640-01-runner '
  systemctl status actions.runner.*
  free -h
  df -h
  top -bn1 | head -5
'
```

### Step 2: Start Primary Runner

```bash
# Start service
ssh dell-r640-01-runner 'sudo systemctl start actions.runner.*'

# Verify online
sleep 10
gh api /repos/rpalermodrums/PAWS360/actions/runners \
  --jq '.runners[] | select(.name=="dell-r640-01-runner")'
```

### Step 3: Gradual Load Transfer

```bash
# Let primary naturally pick up new jobs
# Monitor for 30 minutes

# Check distribution
gh api /repos/rpalermodrums/PAWS360/actions/runs \
  --jq '[.workflow_runs[] | .runner_name] | group_by(.) | map({runner: .[0], count: length})'
```

---

## Emergency Procedures

### Both Runners Down

1. **Immediate:** Notify team in #infrastructure-alerts
2. **Assess:** Check both runner hosts for hardware/network issues
3. **Triage:** Determine which runner to restore first (usually primary)
4. **Execute:** Follow recovery procedures for chosen runner
5. **Communicate:** Update stakeholders every 10 minutes

### Backup Runner Degraded During Failover

1. **Stop accepting new jobs:** Set runner to maintenance mode
2. **Restart backup runner service**
3. **If unsuccessful:** Page infrastructure lead
4. **Document:** All actions taken

---

## Planned Maintenance Failover

### Pre-Maintenance Checklist
- [ ] Notify team 24 hours in advance
- [ ] Schedule during low-activity window
- [ ] Verify backup runner health
- [ ] Create maintenance issue in Jira

### Execution
1. Wait for current jobs to complete
2. Stop primary runner gracefully
3. Monitor backup for 15 minutes
4. Perform maintenance
5. Execute failback procedure

---

## Monitoring & Alerts

### Key Metrics

```promql
# Failover count
increase(runner_failover_total[24h])

# Time to failover
runner_failover_duration_seconds

# Runner availability
avg_over_time(runner_health[5m])
```

### Alert Thresholds
- Failover duration > 10 minutes: Page SRE
- Multiple failovers in 1 hour: Investigate root cause
- Both runners down > 5 minutes: Page CTO

---

## Troubleshooting

### Failover Not Occurring

**Symptom:** Jobs queue on offline runner

**Diagnosis:**
```bash
# Check runner status in GitHub
gh api /repos/rpalermodrums/PAWS360/actions/runners

# Check runner heartbeat
ssh runner-name 'journalctl -u actions.runner.* -n 50'
```

**Resolution:**
- Manually mark runner offline in GitHub UI
- Force stop runner service
- Cancel queued jobs and re-run

### Slow Failover

**Symptom:** > 10 minutes to redirect jobs

**Causes:**
- GitHub API propagation delay
- Runner heartbeat timeout
- Queued jobs assigned before failure

**Mitigation:**
- Cancel and re-run queued jobs
- Reduce runner heartbeat interval in config

---

## Post-Failover Validation

```bash
# Run comprehensive tests
./tests/ci/test-automatic-failover.sh

# Verify metrics collection
curl "http://192.168.0.200:9090/api/v1/query?query=runner_health"

# Check alert history
curl "http://192.168.0.200:9090/api/v1/alerts" | jq '.data.alerts'
```

---

## Related Resources
- [Performance Degradation Runbook](./performance-degradation.md)
- [Failure Reproduction Guide](./failure-reproduction.md)
- [Runner Setup Documentation](../../infrastructure/runners/)
