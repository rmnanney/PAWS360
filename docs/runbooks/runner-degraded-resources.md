---
title: "Runner Degraded - Resource Exhaustion"
severity: "High"
category: "Runner Performance"
last_updated: "2025-01-11"
owner: "SRE Team"
jira_tickets: ["INFRA-474"]
related_runbooks:
  - "runner-offline-restore.md"
  - "performance-degradation.md"
estimated_time: "15-20 minutes"
---

# Runner Degraded - Resource Exhaustion

## Overview

Procedures to diagnose and remediate GitHub Actions runner performance degradation due to resource exhaustion (CPU, memory, disk).

**Severity**: High  
**Impact**: Slow deployments, job failures, potential runner crash  
**Response Time**: < 10 minutes

---

## Symptoms

- ⚠ High CPU usage (>80%) sustained for >5 minutes
- ⚠ High memory usage (>85%) sustained for >5 minutes
- ⚠ Low disk space (<15% free)
- ⚠ Deployment jobs taking 2x+ normal duration
- ⚠ Prometheus alert: `RunnerResourceExhaustion` firing
- ⚠ Slow SSH response or command execution on runner host

---

## Diagnosis

### Quick Resource Check

SSH to runner and run:

```bash
# One-line resource summary
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% | Memory: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100)}') | Disk: $(df -h / | awk 'NR==2 {print $5}')"
```

### Detailed CPU Diagnosis

```bash
# Check current CPU usage
top -bn1 | head -20

# Identify CPU-heavy processes
ps aux --sort=-%cpu | head -15

# Check load average (should be < # of cores)
uptime

# Monitor CPU over time (Ctrl+C to exit)
mpstat 2 10
```

**Common CPU consumers**:
- Docker builds (buildkit)
- Maven/Gradle compilation
- npm install
- Test suites (Jest, JUnit)

### Detailed Memory Diagnosis

```bash
# Check memory usage
free -h

# Identify memory-heavy processes
ps aux --sort=-%mem | head -15

# Check for OOM kills in system logs
sudo journalctl -k | grep -i "out of memory" | tail -20

# Check swap usage
swapon --show

# Monitor memory over time
watch -n 2 free -h
```

**Common memory consumers**:
- Java applications (Maven, Spring Boot)
- Docker containers
- Node.js applications
- In-memory databases (Redis, H2)

### Detailed Disk Diagnosis

```bash
# Check disk usage by filesystem
df -h

# Find large directories
sudo du -hsx /* | sort -rh | head -10

# Check runner-specific disk usage
du -hs ~/actions-runner/_diag  # Runner logs
du -hs ~/.docker               # Docker data
du -hs /var/lib/docker         # Docker system data

# Find large files
find ~ -type f -size +100M -exec ls -lh {} \; | awk '{print $9 ": " $5}'
```

**Common disk consumers**:
- Docker images and volumes
- Runner logs (`_diag/`)
- Build artifacts
- Package manager caches (npm, Maven)

---

## Remediation

### CPU Exhaustion

**Option 1: Identify and Kill Resource-Heavy Process**

```bash
# Identify process
ps aux --sort=-%cpu | head -5

# Kill specific process (if safe)
kill -9 <PID>

# For Docker containers
docker ps
docker stop <container_id>
```

**Option 2: Reduce Concurrency**

```bash
# Limit concurrent jobs in runner configuration
cd ~/actions-runner
./config.sh --maxjobs 1  # Reduce from default (2-4)

# Restart runner service
sudo systemctl restart actions.runner.rmnanney-PAWS360.<runner-name>.service
```

**Option 3: Nice Process Priority**

```bash
# Reduce priority of CPU-heavy process
renice +10 <PID>

# For runner service (permanent)
sudo systemctl edit actions.runner.rmnanney-PAWS360.<runner-name>.service

# Add:
[Service]
CPUQuota=80%
Nice=5
```

### Memory Exhaustion

**Option 1: Free Memory**

```bash
# Drop caches (safe operation)
sudo sync && sudo sysctl -w vm.drop_caches=3

# Restart memory-heavy services
sudo systemctl restart docker
```

**Option 2: Enable/Increase Swap**

```bash
# Check current swap
swapon --show

# Create swap file (if none exists)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Adjust swappiness (how aggressively to use swap)
sudo sysctl vm.swappiness=10  # Lower = prefer RAM
```

**Option 3: Limit Container Memory**

```bash
# Set memory limits in docker-compose.yml
services:
  app:
    mem_limit: 2g
    memswap_limit: 2g

# Or via docker run
docker run -m 2g ...
```

### Disk Exhaustion

**Option 1: Clean Docker Resources**

```bash
# Remove all unused Docker resources (AGGRESSIVE)
docker system prune -a -f --volumes

# More selective cleanup:
docker image prune -f      # Remove unused images
docker container prune -f  # Remove stopped containers
docker volume prune -f     # Remove unused volumes
docker network prune -f    # Remove unused networks

# Check reclaimed space
df -h /var/lib/docker
```

