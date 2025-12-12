---
title: "Runner Offline - Restore Service"
severity: "Critical"
category: "Runner Health"
last_updated: "2025-01-11"
owner: "SRE Team"
jira_tickets: ["INFRA-474"]
related_runbooks:
  - "runner-degraded-resources.md"
  - "network-unreachable-troubleshooting.md"
  - "failure-reproduction.md"
estimated_time: "10-15 minutes"
---

# Runner Offline - Restore Service

## Overview

This runbook provides step-by-step procedures to diagnose and restore a GitHub Actions runner that has gone offline unexpectedly.

**Severity**: Critical  
**Impact**: Deployments blocked, CI/CD pipeline halted  
**Response Time**: < 5 minutes

---

## Symptoms

- ✗ Runner not accepting new jobs from GitHub Actions
- ✗ Runner last check-in timestamp > 5 minutes ago
- ✗ Prometheus alert: `RunnerOffline` firing
- ✗ GitHub Actions UI shows runner as "Offline"
- ✗ Deployment workflows queued or failing with "No runners available"

### Detection Methods

1. **Prometheus Alert**:
   ```promql
   runner_status{hostname="<runner_name>"} == 0
   ```

2. **GitHub API**:
   ```bash
   gh api /repos/rmnanney/PAWS360/actions/runners \
     | jq '.runners[] | select(.status == "offline")'
   ```

3. **Grafana Dashboard**:
   - Navigate to: `http://192.168.0.200:3000/d/runner-health`
   - Check "Runner Status Overview" panel

---

## Diagnosis

### Step 1: Verify Runner Process Status

SSH into the affected runner host:

```bash
# Primary runner: Serotonin-paws360 (192.168.0.13)
ssh admin@192.168.0.13

# Secondary runner: dell-r640-01 (192.168.0.51)
ssh admin@192.168.0.51
```

Check the runner service status:

```bash
# Check service status
sudo systemctl status actions.runner.rmnanney-PAWS360.<runner-name>.service

# Expected output if running:
# ● actions.runner.rmnanney-PAWS360.Serotonin-paws360.service
#    Loaded: loaded (/etc/systemd/system/...)
#    Active: active (running) since ...
```

If service is **stopped** or **failed**:

```bash
# Check recent logs
sudo journalctl -u actions.runner.rmnanney-PAWS360.<runner-name>.service -n 50 --no-pager

# Common failure indicators:
# - "Connection refused" → Network issue
# - "Authentication failed" → Token expired
# - "Terminated by signal" → OOM killer or manual stop
# - "Exit code 1" → Configuration error
```

### Step 2: Check Network Connectivity

Verify runner can reach GitHub:

```bash
# Test GitHub API connectivity
curl -sf https://api.github.com/zen

# Test HTTPS connectivity
curl -sf -I https://github.com

# Check DNS resolution
nslookup api.github.com

# Test network path
traceroute api.github.com
```

If network tests fail, see: [`network-unreachable-troubleshooting.md`](./network-unreachable-troubleshooting.md)

### Step 3: Check Runner Authentication Token

Verify runner token is valid:

```bash
# Check runner configuration file
cat ~/actions-runner/.runner

# Expected fields:
# - agentId: <numeric_id>
# - agentName: "<runner_name>"
# - gitHubUrl: "https://github.com/rmnanney/PAWS360"

# Check token expiration (if using PAT)
gh auth status
```

If token is expired or invalid, see: [`secrets-expired-rotation.md`](./secrets-expired-rotation.md)

### Step 4: Check System Resources

Verify sufficient resources available:

```bash
# Check disk space (need > 20% free)
df -h /

# Check memory usage (need > 20% free)
free -h

# Check CPU load
uptime

# Check for OOM kills
sudo journalctl -k | grep -i "out of memory"
```

If resource exhaustion detected, see: [`runner-degraded-resources.md`](./runner-degraded-resources.md)

### Step 5: Check Runner Logs

Review detailed runner logs:

```bash
# Runner diagnostic logs
cd ~/actions-runner/_diag
ls -lt | head -10  # Find most recent log

# View recent worker log
tail -100 Worker_*.log

# Search for errors
grep -i "error\|fatal\|exception" Worker_*.log | tail -20
```

