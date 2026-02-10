# SRE Onboarding Guide: GitHub Runner Production Deployments

**Version**: 1.0
**Last Updated**: 2025-12-11
**Maintainer**: SRE Team
**JIRA Epic**: INFRA-472

## Welcome to PAWS360 Production Deployments 🚀

This guide will teach you everything you need to know about managing production deployments via GitHub Actions self-hosted runners for PAWS360.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [How Production Deployments Work](#how-production-deployments-work)
3. [Monitoring and Observability](#monitoring-and-observability)
4. [Diagnosing and Fixing Runner Issues](#diagnosing-and-fixing-runner-issues)
5. [Executing Rollback](#executing-rollback)
6. [Common Scenarios and Playbooks](#common-scenarios-and-playbooks)
7. [Safeguards and Safety Mechanisms](#safeguards-and-safety-mechanisms)
8. [Emergency Procedures](#emergency-procedures)
9. [Daily Operations](#daily-operations)

---

## Architecture Overview

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
│  Workflow: .github/workflows/ci.yml                         │
│  ├─ build-and-test                                          │
│  ├─ deploy-to-staging                                       │
│  └─ deploy-to-production ◄── YOU ARE HERE                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Self-Hosted Runners                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Primary: production-runner-01                         │  │
│  │ Host: Serotonin-paws360 (192.168.0.13)               │  │
│  │ Labels: [self-hosted, production, primary]           │  │
│  │ Health: Monitored every 30s                           │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Secondary: production-runner-02                       │  │
│  │ Host: dell-r640-01 (192.168.0.51)                    │  │
│  │ Labels: [self-hosted, production, secondary]         │  │
│  │ Failover: Automatic (< 30s switchover)               │  │
│  └───────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Ansible Playbooks                          │
│  Location: infrastructure/ansible/playbooks/                │
│  ├─ production-deploy-transactional.yml                     │
│  ├─ rollback-production-safe.yml                            │
│  ├─ validate-production-deploy.yml                          │
│  └─ comprehensive-health-checks.yml                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Production Environment                         │
│  ├─ Backend (Spring Boot)                                   │
│  ├─ Frontend (Next.js)                                      │
│  ├─ Database (PostgreSQL)                                   │
│  ├─ Cache (Redis)                                           │
│  └─ Nginx (Reverse Proxy)                                   │
└─────────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│          Monitoring & Alerting                              │
│  ├─ Prometheus: Metrics collection                          │
│  ├─ Grafana: Dashboards and visualization                   │
│  ├─ Loki: Log aggregation                                   │
│  └─ Alertmanager: Alert routing (Slack, PagerDuty)         │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose | Location | Access |
|-----------|---------|----------|--------|
| **Primary Runner** | Main deployment executor | 192.168.0.13 | `ssh ryan@192.168.0.13` |
| **Secondary Runner** | Failover backup | 192.168.0.51 | `ssh ryan@192.168.0.51` |
| **Prometheus** | Metrics collection | monitoring.paws360.local:9090 | Web UI |
| **Grafana** | Dashboards | monitoring.paws360.local:3000 | Web UI |
| **Production Apps** | Target deployment | production.paws360.local | Various ports |

---

## How Production Deployments Work

### Deployment Flow (Happy Path)

```
1. Developer pushes to main branch
   └─▶ GitHub Actions workflow triggered
   
2. Build and Test Phase
   ├─ Maven build
   ├─ Unit tests
   ├─ Integration tests
   └─ Artifact creation (JAR files)
   
3. Deploy to Production Job
   ├─ Concurrency Check (ensure no other deploy running)
   ├─ Runner Health Gate (validate primary runner available)
   │  ├─ Primary available? → Use primary runner
   │  └─ Primary unavailable? → Failover to secondary (<30s)
   │
   ├─ Preflight Validation
   │  ├─ Check secrets available
   │  ├─ Validate Ansible inventory
   │  └─ Verify production connectivity
   │
   ├─ Pre-Deployment State Capture
   │  ├─ Record current version
   │  ├─ Capture service status
   │  └─ Save configuration
   │
   ├─ Execute Transactional Deployment (Ansible block/rescue)
   │  ├─ Stop services gracefully
   │  ├─ Deploy new artifacts
   │  ├─ Update configuration
   │  ├─ Database migrations (if needed)
   │  └─ Start services
   │
   ├─ Post-Deployment Health Checks (20+ checks)
   │  ├─ Backend health endpoint (/actuator/health)
   │  ├─ Frontend homepage load
   │  ├─ Database connectivity
   │  ├─ Redis connectivity
   │  ├─ External integrations (SAML IdP)
   │  ├─ System resources (disk, memory, CPU)
   │  ├─ Nginx status
   │  └─ All systemd services
   │
   ├─ Smoke Tests (14 automated tests)
   │  ├─ Infrastructure tests (connectivity, DNS)
   │  ├─ Critical functionality (login, course enrollment)
   │  ├─ Data integrity (verify no data loss)
   │  └─ Error handling (404, 500 pages)
   │
   └─ Deployment Complete
      ├─ Update deployment metrics
      ├─ Send success notification
      └─ Record deployment in state file

IF ANY STEP FAILS:
   └─▶ Rescue Block Triggered
       ├─ Capture failure diagnostics
       ├─ Execute automatic rollback
       ├─ Restore pre-deployment state
       ├─ Run post-rollback health checks
       ├─ Create incident issue (GitHub + JIRA)
       └─ Send alert to oncall-sre
```

### Deployment Timing

| Phase | Duration | Notes |
|-------|----------|-------|
| Build + Test | 3-5 min | Parallel execution when possible |
| Preflight Validation | 30s | Fast-fail checks |
| State Capture | 10s | Lightweight snapshot |
| Deployment Execution | 2-4 min | Service stop → deploy → start |
| Health Checks | 1-2 min | 20+ checks with retry logic |
| Smoke Tests | 1-2 min | 14 automated tests |
| **Total (Success)** | **7-14 min** | Target: p95 ≤10 min |
| **Total (Rollback)** | **10-17 min** | +3 min for rollback |

---

## Monitoring and Observability

### Grafana Dashboards

#### 1. Runner Health Dashboard

**URL**: `http://monitoring.paws360.local/grafana/d/runner-health`

**Panels**:
- **Runner Status Timeline**: Shows online/degraded/offline status over time
- **Last Check-in Time**: When each runner last contacted GitHub
- **Runner Capacity**: Available capacity vs total capacity
- **Version Drift**: Detect if runner version out of date
- **Queue Depth**: Number of pending jobs waiting for runners
- **Job Success Rate**: Percentage of successful jobs per runner

**Key Metrics to Watch**:
- ✅ **Good**: Both runners online, last check-in <60s ago
- ⚠️ **Warning**: One runner offline, primary degraded
- 🚨 **Critical**: Both runners offline, queue depth >5

#### 2. Deployment Pipeline Dashboard

**URL**: `http://monitoring.paws360.local/grafana/d/deployment-pipeline`

**Panels**:
- **Deployment Success/Fail Rate**: Line graph by environment
- **Deployment Duration**: Histogram showing p50, p95, p99
- **Rollback Count by Reason**: Bar chart of rollback triggers
- **Health Check Failure Rate**: Which checks fail most often
- **Success Ratio Gauge**: Current success rate vs 95% target
- **Secrets Validation Status**: Are all secrets valid?

**New Panels (US3 Safeguards)**:
- **Rollback Count by Reason**: Breakdown of why rollbacks triggered
- **Health Check Failures**: Specific checks that failed
- **Success Ratio Gauge**: Visual indicator of reliability
- **Rollback Duration Heatmap**: Time to detect and rollback failures
- **Safeguard Status**: All safeguard mechanisms health
- **Rollback Incidents Table**: Recent rollback events with details

**Key Metrics to Watch**:
- ✅ **Good**: Success rate >95%, p95 duration <10min, no recent rollbacks
- ⚠️ **Warning**: Success rate 90-95%, p95 duration 10-15min, 1-2 rollbacks/day
- 🚨 **Critical**: Success rate <90%, p95 duration >15min, >3 rollbacks/day

### Prometheus Alerts

All alerts route to `oncall-sre` Slack channel and PagerDuty.

#### Critical Alerts (Page immediately)

| Alert | Condition | Action |
|-------|-----------|--------|
| `RunnerOffline` | Primary offline >5min OR both offline | Check runner health, restart service |
| `DeploymentRollbackTriggered` | Any automatic rollback | Investigate root cause, verify rollback success |
| `DeploymentHealthCheckFailed` | Post-deploy health checks fail | Check application logs, verify services running |
| `DeploymentPartialState` | Deployment left in partial state | Manual intervention required, check state file |

#### Warning Alerts (Investigate within 1 hour)

| Alert | Condition | Action |
|-------|-----------|--------|
| `RunnerDegraded` | High CPU/memory/disk usage | Check resource usage, consider cleanup |
| `DeploymentFailureRate` | >3 failures per hour | Review recent deployment logs |
| `DeploymentDurationExceeded` | p95 duration >10 minutes | Investigate performance bottleneck |
| `SecretValidationFailed` | Secret validation fails | Check secret expiration, rotate if needed |

#### Info Alerts (Review daily)

| Alert | Condition | Action |
|-------|-----------|--------|
| `RunnerVersionDrift` | Runner version ≠ latest | Schedule runner upgrade |
| `DeploymentSuccessRate` | Success rate <95% over 24h | Trend analysis, identify patterns |
| `HealthCheckRetries` | Health checks requiring retries | Investigate transient issues |

### Log Aggregation (Loki)

**Access**: `http://monitoring.paws360.local/grafana/explore`

**Common Queries**:

```logql
# All deployment logs
{job="github-runner"} |= "deploy-to-production"

# Failed deployments only
{job="github-runner"} |= "deploy-to-production" |= "FAILED"

# Rollback events
{job="github-runner"} |= "rollback" |~ "triggered|executed|completed"

# Runner offline events
{job="systemd"} |= "actions.runner" |= "stopped"

# Health check failures
{job="ansible"} |= "health_check" |= "FAILED"
```

**Saved Queries**: See [docs/runbooks/runner-log-queries.md](../runbooks/runner-log-queries.md)

---

## Diagnosing and Fixing Runner Issues

### Scenario 1: Runner Offline

**Symptoms**:
- Runner not accepting jobs
- Last check-in >5 minutes ago
- Alert: `RunnerOffline` firing

**Diagnosis**:

```bash
# 1. SSH to runner host
ssh ryan@192.168.0.13  # or 192.168.0.51 for secondary

# 2. Check runner service status
sudo systemctl status actions.runner.paws360-production-runner-01.service

# 3. Check recent logs
sudo journalctl -u actions.runner.* -n 100 --no-pager

# 4. Check network connectivity
ping github.com
curl -I https://api.github.com

# 5. Check disk space
df -h
```

**Common Causes**:
- Service crashed (OOM, segfault)
- Network connectivity lost
- Disk full (logs, artifacts)
- Runner token expired

**Fix**:

```bash
# Restart service
sudo systemctl restart actions.runner.paws360-production-runner-01.service

# Verify service started
sudo systemctl status actions.runner.paws360-production-runner-01.service

# Check runner registered in GitHub
# Visit: https://github.com/rmnanney/PAWS360/settings/actions/runners

# If token expired, re-register runner (requires admin PAT)
cd /opt/github-runner
./config.sh remove
./config.sh --url https://github.com/rmnanney/PAWS360 --token <NEW_TOKEN>
sudo ./svc.sh install
sudo ./svc.sh start
```

**Prevention**:
- Monitor disk usage (alert at 80%)
- Rotate logs (configure in runner settings)
- Set up automatic service restart on failure

**Detailed Runbook**: [docs/runbooks/runner-offline-restore.md](../runbooks/runner-offline-restore.md)

### Scenario 2: Runner Degraded (Resource Exhaustion)

**Symptoms**:
- High CPU/memory/disk usage
- Slow job execution
- Jobs timing out
- Alert: `RunnerDegraded` firing

**Diagnosis**:

```bash
# 1. SSH to runner host
ssh ryan@192.168.0.13

# 2. Check resource usage
top -bn1 | head -20
free -h
df -h

# 3. Identify resource hogs
ps aux --sort=-%mem | head -10  # Memory
ps aux --sort=-%cpu | head -10  # CPU

# 4. Check for stuck processes
ps aux | grep 'Runner.Worker'
```

**Common Causes**:
- Memory leak in runner process
- Disk full from artifacts/logs
- CPU saturation from parallel jobs
- Zombie processes from failed jobs

**Fix**:

```bash
# Clean up old artifacts (runner work directory)
cd /opt/github-runner/_work
du -sh * | sort -hr | head -10
# Manually remove old directories (or configure auto-cleanup)

# Clean up logs
sudo journalctl --vacuum-time=7d  # Keep last 7 days only

# Kill stuck processes (if any)
ps aux | grep 'Runner.Worker' | grep -v grep | awk '{print $2}' | xargs sudo kill -9

# Restart runner service
sudo systemctl restart actions.runner.paws360-production-runner-01.service
```

**Prevention**:
- Configure automatic artifact cleanup (retention policy)
- Set up log rotation (systemd journal limits)
- Monitor resource trends (alert on sustained high usage)
- Consider increasing runner host resources

**Detailed Runbook**: [docs/runbooks/runner-degraded-resources.md](../runbooks/runner-degraded-resources.md)

### Scenario 3: Deployment Fails with Auth Error

**Symptoms**:
- Deployment fails with "Authentication failed" or "Permission denied"
- Alert: `SecretValidationFailed` firing
- Logs show SSH or API auth errors

**Diagnosis**:

```bash
# 1. Check GitHub Secrets in workflow
# Visit: https://github.com/rmnanney/PAWS360/settings/secrets/actions

# 2. Test SSH connectivity from runner
ssh ryan@192.168.0.13
ssh -T production-host  # Should succeed without password

# 3. Check SSH key permissions
ls -l ~/.ssh/
# Should be 600 for private keys, 644 for public keys

# 4. Test Ansible connectivity
cd /opt/github-runner/paws360/infrastructure/ansible
ansible all -i inventories/production/hosts -m ping
```

**Common Causes**:
- Expired SSH keys
- Rotated passwords not updated in secrets
- SSH key permissions changed (too permissive)
- Known_hosts changed (host key mismatch)

**Fix**:

```bash
# Rotate SSH key (if expired)
ssh-keygen -t ed25519 -C "paws360-runner" -f ~/.ssh/paws360_runner_key

# Copy public key to production hosts
ssh-copy-id -i ~/.ssh/paws360_runner_key.pub ryan@production-host

# Update GitHub Secret
# Go to: https://github.com/rmnanney/PAWS360/settings/secrets/actions
# Update SSH_PRIVATE_KEY with contents of ~/.ssh/paws360_runner_key

# Fix known_hosts (if host key changed)
ssh-keyscan production-host >> ~/.ssh/known_hosts
```

**Prevention**:
- Set up quarterly secret rotation schedule
- Monitor secret expiration dates
- Use OIDC for cloud provider credentials (no secrets!)
- Document all secrets and their purpose

**Detailed Runbook**: [docs/runbooks/secrets-expired-rotation.md](../runbooks/secrets-expired-rotation.md)

### Scenario 4: Network Unreachable

**Symptoms**:
- Deployment fails with timeout or connection refused
- Ping/SSH to production hosts fails from runner
- Alert: `DeploymentFailureRate` increasing

**Diagnosis**:

```bash
# 1. SSH to runner host
ssh ryan@192.168.0.13

# 2. Test network connectivity
ping production-host
ping 8.8.8.8  # Internet connectivity
nslookup production.paws360.local  # DNS resolution

# 3. Test specific ports
nc -zv production-host 22    # SSH
nc -zv production-host 80    # HTTP
nc -zv production-host 443   # HTTPS

# 4. Check routing
traceroute production-host
ip route show
```

**Common Causes**:
- Network outage (ISP, datacenter)
- Firewall rules changed
- DNS resolution failure
- Production host down

**Fix**:

```bash
# If DNS issue, use IP address temporarily
# Update Ansible inventory to use IP instead of hostname

# If firewall issue, verify rules
sudo iptables -L -n -v

# If routing issue, check network configuration
ip addr show
ip route show

# If production host down, investigate separately
ssh production-host
# Check system status, restart services, etc.
```

**Prevention**:
- Monitor network connectivity (ping checks)
- Document all firewall rules
- Use multiple DNS servers
- Set up redundant network paths

**Detailed Runbook**: [docs/runbooks/network-unreachable-troubleshooting.md](../runbooks/network-unreachable-troubleshooting.md)

---

## Executing Rollback

### When to Rollback

**Automatic Rollback Triggers** (no manual intervention):
- Health checks fail after deployment
- Deployment interrupted mid-execution
- Ansible task fails in deployment block

**Manual Rollback Scenarios** (SRE decision):
- Production issues discovered post-deployment
- Performance degradation observed
- Customer-reported bugs in new version
- Security vulnerability discovered

### Automatic Rollback (Already Happened)

If you receive alert `DeploymentRollbackTriggered`, the system has already executed automatic rollback. Your job is to:

1. **Verify Rollback Success**:
   ```bash
   # Check Grafana dashboard
   # URL: http://monitoring.paws360.local/grafana/d/deployment-pipeline
   # Panel: "Rollback Count by Reason" - see why it triggered
   
   # Check production health
   curl https://production.paws360.local/actuator/health
   
   # Check production version (should be previous version)
   curl https://production.paws360.local/actuator/info | jq '.build.version'
   ```

2. **Review Rollback Incident**:
   - GitHub issue created automatically (label: `production-rollback`)
   - JIRA ticket linked (check INFRA epic)
   - Forensics captured (if enabled) in `/tmp/forensics-<timestamp>/`

3. **Investigate Root Cause**:
   - Review deployment logs in GitHub Actions
   - Check health check failure details
   - Examine forensics data (logs, metrics, state)

4. **Post-Mortem** (Required for all rollbacks):
   - Use template: `.specify/templates/deployment-rollback-postmortem.md`
   - Document timeline, root cause, remediation
   - Create action items (JIRA tickets)
   - Share with team

### Manual Rollback (You Execute)

**Step 1: Assess Situation**

```bash
# Check current production version
curl https://production.paws360.local/actuator/info | jq '.build.version'

# Check production health
curl https://production.paws360.local/actuator/health

# Review recent deployment logs
# GitHub Actions: https://github.com/rmnanney/PAWS360/actions/workflows/ci.yml
```

**Step 2: Coordinate with Team**

```bash
# Notify team in Slack #oncall-sre
"🚨 Initiating manual rollback of production deployment
Version: <current-version> → <target-version>
Reason: <brief-description>
ETA: 5-10 minutes"
```

**Step 3: Execute Rollback Playbook**

```bash
# 1. SSH to primary runner
ssh ryan@192.168.0.13

# 2. Navigate to Ansible directory
cd /opt/github-runner/paws360/infrastructure/ansible

# 3. (Optional) Dry-run to verify
ansible-playbook -i inventories/production/hosts \
  playbooks/rollback-production-safe.yml \
  --check \
  --diff

# 4. Execute rollback with forensics
ansible-playbook -i inventories/production/hosts \
  playbooks/rollback-production-safe.yml \
  -e "rollback_version=<target-version>" \
  -e "forensics_enabled=true"

# Example:
ansible-playbook -i inventories/production/hosts \
  playbooks/rollback-production-safe.yml \
  -e "rollback_version=1.2.3" \
  -e "forensics_enabled=true"
```

**Step 4: Verify Rollback**

The playbook automatically runs post-rollback health checks. Verify manually:

```bash
# Check version rolled back
curl https://production.paws360.local/actuator/info | jq '.build.version'
# Should show target version

# Run smoke tests
cd /opt/github-runner/paws360
./tests/smoke/post-deployment-smoke-tests.sh --environment=production

# Check all services healthy
curl https://production.paws360.local/actuator/health | jq '.status'
# Should show "UP"

# Monitor metrics in Grafana
# URL: http://monitoring.paws360.local/grafana/d/deployment-pipeline
```

**Step 5: Notify Team**

```bash
# Update Slack #oncall-sre
"✅ Rollback completed successfully
Version: <current> → <target>
Duration: <X> minutes
Health: All checks passing
Next: Post-mortem required"
```

**Step 6: Post-Mortem** (Required)

- Create post-mortem from template
- Document timeline and root cause
- Create action items (JIRA tickets)
- Schedule retrospective with team
- Update runbooks if new scenario discovered

### Rollback Troubleshooting

**Problem: Rollback Fails**

```bash
# Check rollback logs
tail -f /tmp/rollback-<timestamp>.log

# Common issues:
# 1. Target version artifact not found
#    → Check artifact storage, may need manual download

# 2. Health checks fail post-rollback
#    → Check application logs, database state

# 3. Ansible task fails
#    → Check Ansible logs, may need manual intervention

# If rollback fails critically:
# 1. Create critical incident issue
# 2. Page on-call SRE lead
# 3. Consider manual emergency fix
# 4. Document all steps taken
```

---

## Common Scenarios and Playbooks

### Scenario: Primary Runner Failed, Need to Force Secondary

```bash
# 1. Disable primary runner in GitHub (prevents auto-selection)
# Visit: https://github.com/rmnanney/PAWS360/settings/actions/runners
# Click production-runner-01 → Disable

# 2. Trigger deployment (will use secondary)
gh workflow run ci.yml --ref main

# 3. Monitor deployment on secondary
# Dashboard: http://monitoring.paws360.local/grafana/d/deployment-pipeline

# 4. After primary fixed, re-enable
# GitHub → Runners → production-runner-01 → Enable
```

### Scenario: Need to Deploy Hotfix Immediately

```bash
# 1. Create hotfix branch from main
git checkout main
git pull
git checkout -b hotfix/critical-fix
# Make your fix
git commit -m "INFRA-XXX: Critical hotfix for [issue]"
git push origin hotfix/critical-fix

# 2. Merge to main (or create PR and merge immediately)
git checkout main
git merge hotfix/critical-fix
git push origin main

# 3. Deployment automatically triggers on push to main
# Or trigger manually:
gh workflow run ci.yml --ref main

# 4. Monitor closely in Grafana
# Watch for alerts, health check failures

# 5. If deployment fails, automatic rollback kicks in
# Review logs and fix issue before retrying
```

### Scenario: Need to Test Deployment in Dry-Run Mode

```bash
# 1. SSH to runner
ssh ryan@192.168.0.13

# 2. Navigate to repo
cd /opt/github-runner/paws360

# 3. Run deployment playbook in check mode
cd infrastructure/ansible
ansible-playbook -i inventories/production/hosts \
  playbooks/production-deploy-transactional.yml \
  --check \
  --diff \
  -e "artifact_version=<version-to-deploy>"

# 4. Review diff output (what would change)
# No actual changes made to production
```

### Scenario: Health Check Keeps Failing on Specific Component

```bash
# 1. Identify which health check failing
# Check Grafana: deployment-pipeline dashboard → "Health Check Failures"

# 2. SSH to runner and run health checks manually
ssh ryan@192.168.0.13
cd /opt/github-runner/paws360/infrastructure/ansible

# Run specific health check category
ansible-playbook -i inventories/production/hosts \
  roles/deployment/tasks/comprehensive-health-checks.yml \
  --tags "backend_health"  # or frontend_health, database_health, etc.

# 3. Debug specific check
# Example: Backend health endpoint
curl -v https://production.paws360.local/actuator/health

# 4. If transient issue, adjust retry count
# Edit: roles/deployment/tasks/comprehensive-health-checks.yml
# Increase retries: for that specific check

# 5. If persistent issue, make check non-blocking
# Add to health check task: ignore_errors: true
# Create JIRA ticket to fix underlying issue
```

---

## Safeguards and Safety Mechanisms

PAWS360 production deployments include 7 layers of safeguards to prevent failures and partial state:

### 1. Concurrency Control

**Mechanism**: GitHub Actions concurrency group
**Purpose**: Prevent concurrent deployments (avoid race conditions)
**Location**: `.github/workflows/ci.yml`

```yaml
concurrency:
  group: production-deployment
  cancel-in-progress: false  # Queue, don't cancel
```

**Effect**: If deployment triggered while another running, queues and waits

### 2. Runner Health Gate

**Mechanism**: Preflight runner health check
**Purpose**: Ensure runner available before starting deployment
**Location**: Workflow step "Runner Health Check"

**Checks**:
- Runner online in GitHub?
- Last check-in <5 minutes ago?
- Sufficient disk space?
- Network connectivity to production?

**Effect**: Fail-fast if runner unhealthy, automatic failover to secondary

### 3. Pre-Deployment State Capture

**Mechanism**: Capture current state before deployment
**Purpose**: Enable reliable rollback to known-good state
**Location**: `scripts/deployment/capture-production-state.sh`

**Captures**:
- Current application version
- Service status (systemd units)
- Configuration files
- Database schema version
- Metadata (timestamp, deployer, commit)

**Storage**: `/tmp/production-state-backup-<timestamp>.json` + GitHub artifact

### 4. Transaction Safety (Ansible block/rescue)

**Mechanism**: Ansible block/rescue/always pattern
**Purpose**: Atomic deployment (all-or-nothing)
**Location**: `playbooks/production-deploy-transactional.yml`

```yaml
- block:
    - name: Stop services
    - name: Deploy artifacts
    - name: Update configuration
    - name: Start services
    - name: Run health checks
  rescue:
    - name: Rollback automatically
  always:
    - name: Clean up locks/temp files
```

**Effect**: If any step fails, rescue block triggers automatic rollback

### 5. Comprehensive Health Checks

**Mechanism**: 20+ post-deployment health checks
**Purpose**: Verify deployment success before declaring complete
**Location**: `roles/deployment/tasks/comprehensive-health-checks.yml`

**Check Categories** (8):
1. Backend API (health endpoint, version, connections)
2. Frontend (homepage, login, critical pages)
3. Database (connectivity, schema version, tables)
4. Redis (connectivity, memory, cache)
5. External Integrations (SAML IdP, APIs)
6. System Resources (disk, memory, CPU)
7. Nginx (service status, response)
8. Systemd Services (all units)

**Retry Logic**: 3 attempts for critical checks, 2 for pages, 5s delay

**Effect**: If any check fails, rescue block triggers rollback

### 6. Enhanced Rollback Safety

**Mechanism**: Safe rollback playbook with validation
**Purpose**: Ensure rollback doesn't make things worse
**Location**: `playbooks/rollback-production-safe.yml`

**Phases**:
1. **Pre-Rollback**: Validate target version artifact exists, permissions OK
2. **Forensics** (optional): Capture failed state for debugging
3. **Rollback**: Transactional rollback to previous version
4. **Post-Rollback**: Health checks to verify rollback success

**Forensics Captured**:
- Failed state backup
- Service logs (last 1000 lines)
- System metrics (CPU, memory, disk)
- Metadata (timestamp, reason, version)

**Effect**: Rollback as safe as forward deployment, preserves evidence

### 7. Incident Tracking

**Mechanism**: Automatic incident creation on failure
**Purpose**: Ensure all failures documented and tracked
**Location**: `scripts/ci/notify-rollback.sh`

**Actions on Rollback**:
- Create GitHub issue (label: `production-rollback`)
- Link to JIRA deployment ticket
- Send Slack notification (#oncall-sre)
- Send PagerDuty alert (if critical)
- Emit Prometheus metric (`deployment_rollback_total`)

**Effect**: No silent failures, all rollbacks require post-mortem

---

## Emergency Procedures

### 🚨 Critical: Both Runners Down

**Symptoms**: No runners available, deployments queued indefinitely

**Immediate Actions**:

```bash
# 1. Alert team immediately
"🚨 CRITICAL: Both production runners offline
Primary: <status>
Secondary: <status>
Impact: Deployments blocked
ETA to resolve: <estimate>"

# 2. Investigate both runners in parallel
# Primary:
ssh ryan@192.168.0.13
sudo systemctl status actions.runner.*
sudo journalctl -u actions.runner.* -n 100

# Secondary:
ssh ryan@192.168.0.51
sudo systemctl status actions.runner.*
sudo journalctl -u actions.runner.* -n 100

# 3. Attempt restart both runners
# Primary:
ssh ryan@192.168.0.13
sudo systemctl restart actions.runner.paws360-production-runner-01.service

# Secondary:
ssh ryan@192.168.0.51
sudo systemctl restart actions.runner.paws360-production-runner-02.service

# 4. If restart fails, check common issues:
# - Disk full: df -h
# - Network down: ping github.com
# - Service crashed: journalctl -xe

# 5. If runners can't be restored quickly:
# - Consider deploying manually via Ansible from local machine
# - Document all manual steps taken
# - Create critical incident ticket
```

**Prevention**: Monitor runner health, set up alerting for both offline

### 🚨 Critical: Production Down After Deployment

**Symptoms**: Production services not responding, health checks all failing

**Immediate Actions**:

```bash
# 1. Alert team
"🚨 CRITICAL: Production down after deployment
Version: <deployed-version>
Status: <service-status>
Action: Immediate rollback
ETA: 5-10 minutes"

# 2. Check if automatic rollback already triggered
# Grafana: deployment-pipeline dashboard → Recent rollbacks

# 3. If no automatic rollback, execute manual rollback
ssh ryan@192.168.0.13
cd /opt/github-runner/paws360/infrastructure/ansible
ansible-playbook -i inventories/production/hosts \
  playbooks/rollback-production-safe.yml \
  -e "rollback_version=<last-known-good>"

# 4. Monitor rollback progress
# Grafana: deployment-pipeline dashboard → Real-time metrics

# 5. Verify production restored
curl https://production.paws360.local/actuator/health
./tests/smoke/post-deployment-smoke-tests.sh --environment=production

# 6. Notify team
"✅ Production restored via rollback
Version: <rolled-back-to>
Status: All services healthy
Next: Incident post-mortem required"
```

**Prevention**: Always test in staging first, comprehensive health checks

### 🚨 Critical: Rollback Failed

**Symptoms**: Rollback playbook failed, production still unhealthy

**Immediate Actions**:

```bash
# 1. Page on-call SRE lead immediately
# PagerDuty or direct phone call

# 2. Do NOT retry automatic rollback
# May make situation worse

# 3. Manual investigation required
ssh ryan@production-host

# Check what's actually running
systemctl status paws360-*
ps aux | grep java

# Check logs for errors
sudo journalctl -u paws360-* -n 500

# Check disk space
df -h

# Check database connectivity
psql -h localhost -U paws360 -d paws360_prod -c "SELECT 1;"

# 4. Determine manual fix required
# Options:
# a) Manual rollback (copy artifacts, restart services)
# b) Emergency patch (fix critical issue, redeploy)
# c) Restore from backup (last resort)

# 5. Document everything
# Create detailed timeline of actions taken
# Will be needed for post-mortem

# 6. After production restored:
# - Full incident review
# - Update runbooks with new scenario
# - Add safeguards to prevent recurrence
```

**Prevention**: Test rollback playbook regularly, maintain backups

---

## Daily Operations

### Morning Checks (5 minutes)

```bash
# 1. Check runner health
# Grafana: runner-health dashboard
# ✅ Both runners online, last check-in <60s

# 2. Check deployment metrics (last 24h)
# Grafana: deployment-pipeline dashboard
# ✅ Success rate >95%
# ✅ P95 duration <10min
# ✅ No rollbacks

# 3. Check alerts
# Grafana: Alerting → Alert rules
# ✅ No firing alerts
# ⚠️ Any warnings? Investigate and resolve

# 4. Check pending deployments
# GitHub Actions: https://github.com/rmnanney/PAWS360/actions
# ✅ No queued or failed workflows

# 5. Review overnight incidents (if any)
# GitHub Issues: label:production-rollback
# 📋 Any post-mortems pending?
```

### Weekly Tasks

```bash
# 1. Review deployment trends (7 days)
# Grafana: deployment-pipeline dashboard
# - Success rate trending up or down?
# - Duration increasing?
# - Common failure patterns?

# 2. Runner maintenance
# Check runner disk usage (clean if >80%)
ssh ryan@192.168.0.13
df -h
du -sh /opt/github-runner/_work/* | sort -hr | head -10
# Clean old work directories if needed

# 3. Review and close old incidents
# GitHub Issues: label:production-rollback
# Ensure all have post-mortems
# Close resolved issues

# 4. Update documentation
# Any new scenarios encountered?
# Update runbooks with lessons learned

# 5. Test runner failover
# Disable primary runner, trigger test deployment
# Verify secondary picks up job
# Re-enable primary
```

### Monthly Tasks

```bash
# 1. Runner version updates
# Check GitHub Actions runner releases
# https://github.com/actions/runner/releases
# Update runners to latest version

# 2. Secret rotation
# Rotate all long-lived credentials
# SSH keys, service account passwords, API tokens
# See: docs/runbooks/secrets-expired-rotation.md

# 3. Capacity planning
# Review runner utilization trends
# Do we need more runners?
# Are runners adequately sized?

# 4. Disaster recovery drill
# Test full rollback procedure
# Verify backups restorable
# Document time to recover

# 5. Retrospective
# Review month's incidents
# Identify systemic issues
# Create improvement tasks (JIRA tickets)
```

---

## Additional Resources

### Documentation

- **[Production Deployment Failures Runbook](../runbooks/production-deployment-failures.md)** - Common failure modes and fixes
- **[Runner Offline Restore Runbook](../runbooks/runner-offline-restore.md)** - Bring runner back online
- **[Runner Degraded Resources Runbook](../runbooks/runner-degraded-resources.md)** - Fix resource exhaustion
- **[Secrets Expired Rotation Runbook](../runbooks/secrets-expired-rotation.md)** - Rotate credentials safely
- **[Network Unreachable Troubleshooting](../runbooks/network-unreachable-troubleshooting.md)** - Connectivity diagnostics
- **[Deployment Safeguards Architecture](../architecture/deployment-safeguards.md)** - Complete technical documentation
- **[GitHub Environment Protection](../deployment/github-environment-protection.md)** - Concurrency and approval controls
- **[Deployment Idempotency Guide](../development/deployment-idempotency-guide.md)** - Writing safe Ansible tasks

### Context Files

- **[GitHub Runners Context](../../contexts/infrastructure/github-runners.md)** - Complete runner configuration
- **[Production Deployment Pipeline Context](../../contexts/infrastructure/production-deployment-pipeline.md)** - Workflow details
- **[Monitoring Stack Context](../../contexts/infrastructure/monitoring-stack.md)** - Observability configuration

### JIRA Stories

- **[INFRA-472](https://paws360.atlassian.net/browse/INFRA-472)** - Epic: Stabilize Production Deployments
- **[INFRA-473](https://paws360.atlassian.net/browse/INFRA-473)** - US1: Restore Reliable Production Deploys
- **[INFRA-474](https://paws360.atlassian.net/browse/INFRA-474)** - US2: Diagnose Runner Issues Quickly
- **[INFRA-475](https://paws360.atlassian.net/browse/INFRA-475)** - US3: Protect Production During Deploy Anomalies

### Templates

- **[Deployment Rollback Post-Mortem Template](../../.specify/templates/deployment-rollback-postmortem.md)** - Required for all rollbacks

### Getting Help

**Slack Channels**:
- `#oncall-sre` - On-call SRE team (emergencies)
- `#paws360-deployments` - Deployment discussions
- `#infra-runners` - Runner-specific issues

**On-Call Rotation**:
- PagerDuty: https://paws360.pagerduty.com
- Escalation: SRE Lead → Engineering Manager → CTO

**Office Hours**:
- SRE Team: Monday/Wednesday 2-3pm (Zoom link in Slack)

---

## Conclusion

You now have a comprehensive understanding of how production deployments work in PAWS360 via GitHub Actions runners. Key takeaways:

✅ **Architecture**: Primary runner with automatic failover to secondary  
✅ **Monitoring**: Real-time Grafana dashboards and Prometheus alerts  
✅ **Safeguards**: 7 layers of protection prevent failures and partial state  
✅ **Diagnostics**: Comprehensive runbooks for common issues  
✅ **Rollback**: Automatic and manual rollback procedures  
✅ **Ops**: Daily/weekly/monthly tasks to maintain system health  

**Next Steps**:
1. Bookmark this guide and related runbooks
2. Join `#oncall-sre` and `#paws360-deployments` Slack channels
3. Shadow experienced SRE during next production deployment
4. Practice runbooks in staging environment
5. Ask questions! We're here to help 🚀

**Welcome to the team!** 🎉

---

*Last Updated: 2025-12-11*  
*Maintained by: SRE Team*  
*Feedback: #oncall-sre Slack channel*
