# Runner Capacity Planning Runbook

**JIRA:** INFRA-474  
**Severity:** P3 - Medium  
**Last Updated:** 2024-01-XX

---

## Overview

Guidelines for monitoring, forecasting, and scaling CI/CD runner capacity to meet organizational needs.

### Objectives
- Maintain < 5 minute average queue time
- Keep runner utilization at 70-80% (optimal efficiency)
- Support 20% growth headroom
- Prevent capacity-related workflow failures

---

## Current Capacity

### Runner Inventory

| Runner | CPU Cores | Memory (GB) | Disk (GB) | Status | Max Concurrent Jobs |
|--------|-----------|-------------|-----------|--------|---------------------|
| dell-r640-01 | 24 | 128 | 1000 | Primary | 8 |
| Serotonin-paws360 | 16 | 64 | 500 | Backup | 4 |
| **Total** | **40** | **192** | **1500** | - | **12** |

### Current Utilization

```bash
# Check current capacity usage
./scripts/capacity-check.sh

# Expected output:
# Average utilization: 65%
# Peak utilization: 85%
# Queue time (avg): 2.3 minutes
```

---

## Monitoring Capacity

### Key Metrics

#### 1. Job Queue Metrics

```promql
# Average queue time (target: < 5 minutes)
avg_over_time(github_workflow_run_queue_duration_seconds[1h]) / 60

# Queue depth (target: < 10 jobs)
github_workflow_run_queued_total - github_workflow_run_started_total

# Jobs dropped due to capacity (target: 0)
increase(github_workflow_run_timeout_total{reason="no_runner"}[24h])
```

#### 2. Runner Utilization

```promql
# Runner busy percentage (optimal: 70-80%)
(count(runner_health{busy="true"}) / count(runner_health)) * 100

# Jobs per runner per hour
rate(github_workflow_run_completed_total[1h]) / count(runner_health)

# Concurrent job count
sum(runner_concurrent_jobs)
```

#### 3. Resource Consumption

```promql
# Peak CPU usage across runners
max(avg_over_time(node_cpu_usage[1h]))

# Peak memory usage
max(avg_over_time(node_memory_usage[1h]))

# Disk growth rate
deriv(node_disk_used_bytes[7d])
```

### Capacity Dashboard

Access: http://192.168.0.200:3000/d/capacity

**Key Panels:**
- Runner utilization over time
- Queue depth trends
- Job duration percentiles
- Resource consumption forecast

---

## Capacity Planning Triggers

### When to Add Capacity

| Metric | Warning Threshold | Critical Threshold | Action |
|--------|------------------|-------------------|---------|
| Avg Queue Time | > 5 minutes | > 10 minutes | Add runner |
| Runner Utilization | > 80% | > 90% | Add runner |
| Jobs Timing Out | > 1/day | > 5/day | Add runner immediately |
| Peak Concurrent Jobs | > 10 | > 11 | Add runner |
| Workflow Failure Rate | > 5% | > 10% | Investigate, potentially add capacity |

### Growth Forecasting

```bash
# Generate 30-day capacity forecast
./scripts/forecast-capacity.sh --days 30

# Expected output:
# Current utilization: 65%
# Forecasted utilization (30d): 78%
# Recommendation: Monitor, no action needed
```

**Forecasting Formula:**
```
Forecast = Current_Util + (Growth_Rate * Days)
Growth_Rate = (Current_Util - Prev_Month_Util) / 30
```

---

## Scaling Strategies

### Vertical Scaling (Upgrade Existing Runners)

**When to Use:**
- Individual runner hitting resource limits
- Workflows requiring more resources per job
- Cost-effective vs. adding new runner

**Implementation:**
1. Plan maintenance window
2. Execute failover to backup runner
3. Upgrade hardware (CPU, RAM, disk)
4. Restore runner and validate
5. Execute failback

**Cost:** $500-2000 per runner  
**Time:** 2-4 hours downtime

### Horizontal Scaling (Add New Runners)

**When to Use:**
- Overall capacity insufficient
- Geographic distribution needed
- Specialized workload isolation

**Implementation:**
1. Provision new hardware/VM
2. Install and configure runner
3. Register with GitHub
4. Configure monitoring
5. Gradually increase load

**Cost:** $3000-5000 per new runner  
**Time:** 1-2 days setup

### Dynamic Scaling (Cloud Runners)

**When to Use:**
- Burst capacity needs
- Temporary project demands
- Testing new capacity levels

**Implementation:**
1. Configure cloud provider (AWS, Azure, GCP)
2. Setup auto-scaling group
3. Install runner auto-registration
4. Configure scale-up/down policies

**Cost:** Variable, ~$0.50-2.00/hour per runner  
**Time:** 1 day setup, instant scale

---

## Capacity Optimization

### Job Efficiency Improvements

#### 1. Reduce Job Duration

```yaml
# Optimize workflow caching
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.cache
      node_modules
    key: ${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}

# Parallelize tests
jobs:
  test:
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - run: npm test -- --shard=${{ matrix.shard }}/4
```

#### 2. Reduce Resource Waste

```yaml
# Set appropriate timeouts
jobs:
  build:
    timeout-minutes: 15  # Don't let jobs run indefinitely
    
    steps:
      - name: Cleanup after job
        if: always()
        run: |
          docker system prune -af
          rm -rf ${GITHUB_WORKSPACE}/.cache
```

#### 3. Schedule Heavy Jobs

```yaml
# Run resource-intensive jobs during off-peak hours
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:  # Allow manual trigger
```