Common log patterns:
- **"HTTP 401 Unauthorized"** → Token expired
- **"Connection timeout"** → Network or firewall issue
- **"Disk quota exceeded"** → Disk space full
- **"Signal 9 (SIGKILL)"** → OOM killer

---

## Remediation

### Option 1: Restart Runner Service (Quick Fix)

If runner process stopped but no underlying issues detected:

```bash
# Restart the runner service
sudo systemctl restart actions.runner.rmnanney-PAWS360.<runner-name>.service

# Verify service started successfully
sudo systemctl status actions.runner.rmnanney-PAWS360.<runner-name>.service

# Check runner logs for startup
sudo journalctl -u actions.runner.rmnanney-PAWS360.<runner-name>.service -n 20 --no-pager
```

Wait 2-3 minutes for runner to check in with GitHub.

### Option 2: Reconfigure Runner (Token Issue)

If authentication token is invalid or expired:

```bash
# Stop the service
sudo systemctl stop actions.runner.rmnanney-PAWS360.<runner-name>.service

# Remove runner from GitHub
cd ~/actions-runner
./config.sh remove --token <REMOVAL_TOKEN>

# Re-register runner with new token
./config.sh --url https://github.com/rmnanney/PAWS360 \
  --token <NEW_REGISTRATION_TOKEN> \
  --name <runner-name> \
  --labels self-hosted,Linux,X64,production

# Restart service
sudo systemctl start actions.runner.rmnanney-PAWS360.<runner-name>.service
```

**Get Registration Token**:
```bash
# Via GitHub CLI (requires admin permissions)
gh api --method POST /repos/rmnanney/PAWS360/actions/runners/registration-token \
  | jq -r '.token'

# Or via GitHub UI:
# Settings → Actions → Runners → New self-hosted runner
```

### Option 3: Fix Network Issues

If network connectivity problems identified:

1. **Check firewall rules**:
   ```bash
   # Verify outbound HTTPS allowed
   sudo iptables -L OUTPUT -n | grep 443
   
   # Verify DNS allowed
   sudo iptables -L OUTPUT -n | grep 53
   ```

2. **Check routing**:
   ```bash
   # Verify default gateway
   ip route show
   
   # Test gateway reachability
   ping -c 3 $(ip route | grep default | awk '{print $3}')
   ```

3. **Restart networking** (if safe):
   ```bash
   sudo systemctl restart networking
   ```

See: [`network-unreachable-troubleshooting.md`](./network-unreachable-troubleshooting.md) for detailed network diagnostics.

### Option 4: Clear Disk Space

If disk space exhausted:

```bash
# Clean Docker resources
docker system prune -a -f --volumes

# Clean old runner logs
find ~/actions-runner/_diag -type f -mtime +7 -delete

# Clean apt cache
sudo apt-get clean

# Find large files
sudo du -hs /* | sort -rh | head -10
```

See: [`runner-degraded-resources.md`](./runner-degraded-resources.md) for resource management.

### Option 5: Full Runner Reinstall (Last Resort)

If all else fails:

```bash
# Stop service
sudo systemctl stop actions.runner.rmnanney-PAWS360.<runner-name>.service

# Remove runner
cd ~/actions-runner
./config.sh remove --token <REMOVAL_TOKEN>

# Download latest runner
wget https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64-<VERSION>.tar.gz

# Extract and configure
tar xzf actions-runner-linux-x64-<VERSION>.tar.gz
./config.sh --url https://github.com/rmnanney/PAWS360 \
  --token <REGISTRATION_TOKEN> \
  --name <runner-name>

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

---

## Validation

### Step 1: Verify Service Running

```bash
# Check systemd service status
sudo systemctl status actions.runner.rmnanney-PAWS360.<runner-name>.service

# Expected: "Active: active (running)"
```

### Step 2: Verify GitHub Registration

```bash
# Check runner status via GitHub API
gh api /repos/rmnanney/PAWS360/actions/runners \
  | jq '.runners[] | select(.name == "<runner-name>") | {name, status, busy}'

