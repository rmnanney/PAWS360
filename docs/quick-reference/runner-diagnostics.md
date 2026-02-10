---
title: "Runner Diagnostics Quick Reference"
version: "1.0"
last_updated: "2025-01-11"
owner: "SRE Team"
jira_tickets: ["INFRA-474"]
print_friendly: true
page_size: "A4"
---

# GitHub Runner Diagnostics Quick Reference

**Emergency Contact**: `@oncall-sre` in Slack `#sre-incidents`  
**Monitoring Dashboard**: http://192.168.0.200:3000/d/runner-health  
**Updated**: 2025-01-11 | **JIRA**: INFRA-474

---

## 🚨 Common Failure Modes

| Symptom | Likely Cause | Quick Diagnostic | Quick Fix | Runbook |
|---------|--------------|------------------|-----------|---------|
| **Runner Offline** | Service stopped, network issue | `systemctl status actions.runner.*` | `systemctl restart actions.runner.*` | [runner-offline-restore.md](../runbooks/runner-offline-restore.md) |
| **High CPU/Memory** | Resource exhaustion | `top -bn1 \| head -20` | `docker system prune -af` | [runner-degraded-resources.md](../runbooks/runner-degraded-resources.md) |
| **Auth Failure** | Token expired | `gh api user` | Rotate token, update secret | [secrets-expired-rotation.md](../runbooks/secrets-expired-rotation.md) |
| **Network Timeout** | Firewall, DNS, routing | `ping 192.168.0.1 && curl https://api.github.com/zen` | Check firewall rules | [network-unreachable-troubleshooting.md](../runbooks/network-unreachable-troubleshooting.md) |
| **Disk Full** | Docker images, logs | `df -h /` | `docker system prune -af && find ~/actions-runner/_diag -mtime +7 -delete` | [runner-degraded-resources.md](../runbooks/runner-degraded-resources.md) |
| **Slow Deployments** | High load, resource contention | `uptime && free -h` | Reduce concurrent jobs | [runner-degraded-resources.md](../runbooks/runner-degraded-resources.md) |

---

## 📋 Essential Diagnostic Commands

### Quick Health Check
```bash
# One-liner health summary
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% | Memory: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100)}') | Disk: $(df -h / | awk 'NR==2 {print $5}')"
```

### Runner Status
```bash
# Check runner service
sudo systemctl status actions.runner.rmnanney-PAWS360.<runner-name>.service

# Check runner logs (last 50 lines)
sudo journalctl -u actions.runner.rmnanney-PAWS360.<runner-name>.service -n 50 --no-pager

# Check GitHub registration
gh api /repos/rmnanney/PAWS360/actions/runners | jq '.runners[] | {name, status, busy}'
```

### Resource Usage
```bash
# CPU usage
top -bn1 | head -10

# Memory usage
free -h

# Disk usage
df -h

# Top processes by CPU
ps aux --sort=-%cpu | head -10

# Top processes by memory
ps aux --sort=-%mem | head -10
```

### Network Connectivity
```bash
# Test gateway
ping -c 3 192.168.0.1

# Test DNS
nslookup github.com

# Test GitHub API
curl -sf https://api.github.com/zen && echo "OK" || echo "FAILED"

# Test SSH to GitHub
ssh -T git@github.com 2>&1 | grep "successfully authenticated"

# Test production hosts
ssh -o ConnectTimeout=5 admin@<production_host> "echo OK"
```

### Prometheus Metrics
```bash
# Check runner status (1=online, 0=offline)
curl -sf "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_status{hostname="<runner>"}' | jq -r '.data.result[0].value[1]'

# Check runner CPU usage
curl -sf "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_cpu_usage_percent{hostname="<runner>"}' | jq -r '.data.result[0].value[1]'
```

### Loki Logs
```bash
# Recent runner errors
logcli query --addr=http://192.168.0.200:3100 \
  '{job="github-runner",hostname="<runner>"} | level="ERROR"' --limit=20

# Deployment failures
logcli query --addr=http://192.168.0.200:3100 \
  '{job="github-runner"} | regexp "failed|error" | line_format "{{.message}}"' --limit=20
```

---

## 🔧 Common Fixes

### Restart Runner
```bash
sudo systemctl restart actions.runner.rmnanney-PAWS360.<runner-name>.service
sudo systemctl status actions.runner.rmnanney-PAWS360.<runner-name>.service
```

### Free Disk Space
```bash
# Remove Docker resources
docker system prune -a -f --volumes

# Clean runner logs (>7 days old)
find ~/actions-runner/_diag -type f -mtime +7 -delete

# Clean package caches
sudo apt-get clean && npm cache clean --force
```

### Fix Network
```bash
# Restart networking
sudo systemctl restart networking

# Flush DNS cache
sudo systemd-resolve --flush-caches

# Test connectivity
ping -c 3 8.8.8.8 && curl -I https://github.com
```

### Rotate SSH Key
```bash
# Generate new key
ssh-keygen -t ed25519 -C "github-actions-$(date +%Y%m%d)" -f ~/.ssh/github-actions-new

# Deploy to production
ssh-copy-id -i ~/.ssh/github-actions-new.pub admin@<production_host>

# Update GitHub Secret
gh secret set PRODUCTION_SSH_PRIVATE_KEY --body "$(cat ~/.ssh/github-actions-new)"
```

---

## 📊 Monitoring Access

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://192.168.0.200:3000 | admin / (from vault) |
| **Prometheus** | http://192.168.0.200:9090 | No auth |
| **Loki** | http://192.168.0.200:3100 | No auth |