**Option 2: Clean Runner Logs**

```bash
# Delete logs older than 7 days
find ~/actions-runner/_diag -type f -mtime +7 -delete

# Keep only last 10 log files
cd ~/actions-runner/_diag
ls -t Worker_*.log | tail -n +11 | xargs rm -f
```

**Option 3: Clean Package Caches**

```bash
# APT cache
sudo apt-get clean
sudo apt-get autoclean

# NPM cache
npm cache clean --force

# Maven cache (BE CAREFUL - may slow next build)
rm -rf ~/.m2/repository

# Gradle cache
rm -rf ~/.gradle/caches
```

**Option 4: Clean Build Artifacts**

```bash
# Find and remove build directories
find ~ -type d -name "target" -o -name "build" -o -name "dist" | xargs rm -rf

# Clean temp files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
```

---

## Validation

### 1. Verify Resources Normal

```bash
# CPU < 50%
top -bn1 | grep "Cpu(s)"

# Memory usage < 70%
free -h | grep Mem

# Disk usage < 80%
df -h /
```

### 2. Run Test Deployment

```bash
# Trigger test workflow
gh workflow run test-runner-health.yml --ref main

# Monitor execution time (should be < 5 minutes)
gh run watch
```

### 3. Check Prometheus Metrics

```bash
# CPU usage
curl -sf "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_cpu_usage_percent{hostname="<runner>"}' \
  | jq -r '.data.result[0].value[1]'

# Memory usage
curl -sf "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_memory_usage_percent{hostname="<runner>"}' \
  | jq -r '.data.result[0].value[1]'

# Disk usage
curl -sf "http://192.168.0.200:9090/api/v1/query" \
  --data-urlencode 'query=runner_disk_usage_percent{hostname="<runner>"}' \
  | jq -r '.data.result[0].value[1]'
```

Expected values:
- CPU: < 50%
- Memory: < 70%
- Disk: < 75%

### 4. Verify No Alerts

```bash
# Check active alerts
curl -sf "http://192.168.0.200:9090/api/v1/alerts" \
  | jq '.data.alerts[] | select(.labels.hostname == "<runner>")'

# Expected: No active alerts
```

---

## Preventive Measures

### 1. Automated Cleanup

Create cron job for regular cleanup:

```bash
sudo crontab -e

# Add:
# Clean Docker weekly (Sunday 2 AM)
0 2 * * 0 docker system prune -f --volumes

# Clean runner logs daily (3 AM)
0 3 * * * find /home/admin/actions-runner/_diag -type f -mtime +7 -delete

# Clean package caches weekly (Monday 2 AM)
0 2 * * 1 apt-get clean && npm cache clean --force
```

### 2. Monitoring Thresholds

Update Prometheus alerts:

```yaml
# infrastructure/prometheus/alerts/runner-health.yaml
- alert: RunnerHighCPU
  expr: runner_cpu_usage_percent > 80
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Runner {{ $labels.hostname }} high CPU"

- alert: RunnerHighMemory
  expr: runner_memory_usage_percent > 85
  for: 10m
  labels:
    severity: warning

- alert: RunnerLowDisk
  expr: runner_disk_free_percent < 20
  for: 5m
  labels:
    severity: critical
```

### 3. Resource Limits

Configure systemd service limits:

```bash
sudo systemctl edit actions.runner.rmnanney-PAWS360.<runner-name>.service

# Add:
[Service]
CPUQuota=80%
MemoryLimit=6G
TasksMax=512
```

### 4. Capacity Planning

Review resource trends weekly:

```promql
# CPU trend (7 days)
avg_over_time(runner_cpu_usage_percent[7d])

# Memory trend (7 days)
avg_over_time(runner_memory_usage_percent[7d])

# Peak usage times
max_over_time(runner_cpu_usage_percent[24h])
```

---

## Escalation

If resource issues persist after remediation:

1. **Scale Horizontally**: Add third runner
   ```bash
   # Deploy new runner via Ansible
   cd infrastructure/ansible
   ansible-playbook -i inventories/production/hosts \
     playbooks/provision-github-runner.yml \
     -e "runner_name=runner-03"
   ```

2. **Scale Vertically**: Increase runner host resources
   - Add RAM: 16GB → 32GB
   - Add CPU cores: 4 → 8
   - Increase disk: 100GB → 250GB

3. **Optimize Workloads**: Review CI/CD pipeline efficiency
   - Use Docker layer caching
   - Parallelize test suites
   - Use smaller base images
   - Reduce build dependencies

---

## Quick Reference

| Resource | Threshold | Quick Fix |
|----------|-----------|-----------|
| CPU > 80% | High | Kill heavy process, reduce concurrency |
| Memory > 85% | High | Drop caches, enable swap |
| Disk > 85% | Critical | `docker system prune -af`, clean logs |
| Load > cores | High | Reduce concurrent jobs |

---

**Last Updated**: 2025-01-11  
**JIRA**: INFRA-474  
**Owner**: SRE Team
