# Failure Reproduction Guide

**JIRA:** INFRA-474  
**Purpose:** Step-by-step procedures for reproducing CI/CD infrastructure failures in controlled environments

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Runner Degradation Scenarios](#runner-degradation-scenarios)
3. [Failover Scenarios](#failover-scenarios)
4. [Monitoring Alert Scenarios](#monitoring-alert-scenarios)
5. [Network Failure Scenarios](#network-failure-scenarios)
6. [Recovery Procedures](#recovery-procedures)

---

## Prerequisites

### Required Access
- SSH access to runner hosts
- Prometheus/Grafana admin access
- GitHub repository admin access
- `sudo` privileges on runner hosts

### Required Tools
```bash
# Install diagnostic tools
sudo apt-get update
sudo apt-get install -y \
  stress-ng \
  iperf3 \
  htop \
  iotop \
  sysstat \
  jq \
  curl
```

### Safety Checks
Before reproducing failures:

1. **Verify monitoring is active:**
   ```bash
   curl http://192.168.0.200:9090/-/healthy
   curl http://192.168.0.200:3000/api/health
   ```

2. **Confirm backup runner available:**
   ```bash
   gh api /repos/rpalermodrums/PAWS360/actions/runners --jq '.runners[] | select(.status=="online") | .name'
   ```

3. **Check for active workflows:**
   ```bash
   gh run list --limit 5 --json status,name
   ```

4. **Set maintenance window (if applicable):**
   - Notify team in Slack/communication channel
   - Update status page if available

---

## Runner Degradation Scenarios

### Scenario 1: High CPU Load

**Objective:** Simulate sustained high CPU usage triggering degradation detection

**Steps:**

1. **Baseline measurement:**
   ```bash
   # Check current CPU usage
   top -bn1 | grep "Cpu(s)"
   
   # Query Prometheus baseline
   curl -s "http://192.168.0.200:9090/api/v1/query" \
     --data-urlencode "query=100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\",instance=~\"$(hostname).*\"}[5m])) * 100)" \
     | jq -r '.data.result[0].value[1]'
   ```

2. **Trigger high CPU load:**
   ```bash
   # Start CPU stress (runs for 10 minutes)
   stress-ng --cpu $(nproc) --timeout 600s --metrics-brief &
   STRESS_PID=$!
   echo "Stress PID: $STRESS_PID"
   ```

3. **Monitor detection:**
   ```bash
   # Watch for alert in Prometheus
   watch -n 15 'curl -s http://192.168.0.200:9090/api/v1/alerts | jq ".data.alerts[] | select(.labels.alertname==\"RunnerHighCPU\")"'
   ```

4. **Verify failover initiated:**
   ```bash
   # Check if jobs moving to backup runner
   gh run list --limit 10 --json status,conclusion,name
   ```

5. **Cleanup:**
   ```bash
   # Stop stress test
   kill $STRESS_PID
   pkill -f stress-ng
   
   # Wait for recovery
   sleep 60
   
   # Verify alert cleared
   curl -s http://192.168.0.200:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.alertname=="RunnerHighCPU")'
   ```

**Expected Results:**
- CPU usage > 85% within 30 seconds
- `RunnerHighCPU` alert fires within 2 minutes
- Failover initiated within 5 minutes
- Alert clears within 3 minutes after cleanup

---

### Scenario 2: High Memory Pressure

**Objective:** Simulate memory exhaustion triggering degradation detection

**Steps:**

1. **Baseline measurement:**
   ```bash
   # Check current memory usage
   free -h
   
   # Query Prometheus baseline
   curl -s "http://192.168.0.200:9090/api/v1/query" \
     --data-urlencode "query=(1 - (node_memory_MemAvailable_bytes{instance=~\"$(hostname).*\"} / node_memory_MemTotal_bytes{instance=~\"$(hostname).*\"})) * 100" \
     | jq -r '.data.result[0].value[1]'
   ```

2. **Trigger high memory usage:**
   ```bash
   # Start memory stress (90% of available memory for 10 minutes)
   stress-ng --vm 2 --vm-bytes 90% --timeout 600s --metrics-brief &
   STRESS_PID=$!
   echo "Stress PID: $STRESS_PID"
   ```

3. **Monitor detection:**
   ```bash
   # Watch for alert
   watch -n 15 'curl -s http://192.168.0.200:9090/api/v1/alerts | jq ".data.alerts[] | select(.labels.alertname==\"RunnerHighMemory\")"'
   ```

4. **Cleanup:**
   ```bash
   kill $STRESS_PID
   pkill -f stress-ng
   sleep 60
   ```

**Expected Results:**
- Memory usage > 85% within 30 seconds
- `RunnerHighMemory` alert fires within 2 minutes
- System remains stable (no OOM killer)
- Alert clears within 3 minutes after cleanup

---

### Scenario 3: Disk I/O Saturation

**Objective:** Simulate high disk I/O triggering performance degradation

**Steps:**

1. **Baseline measurement:**
   ```bash
   iostat -x 1 5
   ```

2. **Trigger high I/O load:**
   ```bash
   # Create I/O stress in temp directory
   stress-ng --iomix 4 --temp-path /tmp --timeout 600s --metrics-brief &
   STRESS_PID=$!
   ```

3. **Monitor I/O metrics:**
   ```bash
   # Watch disk utilization
   watch -n 5 'iostat -x 1 1 | grep -A 2 sda'
   ```

4. **Cleanup:**
   ```bash
   kill $STRESS_PID
   pkill -f stress-ng
   ```

**Expected Results:**
- Disk utilization > 80%
- I/O wait times increase noticeably
- Runner performance degrades but remains functional

---

## Failover Scenarios

### Scenario 4: Primary Runner Failure (Hard Stop)

**Objective:** Simulate complete primary runner failure

**Steps:**

1. **Trigger test workflow:**
   ```bash
   gh workflow run ci-quick.yml --ref main
   
   # Wait for job to start
   sleep 10
   
   # Verify job running on primary
   gh run list --limit 1 --json status,displayTitle
   ```

2. **Stop primary runner service:**
   ```bash
   # On primary runner
   sudo systemctl stop actions.runner.*
   
   # Verify stopped
   sudo systemctl status actions.runner.*
   ```

3. **Monitor failover:**
   ```bash
   # Watch for job to move to secondary
   watch -n 10 'gh run list --limit 5 --json status,name,conclusion'
   ```

4. **Verify secondary handling workload:**
   ```bash
   # Check runner status
   gh api /repos/rpalermodrums/PAWS360/actions/runners --jq '.runners[] | {name, status, busy}'
   ```

5. **Restore primary runner:**
   ```bash
   sudo systemctl start actions.runner.*
   sudo systemctl status actions.runner.*
   ```

**Expected Results:**
- Primary runner marked offline within 1 minute
- New jobs routed to secondary within 2 minutes
- In-flight jobs fail gracefully and retry
- Primary restoration successful

---

### Scenario 5: Network Partition

**Objective:** Simulate network connectivity loss

**Steps:**

1. **Block GitHub API access:**
   ```bash
   # On primary runner
   sudo iptables -A OUTPUT -d api.github.com -j DROP
   sudo iptables -A OUTPUT -d github.com -j DROP
   
   # Verify block
   curl -v --max-time 5 https://api.github.com
   ```

2. **Monitor detection:**
   ```bash
   # Watch for connectivity alerts
   curl -s http://192.168.0.200:9090/api/v1/alerts | jq '.data.alerts[] | select(.labels.instance | contains("'$(hostname)'"))'
   ```

3. **Restore network:**
   ```bash
   # Remove iptables rules
   sudo iptables -D OUTPUT -d api.github.com -j DROP
   sudo iptables -D OUTPUT -d github.com -j DROP
   
   # Verify restoration
   curl https://api.github.com
   ```

**Expected Results:**
- Runner marked offline within 2 minutes
- Network alert fires within 3 minutes
- Jobs route to backup runner
- Recovery automatic after network restoration

---

## Monitoring Alert Scenarios

### Scenario 6: Alert False Positive Investigation

**Objective:** Reproduce and investigate intermittent false positive alerts

**Steps:**

1. **Review alert history:**
   ```bash
   # Query Prometheus for alert occurrences
   curl -s "http://192.168.0.200:9090/api/v1/query_range" \
     --data-urlencode "query=ALERTS{alertname=\"RunnerHighCPU\"}" \
     --data-urlencode "start=$(date -u -d '24 hours ago' +%s)" \
     --data-urlencode "end=$(date -u +%s)" \
     --data-urlencode "step=300" \
     | jq '.data.result'
   ```

2. **Check alert thresholds:**
   ```bash
   # View alert rule definition
   curl -s http://192.168.0.200:9090/api/v1/rules | jq '.data.groups[] | select(.name=="runners") | .rules[] | select(.name=="RunnerHighCPU")'
   ```

3. **Analyze metric data:**
   ```bash
   # Graph metric around alert time
   curl -s "http://192.168.0.200:9090/api/v1/query_range" \
     --data-urlencode "query=100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)" \
     --data-urlencode "start=$(date -u -d '1 hour ago' +%s)" \
     --data-urlencode "end=$(date -u +%s)" \
     --data-urlencode "step=60" \
     | jq -r '.data.result[0].values[] | @tsv'
   ```

4. **Correlate with system logs:**
   ```bash
   # Check for system events
   sudo journalctl --since "1 hour ago" | grep -E "CPU|memory|disk"
   ```

**Investigation Checklist:**
- [ ] Alert duration < threshold (flapping)
- [ ] Metric spikes correlate with known events
- [ ] Alert rule "for" duration appropriate
- [ ] Threshold values tuned for workload

---

## Network Failure Scenarios

### Scenario 7: Prometheus Connectivity Loss

**Objective:** Simulate monitoring stack unavailability

**Steps:**

1. **Stop Prometheus temporarily:**
   ```bash
   # On monitoring host
   docker compose -f infrastructure/monitoring/docker-compose.yml stop prometheus
   
   # Verify stopped
   curl http://192.168.0.200:9090/-/healthy
   ```

2. **Monitor runner behavior:**
   ```bash
   # Runners should continue functioning
   gh run list --limit 5
   ```

3. **Restore Prometheus:**
   ```bash
   docker compose -f infrastructure/monitoring/docker-compose.yml start prometheus
   
   # Wait for startup
   sleep 10
   
   # Verify healthy
   curl http://192.168.0.200:9090/-/healthy
   ```

**Expected Results:**
- Runners continue processing jobs
- Metrics gap in Prometheus data
- No cascading failures
- Automatic reconnection after restoration

---

## Recovery Procedures

### Standard Recovery Steps

1. **Verify problem resolved:**
   - Check system metrics return to normal
   - Confirm alerts cleared
   - Validate runner online status

2. **Review impact:**
   ```bash
   # Check failed workflow runs
   gh run list --status failure --limit 20
   
   # Review monitoring data
   # Access Grafana: http://192.168.0.200:3000
   ```

3. **Document incident:**
   - Record start/end times
   - Note triggered alerts
   - Document actions taken
   - Capture metrics screenshots

4. **Post-incident validation:**
   ```bash
   # Run health checks
   ./scripts/health-check.sh --comprehensive
   
   # Execute test scenarios
   ./tests/ci/test-runner-degradation-detection.sh
   ./tests/ci/test-automatic-failover.sh
   ```

### Emergency Rollback

If issues persist:

1. **Isolate affected runner:**
   ```bash
   # Stop runner service
   sudo systemctl stop actions.runner.*
   
   # Remove from GitHub
   gh api -X DELETE /repos/rpalermodrums/PAWS360/actions/runners/{runner_id}
   ```

2. **Route all jobs to healthy runner:**
   - Verify backup runner capacity
   - Monitor backup runner metrics closely

3. **Investigate root cause:**
   - Review system logs
   - Check hardware health
   - Analyze metrics leading to failure

---

## Safety Notes

⚠️ **Always:**
- Run tests during low-activity periods
- Have backup runner verified healthy before tests
- Monitor actively during reproduction
- Document all actions and observations
- Set appropriate timeouts on stress tests

⚠️ **Never:**
- Run multiple failure scenarios simultaneously
- Exceed 10-minute stress durations without monitoring
- Test during critical deployment windows
- Skip cleanup procedures

---

## Additional Resources

- [SRE Runbooks](./README.md)
- [Monitoring Dashboard](http://192.168.0.200:3000)
- [Alert Rules Configuration](../../infrastructure/monitoring/prometheus/rules/)
- [Runner Setup Documentation](../../infrastructure/runners/)

---

**Last Updated:** 2024-01-XX  
**Maintained By:** SRE Team  
**JIRA Epic:** INFRA-474