### Key Dashboards
- **Runner Health**: http://192.168.0.200:3000/d/runner-health
- **Deployment Pipeline**: http://192.168.0.200:3000/d/deployment-pipeline
- **SRE Overview**: http://192.168.0.200:3000/d/sre-overview

---

## 🔍 Investigation Checklist

When troubleshooting runner issues, check:

- [ ] Runner service status: `systemctl status actions.runner.*`
- [ ] Recent system logs: `journalctl -xe | grep -i runner`
- [ ] Resource usage: `top -bn1 && free -h && df -h`
- [ ] Network connectivity: `ping 192.168.0.1 && curl https://api.github.com/zen`
- [ ] GitHub runner status: `gh api /repos/rmnanney/PAWS360/actions/runners`
- [ ] Prometheus metrics: Check Grafana runner-health dashboard
- [ ] Recent deployments: `gh run list --limit 10`
- [ ] Active alerts: `curl -sf http://192.168.0.200:9090/api/v1/alerts`
- [ ] Recent errors in Loki: Use logcli or Grafana Explore
- [ ] Firewall rules: `sudo iptables -L -n | grep -E "(443|22|53)"`

---

## 📞 Escalation Path

### Level 1: Self-Service (0-15 min)
- Check this quick reference guide
- Review relevant runbook
- Attempt documented quick fixes
- Check monitoring dashboards

### Level 2: On-Call SRE (15-30 min)
- **Slack**: `@oncall-sre` in `#sre-incidents`
- **Email**: sre@example.com
- Provide:
  - Runner hostname
  - Failure symptoms
  - Steps already taken
  - Link to failed workflow run

### Level 3: Infrastructure Team (30+ min)
- **Slack**: `@infra-team` in `#infrastructure`
- **Email**: infrastructure@example.com
- Escalate if:
  - Both runners offline
  - Network-wide issue suspected
  - Resource provisioning needed

### Level 4: Emergency Failover
If unable to restore within 1 hour:
```bash
# Manually edit workflow to use secondary runner
vim .github/workflows/ci.yml
# Change: runs-on: [self-hosted, production, secondary]
git commit -m "EMERGENCY: Failover to secondary runner"
git push origin main
```

---

## 🧪 Test Deployment

Trigger test workflow to verify runner health:

```bash
# Run test deployment
gh workflow run test-runner-health.yml --ref main

# Watch progress
gh run watch

# Expected: Success within 5 minutes
```

---

## 📚 Full Documentation

| Document | Purpose | Location |
|----------|---------|----------|
| **Runner Offline Restore** | Service stopped, network issues | `docs/runbooks/runner-offline-restore.md` |
| **Resource Exhaustion** | High CPU/memory/disk | `docs/runbooks/runner-degraded-resources.md` |
| **Secrets Rotation** | Expired tokens, auth failures | `docs/runbooks/secrets-expired-rotation.md` |
| **Network Troubleshooting** | Connectivity issues | `docs/runbooks/network-unreachable-troubleshooting.md` |
| **Log Query Templates** | Loki/Prometheus queries | `docs/runbooks/runner-log-queries.md` |
| **Failure Reproduction** | Test failure scenarios | `docs/runbooks/failure-reproduction.md` |

---

## 🔑 Key Configuration

### Runners
- **Primary**: Serotonin-paws360 (192.168.0.13)
- **Secondary**: dell-r640-01-runner (192.168.0.51)

### Secrets (GitHub Repository)
- `PRODUCTION_SSH_PRIVATE_KEY` - Production deploy SSH key
- `PRODUCTION_SSH_USER` - Production SSH username
- `DOCKER_HUB_TOKEN` - Docker registry access
- `SLACK_WEBHOOK` - Deployment notifications

### Monitoring Stack
- **Prometheus**: 192.168.0.200:9090
- **Grafana**: 192.168.0.200:3000
- **Loki**: 192.168.0.200:3100
- **Pushgateway**: 192.168.0.200:9091

### Critical Thresholds
- **CPU**: Alert at >80% for 10 min
- **Memory**: Alert at >85% for 10 min
- **Disk**: Alert at >85% (critical), >75% (warning)
- **Runner Offline**: Alert at >5 min (primary), >10 min (secondary)
- **Deployment Failures**: Alert at >3 failures/hour

---

## 💡 Quick Tips

1. **Always check Grafana first** - Visual overview faster than CLI
2. **Use `gh run watch`** - Real-time workflow monitoring
3. **Check both runners** - Issue may affect multiple hosts
4. **Test in stages** - Network → Auth → Service → Application
5. **Document findings** - Update runbooks with new failure modes
6. **Automate common fixes** - Create scripts for frequent issues
7. **Set calendar reminders** - Secret rotation every 90 days
8. **Monitor trends** - Proactive vs reactive fixes

---

## 📝 Post-Incident

After resolving an incident:

1. **Document root cause** in `docs/post-mortems/runner-YYYY-MM-DD.md`
2. **Update runbooks** with new findings or failure modes
3. **Create JIRA ticket** for preventive measures
4. **Notify team** in `#sre-incidents` with summary
5. **Schedule retrospective** if outage >1 hour
6. **Update monitoring** if alerts didn't fire or fired late

---

**Print this page for quick desk reference**  
**QR Code to Runbooks**: [Generate QR code linking to runbooks directory]

---

*Last Updated: 2025-01-11*  
*JIRA: INFRA-474*  
*Owner: SRE Team*  
*Feedback: Create issue or PR in repository*