# Expected output:
# {
#   "name": "<runner-name>",
#   "status": "online",
#   "busy": false
# }
```

### Step 3: Verify Prometheus Metrics

```bash
# Query Prometheus for runner status
curl -sf "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_status{hostname="<runner-name>"}' \
  | jq -r '.data.result[0].value[1]'

# Expected: "1" (online)
```

### Step 4: Trigger Test Deployment

Run a test workflow to verify runner accepting jobs:

```bash
# Trigger test workflow via GitHub CLI
gh workflow run test-runner-health.yml \
  --ref main \
  --field runner=<runner-name>

# Monitor workflow run
gh run list --workflow=test-runner-health.yml --limit 1
```

### Step 5: Check Grafana Dashboard

Navigate to Grafana: `http://192.168.0.200:3000/d/runner-health`

Verify:
- ✓ Runner status shows "Online"
- ✓ Last check-in timestamp < 1 minute
- ✓ No active alerts for this runner
- ✓ Health score = 100%

---

## Post-Incident Actions

### 1. Document Root Cause

Create post-incident report:

```bash
# File: docs/post-mortems/runner-offline-YYYY-MM-DD.md
```

Include:
- Timestamp of outage
- Detection method
- Root cause (service crash, network issue, resource exhaustion, etc.)
- Remediation steps taken
- Time to resolution
- Lessons learned
- Preventive measures

### 2. Update Monitoring

If alert didn't fire or fired late:

```bash
# Review Prometheus alert rules
vim infrastructure/prometheus/alerts/runner-health.yaml

# Test alert configuration
promtool check rules infrastructure/prometheus/alerts/runner-health.yaml
```

### 3. Update Runbook

If new failure mode discovered, update this runbook:

```bash
git checkout -b docs/update-runner-offline-runbook
# Make changes to docs/runbooks/runner-offline-restore.md
git commit -m "docs: update runner offline runbook with new findings"
git push origin docs/update-runner-offline-runbook
```

### 4. Notify Stakeholders

Send notification to team:

```bash
# Post to Slack #sre-incidents
# Include: incident duration, root cause, resolution, action items
```

---

## Escalation Path

If unable to restore runner within 15 minutes:

1. **Notify Primary On-Call**: `@oncall-sre` in Slack `#sre-incidents`
2. **Escalate to Infrastructure Team**: `@infra-team`
3. **Emergency Failover**: Switch to secondary runner manually:
   ```yaml
   # Update .github/workflows/ci.yml
   runs-on: [self-hosted, Linux, X64, secondary]
   ```

---

## Automation Opportunities

### Auto-Restart on Failure

Enable automatic service restart:

```bash
sudo systemctl edit actions.runner.rmnanney-PAWS360.<runner-name>.service

# Add:
[Service]
Restart=always
RestartSec=30s
StartLimitInterval=300s
StartLimitBurst=5
```

### Proactive Monitoring

Deploy health check script:

```bash
# Add to cron: check runner health every 5 minutes
*/5 * * * * /opt/scripts/check-runner-health.sh || /opt/scripts/restart-runner.sh
```

---

## Related Documentation

- [Runner Degraded Resources](./runner-degraded-resources.md)
- [Network Unreachable Troubleshooting](./network-unreachable-troubleshooting.md)
- [Secrets Expired Rotation](./secrets-expired-rotation.md)
- [Log Query Templates](./runner-log-queries.md)
- [Failure Reproduction Guide](./failure-reproduction.md)

---

## Quick Reference Card

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| Service stopped | Manual stop, crash | `sudo systemctl restart actions.runner...` |
| "401 Unauthorized" | Token expired | Re-register runner with new token |
| "Connection refused" | Network issue | Check firewall, test connectivity |
| "Disk quota exceeded" | Disk full | `docker system prune -af`, clean logs |
| "Out of memory" | OOM kill | Restart runner, add swap, monitor memory |

---

**Last Updated**: 2025-01-11  
**JIRA**: INFRA-474  
**Owner**: SRE Team  
**Feedback**: Create issue or PR in repository