### Runner Maintenance

#### Weekly Maintenance

```bash
# Clean up disk space
ssh runner-name '
  docker system prune -af --volumes
  find /home/*/actions-runner/_diag -mtime +7 -delete
  find /home/*/actions-runner/_work -type d -mtime +3 -delete
'

# Check for updates
ssh runner-name 'apt list --upgradable'

# Verify health
./scripts/ci-health-check.sh --comprehensive
```

#### Monthly Capacity Review

```bash
# Generate capacity report
./scripts/capacity-report.sh --period month

# Review key metrics:
# - Average utilization
# - Peak utilization times
# - Queue time trends
# - Growth rate
```

---

## Capacity Scenarios

### Scenario 1: Increased Development Team Size

**Trigger:** Team grows from 10 to 15 developers  
**Expected Impact:** +50% workflow runs  
**Current Capacity:** 65% utilization  
**Forecast:** 97% utilization

**Action Plan:**
1. **Immediate (0-30 days):**
   - Optimize existing workflows for efficiency
   - Implement job caching aggressively
   - Monitor daily

2. **Short-term (30-60 days):**
   - Add 1 new runner (8 core, 32GB RAM)
   - Expected new utilization: 65%

3. **Long-term (60-90 days):**
   - Evaluate cloud burst capacity
   - Plan for next growth phase

### Scenario 2: Large Monorepo Migration

**Trigger:** Migrating 5 repos into 1 monorepo  
**Expected Impact:** Longer build times, more complex workflows  
**Current Job Duration:** Avg 8 minutes  
**Forecast:** Avg 15 minutes

**Action Plan:**
1. **Pre-migration (30 days before):**
   - Benchmark monorepo build times
   - Optimize build parallelization
   - Add caching strategies

2. **Migration (0-7 days):**
   - Add temporary cloud capacity for buffer
   - Monitor queue times closely
   - Be ready to scale quickly

3. **Post-migration (7-30 days):**
   - Analyze actual impact
   - Adjust permanent capacity
   - Optimize workflows based on learnings

### Scenario 3: Security Compliance Requirements

**Trigger:** New requirement for dedicated compliance scanning  
**Expected Impact:** +20% workflow duration, +30% resource usage  
**Current Capacity:** 65% utilization  
**Forecast:** 85% utilization

**Action Plan:**
1. **Evaluation (0-14 days):**
   - Test compliance tooling on existing runners
   - Measure resource impact
   - Determine if dedicated runner needed

2. **Implementation (14-30 days):**
   - If impact > 20%: Add dedicated compliance runner
   - If impact < 20%: Absorb in existing capacity
   - Configure monitoring for compliance jobs

---

## Cost Analysis

### Current Infrastructure Cost

| Item | Monthly Cost |
|------|-------------|
| Runner hardware (amortized) | $500 |
| Network/power | $100 |
| Monitoring infrastructure | $50 |
| Maintenance time (4 hours/mo) | $200 |
| **Total** | **$850/month** |

**Cost per workflow run:** $0.15 (at 5,000 runs/month)

### Scaling Cost Projections

| Scenario | Additional Hardware | Monthly Cost Increase | New Cost/Run |
|----------|-------------------|---------------------|--------------|
| +1 Runner | $3,500 upfront | +$250/month | $0.12 |
| +2 Runners | $7,000 upfront | +$500/month | $0.10 |
| Cloud (burst) | $0 upfront | +$300-800/month | $0.16-0.22 |

### ROI Calculations

**Developer Time Saved:**
- Avg developer hourly rate: $75
- Time saved per developer per day (reduced queue time): 10 minutes
- Team size: 15 developers
- Monthly savings: 15 devs × 10 min/day × 20 days × $75/hour ÷ 60 = $3,750

**Additional Runner ROI:**
- Cost: $3,500 upfront + $250/month
- Savings: $3,750/month (developer time)
- Payback: < 1 month
- **Recommendation:** Strongly positive ROI

---

## Emergency Capacity Procedures

### Temporary Capacity Boost

```bash
# Enable cloud burst runners
./scripts/enable-cloud-runners.sh --provider aws --count 2

# Monitor for 1 hour
watch -n 60 './scripts/capacity-check.sh'

# Disable when crisis resolved
./scripts/disable-cloud-runners.sh
```

### Job Prioritization

```yaml
# High-priority workflows get dedicated runner label
jobs:
  critical-build:
    runs-on: [self-hosted, high-priority]
    
  normal-build:
    runs-on: [self-hosted, standard]
```

---

## Reporting

### Weekly Capacity Report

```bash
# Auto-generated every Monday
./scripts/capacity-report.sh --format email --recipients sre-team@company.com
```

**Report Contents:**
- Current utilization (with trend)
- Queue time statistics
- Top 10 slowest workflows
- Capacity forecast (30 days)
- Recommended actions

### Quarterly Capacity Review

**Stakeholders:** SRE Team, Engineering Leadership, Finance  
**Format:** Presentation + Q&A

**Agenda:**
1. Capacity trends (3-month retrospective)
2. Cost analysis
3. Scaling recommendations
4. Budget requirements
5. Technology roadmap alignment

---

## Related Resources
- [Capacity Monitoring Dashboard](http://192.168.0.200:3000/d/capacity)
- [Performance Degradation Runbook](./performance-degradation.md)
- [Infrastructure Budget Planning](../../docs/finance/infrastructure-budget.md)
- [Workflow Optimization Guide](../../docs/dev/workflow-optimization.md)
