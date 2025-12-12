# GitHub Actions Runner Operations Playbook

**JIRA:** INFRA-474  
**Last Updated:** 2024-01-XX  
**Status:** Production  
**Owner:** SRE Team

---

## Table of Contents

- [Overview](#overview)
- [Daily Operations](#daily-operations)
- [Runner Management](#runner-management)
- [Failover Operations](#failover-operations)
- [Capacity Management](#capacity-management)
- [Incident Response](#incident-response)
- [Maintenance Procedures](#maintenance-procedures)
- [Troubleshooting](#troubleshooting)

---

## Overview

This playbook covers daily operations, maintenance, and incident response procedures for the PAWS360 CI/CD infrastructure.

### Infrastructure Summary

| Component | Primary | Backup |
|-----------|---------|--------|
| **Hostname** | dell-r640-01-runner | Serotonin-paws360 |
| **IP Address** | 192.168.0.201 | 192.168.0.202 |
| **CPU** | 24 cores | 16 cores |
| **Memory** | 128 GB | 64 GB |
| **Disk** | 1 TB SSD | 500 GB SSD |
| **Max Jobs** | 8 concurrent | 4 concurrent |
| **Status Page** | [Grafana Dashboard](http://192.168.0.200:3000/d/sre-overview) | |

### Key Contacts

- **SRE On-Call:** [PagerDuty rotation]
- **GitHub Admin:** @rpalermodrums
- **Infrastructure Team:** #infra-team (Slack)

---

## Daily Operations

### Morning Health Check

**Time:** First thing each workday (9:00 AM)  
**Duration:** 5-10 minutes  
**Frequency:** Daily

1. **Check Runner Status**
   ```bash
   # From any workstation with gh CLI
   gh api /repos/rpalermodrums/PAWS360/actions/runners | jq '.runners[] | {name, status, busy}'
   ```
   
   **Expected Output:**
   ```json
   {
     "name": "dell-r640-01-runner",
     "status": "online",
     "busy": false
   }
   {
     "name": "Serotonin-paws360",
     "status": "online",
     "busy": false
   }
   ```

2. **Review Active Alerts**
   - Open [Grafana SRE Overview](http://192.168.0.200:3000/d/sre-overview)
   - Check "Active Alerts" panel
   - **Green (0 alerts):** All clear
   - **Yellow (1-2 alerts):** Review alert details
   - **Red (3+ alerts):** Potential incident, investigate immediately

3. **Check Workflow Success Rate**
   - View "Workflow Success Rate 24h" gauge
   - **Target:** ≥ 95%
   - **Action if < 95%:** Review failed workflows in GitHub Actions tab

4. **Verify Monitoring Stack**
   ```bash
   # Run health check script
   cd /home/ryan/repos/PAWS360
   ./scripts/ci-health-check.sh --mode comprehensive
   ```
   
   **Expected:** "All checks passed" or specific warnings

5. **Review Capacity Trends**
   - Check "Runner CPU Usage" and "Runner Memory Usage" panels
   - Note any sustained utilization > 70%
   - Flag for capacity review if trend increasing

### Weekly Capacity Review

**Time:** Monday mornings, 9:30 AM  
**Duration:** 15-20 minutes  
**Frequency:** Weekly

1. **Run Capacity Report**
   ```bash
   # Generate weekly capacity report
   cd /home/ryan/repos/PAWS360
   ./scripts/generate-capacity-report.sh --period 7d --output reports/capacity-$(date +%Y%m%d).md
   ```

2. **Review Key Metrics:**
   - Job queue time trends
   - Runner utilization (target: 60-80%)
   - Workflow duration (P95)
   - Failover events count

3. **Identify Trends:**
   - Is utilization increasing?
   - Are workflows taking longer?
   - Are we approaching capacity limits?

4. **Take Action:**
   - Schedule capacity increase if utilization > 80% sustained
   - Investigate performance degradation if P95 duration increasing
   - Optimize workflows if specific jobs are bottlenecks

---

## Runner Management

### Starting a Runner

**Use Case:** After maintenance, reboot, or manual stop

```bash
# SSH to runner host
ssh admin@<runner-ip>

# Check current status
sudo systemctl status actions.runner.rpalermodrums-PAWS360.*.service

# Start runner service
sudo systemctl start actions.runner.rpalermodrums-PAWS360.*.service

# Verify started
sudo systemctl status actions.runner.rpalermodrums-PAWS360.*.service

# Check runner registered with GitHub
gh api /repos/rpalermodrums/PAWS360/actions/runners | jq '.runners[] | select(.name=="<runner-name>")'
```

**Verification:**
- Service status: `active (running)`
- GitHub status: `online`
- Grafana: Runner appears in "Runner Status Overview"

### Stopping a Runner

**Use Case:** Planned maintenance, hardware replacement, or emergency shutdown

```bash
# SSH to runner host
ssh admin@<runner-ip>

# Gracefully stop runner (waits for current jobs to finish)
sudo systemctl stop actions.runner.rpalermodrums-PAWS360.*.service

# Force stop if needed (terminates running jobs)
sudo systemctl kill actions.runner.rpalermodrums-PAWS360.*.service

# Verify stopped
sudo systemctl status actions.runner.rpalermodrums-PAWS360.*.service
```

**Monitoring:**
- Watch for jobs to complete: `journalctl -u actions.runner.* -f`
- Verify failover: Check backup runner starts accepting jobs in Grafana
- Confirm no queued jobs waiting: GitHub Actions tab

### Restarting a Runner

**Use Case:** Configuration changes, performance issues, or stuck jobs

```bash
# SSH to runner host
ssh admin@<runner-ip>

# Restart runner service
sudo systemctl restart actions.runner.rpalermodrums-PAWS360.*.service

# Verify restarted
sudo systemctl status actions.runner.rpalermodrums-PAWS360.*.service

# Watch logs for errors
journalctl -u actions.runner.* -f --since "1 minute ago"
```

**Post-Restart Checks:**
- Verify runner reconnects to GitHub (< 30 seconds)
- Check for error messages in logs
- Confirm workflows can execute on runner

### Checking Runner Logs

```bash
# SSH to runner host
ssh admin@<runner-ip>

# View recent logs
journalctl -u actions.runner.* -n 100

# Follow logs in real-time
journalctl -u actions.runner.* -f

# Search for errors
journalctl -u actions.runner.* --since today | grep -i error

# Export logs for analysis
journalctl -u actions.runner.* --since "2 hours ago" > /tmp/runner-logs.txt
```

### Re-registering a Runner

**Use Case:** Token expired, runner removed from GitHub, or configuration corruption

```bash
# SSH to runner host
ssh admin@<runner-ip>

# Stop runner service
sudo systemctl stop actions.runner.rpalermodrums-PAWS360.*.service

# Remove current registration
cd /home/runner/actions-runner
sudo -u runner ./config.sh remove

# Generate new registration token (from workstation)
gh api /repos/rpalermodrums/PAWS360/actions/runners/registration-token

# Re-register runner
sudo -u runner ./config.sh --url https://github.com/rpalermodrums/PAWS360 \
  --token <NEW_TOKEN> \
  --name <runner-name> \
  --labels self-hosted,Linux,X64,<primary|backup>,<high-capacity|standard-capacity>

# Restart service
sudo systemctl start actions.runner.rpalermodrums-PAWS360.*.service

# Verify registration
./run.sh --check
```

---

## Failover Operations

See also: [Failover Procedures Runbook](./runbooks/failover-procedures.md)

### Manual Failover (Primary → Backup)

**Use Case:** Planned maintenance on primary runner

**Pre-Flight Checklist:**
- [ ] Verify backup runner is healthy (CPU < 50%, Memory < 50%, Disk < 75%)
- [ ] Confirm no critical workflows currently running
- [ ] Notify team in #infra-team channel
- [ ] Schedule maintenance window (if needed)

**Steps:**

1. **Verify Backup Health**
   ```bash
   ./scripts/ci-health-check.sh --runner backup
   ```
   
   **Expected:** All checks pass

2. **Initiate Failover**
   ```bash
   # Stop primary runner
   ssh admin@192.168.0.201 "sudo systemctl stop actions.runner.rpalermodrums-PAWS360.*.service"
   ```

3. **Monitor Failover**
   - Open [Grafana SRE Overview](http://192.168.0.200:3000/d/sre-overview)
   - Watch "Runner Status Overview" - Primary should show offline
   - New jobs should route to backup within 2 minutes
   - Check "Failover Events 24h" panel

4. **Verify Failover**
   ```bash
   # Check backup runner accepting jobs
   gh run list --limit 5 --json status,name,conclusion,displayTitle
   
   # Verify backup runner is busy
   gh api /repos/rpalermodrums/PAWS360/actions/runners | jq '.runners[] | select(.name=="Serotonin-paws360")'
   ```

5. **Perform Maintenance** on primary runner

### Failback (Backup → Primary)

**Use Case:** Primary runner maintenance complete, restore normal operations

**Pre-Flight Checklist:**
- [ ] Verify primary runner is healthy and ready
- [ ] Confirm backup runner workload is manageable
- [ ] Check no critical workflows are running

**Steps:**

1. **Verify Primary Health**
   ```bash
   ssh admin@192.168.0.201 "systemctl status actions.runner.rpalermodrums-PAWS360.*.service"
   ./scripts/ci-health-check.sh --runner primary
   ```

2. **Start Primary Runner**
   ```bash
   ssh admin@192.168.0.201 "sudo systemctl start actions.runner.rpalermodrums-PAWS360.*.service"
   ```

3. **Gradual Load Transfer**
   - GitHub automatically routes new jobs to available runners
   - Monitor distribution in Grafana: "Runner CPU Usage" panel
   - Wait 10-15 minutes for gradual load balancing

4. **Verify Failback**
   - Primary runner shows "online" and "busy" in GitHub
   - Primary runner accepting new jobs (check recent workflow runs)
   - Both runners operational in Grafana

### Emergency Procedures

#### Both Runners Offline

**Detection:** Grafana alert "NoRunnersOnline" firing

**Immediate Actions:**

1. **Notify Team**
   ```
   #infra-team: 🚨 INCIDENT: Both CI/CD runners offline. Workflows queuing. Investigating.
   ```

2. **Check Runner Status**
   ```bash
   gh api /repos/rpalermodrums/PAWS360/actions/runners | jq '.runners[] | {name, status}'
   ```

3. **Attempt Remote Recovery**
   ```bash
   # Try starting primary
   ssh admin@192.168.0.201 "sudo systemctl start actions.runner.* || sudo systemctl restart actions.runner.*"
   
   # Try starting backup
   ssh admin@192.168.0.202 "sudo systemctl start actions.runner.* || sudo systemctl restart actions.runner.*"
   ```

4. **If Remote Recovery Fails:**
   - Physical access required (data center visit)
   - Check console logs for hardware failures
   - Escalate to infrastructure team lead

**Estimated RTO:** 30 minutes (with physical access)

---

## Capacity Management

See also: [Runner Capacity Planning Runbook](./runbooks/runner-capacity-planning.md)

### Capacity Triggers

Take action when:

| Trigger | Threshold | Action |
|---------|-----------|--------|
| **Job queue time** | > 5 minutes sustained | Investigate bottleneck, consider scaling |
| **Runner utilization** | > 80% for 24 hours | Plan capacity increase |
| **Workflow timeouts** | > 1 per day | Investigate performance degradation |
| **Concurrent jobs** | > 10 consistently | Add runner capacity |

### Scaling Options

#### Option 1: Vertical Scaling (Upgrade Existing)

**Timeline:** 2-4 hours (maintenance window)  
**Cost:** $500-2,000 (hardware upgrade)  
**Capacity Increase:** +50% (approx)

**Steps:**
1. Schedule maintenance window (off-hours)
2. Failover to backup runner
3. Power down primary runner
4. Install additional RAM/CPU/disk
5. Power on and verify hardware
6. Start runner service
7. Verify health and failback

#### Option 2: Horizontal Scaling (Add Runner)

**Timeline:** 1-2 days (procurement + setup)  
**Cost:** $3,000-5,000 (new server)  
**Capacity Increase:** +4-8 concurrent jobs

**Steps:**
1. Procure hardware
2. Install OS and dependencies (Ansible playbook)
3. Register runner with GitHub
4. Configure monitoring
5. Validate health
6. Add to production

#### Option 3: Dynamic Scaling (Cloud Burst)

**Timeline:** < 1 hour (immediate)  
**Cost:** $0.50-2.00/hour (AWS/Azure)  
**Capacity Increase:** Unlimited (on-demand)

**Steps:**
1. Deploy cloud runner (Terraform/Ansible)
2. Register with GitHub
3. Add labels: `cloud`, `burst`, `temporary`
4. Use for overflow capacity only
5. Decommission when not needed

---

## Incident Response

### Severity Levels

| Severity | Description | Response Time | Example |
|----------|-------------|---------------|---------|
| **P0 - Critical** | Both runners down, all workflows failing | 15 minutes | Hardware failure on both runners |
| **P1 - High** | Primary down, backup degraded | 30 minutes | Primary offline, backup high CPU |
| **P2 - Medium** | Performance degraded, some failures | 2 hours | Workflows timing out, high queue times |
| **P3 - Low** | Minor issues, no impact | 1 business day | False positive alerts, cosmetic issues |

### Incident Response Process

1. **Detection**
   - Alert fired in Grafana/Alertmanager
   - User report in #infra-team
   - Monitoring dashboard anomaly

2. **Initial Response** (within 5 minutes)
   - Acknowledge incident
   - Assess severity
   - Notify team if P0/P1

3. **Investigation** (parallel actions)
   - Review Grafana dashboards
   - Check runner system logs
   - Query Prometheus for metrics
   - Review recent changes (git log)

4. **Mitigation** (immediate)
   - Execute runbook procedure (if applicable)
   - Failover to backup if needed
   - Restart services if safe
   - Disable problematic workflows

5. **Resolution**
   - Implement permanent fix
   - Verify metrics return to normal
   - Update documentation if needed

6. **Post-Incident**
   - Write incident report
   - Conduct blameless postmortem
   - Identify preventive measures
   - Update runbooks

---

## Maintenance Procedures

### Monthly Maintenance Window

**Schedule:** 2nd Tuesday of each month, 2:00-4:00 AM  
**Duration:** 2 hours  
**Frequency:** Monthly

**Checklist:**

1. **OS Security Updates**
   ```bash
   # Primary runner
   ssh admin@192.168.0.201
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   
   # Wait 10 minutes, then backup runner
   ssh admin@192.168.0.202
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   ```

2. **Docker Cleanup**
   ```bash
   # Remove unused images/containers
   docker system prune -af --volumes
   ```

3. **Log Rotation Verification**
   ```bash
   # Check log sizes
   du -sh /var/log/* | sort -h
   
   # Verify logrotate working
   systemctl status logrotate
   ```

4. **Disk Space Check**
   ```bash
   df -h
   # Ensure no filesystem > 85%
   ```

5. **Runner Service Health**
   ```bash
   systemctl status actions.runner.*
   journalctl -u actions.runner.* --since "24 hours ago" | grep -i error
   ```

### Quarterly Maintenance

**Schedule:** March, June, September, December (1st week)  
**Duration:** 4 hours  
**Frequency:** Quarterly

**Checklist:**

1. **Hardware Health Check**
   - Check RAID status
   - Review SMART disk health
   - Verify CPU/RAM temperatures
   - Test backup power supply

2. **Capacity Planning Review**
   - Run 90-day capacity report
   - Forecast next quarter needs
   - Budget for scaling if needed

3. **Disaster Recovery Drill**
   - Simulate primary runner failure
   - Verify automatic failover works
   - Test manual failback procedure
   - Document any issues

4. **Documentation Review**
   - Update runbooks with lessons learned
   - Review contact information
   - Update architecture diagrams
   - Archive old incident reports

5. **Security Audit**
   - Review runner permissions
   - Rotate GitHub PAT tokens
   - Update SSH authorized_keys
   - Review firewall rules

---

## Troubleshooting

### Common Issues

#### Issue: Runner showing offline in GitHub

**Symptoms:** Runner status "offline", workflows not executing

**Diagnosis:**
```bash
# Check runner service
ssh admin@<runner-ip> "systemctl status actions.runner.*"

# Check network connectivity to GitHub
curl -I https://api.github.com

# Check logs for errors
journalctl -u actions.runner.* --since "10 minutes ago"
```

**Solutions:**
1. Restart runner service: `systemctl restart actions.runner.*`
2. Check network connectivity (firewall, DNS)
3. Re-register runner if token expired
4. Check GitHub status page: https://www.githubstatus.com/

---

#### Issue: Workflows timing out or hanging

**Symptoms:** Workflows exceed timeout, never complete

**Diagnosis:**
```bash
# Check runner resource usage
ssh admin@<runner-ip> "top -b -n 1 | head -20"
ssh admin@<runner-ip> "df -h"

# Check for stuck processes
ssh admin@<runner-ip> "ps aux | grep -E '(docker|node|java|npm)'"

# Check Docker
ssh admin@<runner-ip> "docker ps -a | grep -v 'Exited'"
```

**Solutions:**
1. Kill stuck processes: `pkill -f <process-name>`
2. Clean Docker: `docker system prune -af`
3. Restart runner service
4. Check specific workflow logs in GitHub

---

#### Issue: High CPU/Memory usage

**Symptoms:** CPU > 85%, Memory > 85%, performance degraded

**See:** [Performance Degradation Runbook](./runbooks/performance-degradation.md)

**Quick Actions:**
```bash
# Identify top processes
ssh admin@<runner-ip> "top -b -n 1 | head -20"

# Check concurrent jobs
gh api /repos/rpalermodrums/PAWS360/actions/runs --jq '.workflow_runs[] | select(.status=="in_progress") | {id, name, created_at}'

# Trigger failover if needed (manual)
ssh admin@<runner-ip> "sudo systemctl stop actions.runner.*"
```

---

#### Issue: Disk space full

**Symptoms:** Disk > 85%, workflows failing with "No space left on device"

**Diagnosis:**
```bash
# Check disk usage
ssh admin@<runner-ip> "df -h"

# Find large directories
ssh admin@<runner-ip> "du -sh /home/runner/actions-runner/_work/* | sort -h | tail -10"

# Check Docker disk usage
ssh admin@<runner-ip> "docker system df"
```

**Solutions:**
```bash
# Clean workflow working directories
ssh admin@<runner-ip> "rm -rf /home/runner/actions-runner/_work/*/_temp/*"

# Clean Docker
ssh admin@<runner-ip> "docker system prune -af --volumes"

# Clean old logs
ssh admin@<runner-ip> "find /var/log -name '*.log' -mtime +30 -delete"
```

---

## Related Documentation

- [CI/CD Architecture](./infrastructure/ci-cd-architecture.md)
- [Performance Degradation Runbook](./runbooks/performance-degradation.md)
- [Failover Procedures Runbook](./runbooks/failover-procedures.md)
- [Capacity Planning Runbook](./runbooks/runner-capacity-planning.md)
- [Alert False Positives Runbook](./runbooks/alert-false-positives.md)

---

**Document Owner:** SRE Team  
**Review Frequency:** Quarterly  
**Next Review:** 2024-04-XX
