# CI/CD Capacity Planning Guide

**JIRA:** INFRA-474  
**Last Updated:** 2024-01-XX  
**Status:** Production  
**Owner:** SRE Team

---

## Overview

This guide provides strategic capacity planning for the PAWS360 CI/CD infrastructure, including forecasting, scaling decisions, and cost analysis.

**Related Documentation:**
- [Runner Capacity Planning Runbook](./runbooks/runner-capacity-planning.md) - Operational procedures
- [CI/CD Architecture](./infrastructure/ci-cd-architecture.md) - Technical details
- [Operations Playbook](./operations-playbook.md) - Daily operations

---

## Current State

### Infrastructure Inventory

| Resource | Primary | Backup | Total |
|----------|---------|--------|-------|
| **Runners** | 1 | 1 | 2 |
| **CPU Cores** | 24 | 16 | 40 |
| **Memory (GB)** | 128 | 64 | 192 |
| **Disk (GB)** | 1000 | 500 | 1500 |
| **Max Concurrent Jobs** | 8 | 4 | 12 |

### Current Utilization (30-Day Average)

| Metric | Primary | Backup | Target Range |
|--------|---------|--------|--------------|
| **CPU Utilization** | 55% | 20% | 60-80% |
| **Memory Utilization** | 48% | 15% | 60-80% |
| **Disk Utilization** | 42% | 28% | <75% |
| **Job Concurrency** | 4.2 avg | 0.8 avg | 6-10 optimal |
| **Daily Workflow Runs** | ~150 | ~50 | N/A |

**Health Status:** ✅ Healthy - Capacity is appropriate for current load

---

## Capacity Metrics & Monitoring

### Key Performance Indicators (KPIs)

#### 1. Job Queue Time
**Definition:** Time from workflow trigger to job start execution  
**Target:** < 5 minutes (P95)  
**Current:** 2.3 minutes (P95)  
**Status:** ✅ Meeting target

**PromQL Query:**
```promql
histogram_quantile(0.95, 
  rate(github_workflow_run_queue_duration_seconds_bucket[24h])
)
```

**Action Triggers:**
- **Warning:** P95 > 5 minutes for 2 hours
- **Critical:** P95 > 10 minutes for 1 hour
- **Action:** Investigate bottleneck, consider horizontal scaling

---

#### 2. Runner Utilization
**Definition:** Percentage of time runner is executing jobs  
**Target:** 60-80% (optimal efficiency)  
**Current:** Primary 55%, Backup 20%  
**Status:** ✅ Healthy

**PromQL Query:**
```promql
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) * 100
```

**Action Triggers:**
- **Warning:** > 80% sustained for 24 hours
- **Critical:** > 90% sustained for 4 hours
- **Action:** Plan capacity increase (vertical or horizontal)

**Under-Utilization:**
- **Warning:** < 30% sustained for 7 days
- **Action:** Review if over-provisioned, consider cost optimization

---

#### 3. Workflow Duration
**Definition:** End-to-end execution time for workflows  
**Target:** No more than 2x baseline P95  
**Current:** 
  - `ci-quick`: 5 min (P50), 8 min (P95)
  - `ci-local`: 12 min (P50), 18 min (P95)
  - `test-e2e`: 15 min (P50), 25 min (P95)  
**Status:** ✅ Within acceptable range

**PromQL Query:**
```promql
histogram_quantile(0.95, 
  rate(github_workflow_run_duration_seconds_bucket{workflow="ci-local"}[24h])
) / 60
```

**Action Triggers:**
- **Warning:** P95 increases by 50% from baseline
- **Critical:** P95 > 2x baseline
- **Action:** Investigate performance degradation, optimize workflows, or add capacity

---

#### 4. Failover Frequency
**Definition:** Number of automatic failover events  
**Target:** < 2 per week (ideally 0)  
**Current:** ~0.5 per week  
**Status:** ✅ Acceptable

**PromQL Query:**
```promql
increase(runner_failover_count_total[7d])
```

**Action Triggers:**
- **Warning:** > 2 failovers per week
- **Critical:** > 1 failover per day
- **Action:** Investigate root cause (hardware, resource exhaustion, network)

---

### Monitoring Dashboards

**Grafana Dashboards:**
1. **SRE Overview** - Real-time health and availability
   - URL: http://192.168.0.200:3000/d/sre-overview
   - Refresh: 30s
   - Panels: Runner status, CPU/memory/disk, active alerts, MTTR

2. **Capacity Planning** - Utilization trends and forecasting
   - URL: http://192.168.0.200:3000/d/capacity
   - Refresh: 5m
   - Panels: Utilization trends, queue depth, growth forecast, cost projections

3. **Workflow Performance** - Execution metrics
   - URL: http://192.168.0.200:3000/d/workflows
   - Refresh: 1m
   - Panels: Duration percentiles, success rates, job distribution

---

## Growth Forecasting

### Historical Growth Analysis

**Methodology:**
1. Collect 90 days of historical data
2. Calculate monthly growth rate
3. Project 30/60/90 days forward
4. Identify capacity exhaustion date

**Current Growth Rate (Last 90 Days):**
- Workflow runs: +8% per month
- Average duration: Stable (no trend)
- Concurrent jobs: +5% per month

### 30-Day Forecast

**Assumptions:**
- Continued 8% monthly workflow growth
- No significant duration changes
- Team size stable

**Projected Utilization (30 days from now):**

| Metric | Current | Projected | Status |
|--------|---------|-----------|--------|
| Daily Runs | 200 | 216 | ✅ Within capacity |
| Primary CPU | 55% | 59% | ✅ Healthy |
| Primary Memory | 48% | 52% | ✅ Healthy |
| Job Queue Time | 2.3 min | 2.8 min | ✅ Acceptable |

**Recommendation:** No action required in next 30 days

### 90-Day Forecast

**Projected Utilization (90 days from now):**

| Metric | Current | Projected | Status |
|--------|---------|-----------|--------|
| Daily Runs | 200 | 256 | ⚠️ Approaching limits |
| Primary CPU | 55% | 70% | ⚠️ Review needed |
| Primary Memory | 48% | 61% | ✅ Healthy |
| Job Queue Time | 2.3 min | 4.2 min | ⚠️ Watch closely |

**Recommendation:** Plan capacity increase in Q2 2024

### Capacity Exhaustion Estimate

**Assumptions:**
- Critical threshold: 80% utilization sustained
- Growth rate: 8% per month
- No optimization implemented

**Estimated Time to Capacity Exhaustion:**

```
Current Utilization: 55%
Target Threshold: 80%
Available Headroom: 25%
Monthly Growth: 4.4% (8% * 55%)

Months to Exhaustion: 25% / 4.4% = 5.7 months
Estimated Date: June 2024
```

**Action Plan:**
- Q1 2024: Monitor trends, validate forecast
- Q2 2024: Initiate scaling project (procurement, setup)
- Target Completion: May 2024 (before exhaustion)

---

## Scaling Decision Framework

### Decision Tree

```
Is utilization > 80% sustained?
├─ YES → Is this a temporary spike?
│   ├─ YES → Monitor for 48 hours
│   │   └─ If persists → Proceed to scaling
│   └─ NO → Proceed to scaling
└─ NO → Is queue time > 5 minutes?
    ├─ YES → Investigate bottleneck
    │   └─ If capacity-related → Proceed to scaling
    └─ NO → Monitor and review quarterly
```

### Scaling Options Comparison

| Option | Timeline | Cost | Capacity Increase | Complexity | Downtime |
|--------|----------|------|-------------------|------------|----------|
| **Vertical Scaling** | 1-2 weeks | $500-2,000 | +50% | Low | 2-4 hours |
| **Horizontal Scaling** | 1-2 months | $3,000-5,000 | +100% | Medium | None |
| **Cloud Burst** | < 1 day | $0.50-2/hr | Unlimited | Medium | None |
| **Workflow Optimization** | 2-4 weeks | $0 (labor) | +20-40% | High | None |

### Recommended Strategy by Scenario

#### Scenario 1: Gradual Growth (Current State)
**Characteristics:** Steady 5-10% monthly growth, predictable patterns  
**Strategy:** Vertical scaling in Q2 2024  
**Rationale:** Cost-effective, minimal complexity, aligns with forecast

**Action Plan:**
1. Q1 2024: Continue monitoring
2. Q2 2024: Upgrade primary runner (RAM: 128GB → 256GB, CPU: 24 → 32 cores)
3. Estimated Cost: $1,500
4. Expected Capacity Increase: +50% (8 → 12 concurrent jobs on primary)

---

#### Scenario 2: Rapid Growth (Team Expansion)
**Characteristics:** Team size doubles, workflow runs +50% in 1 month  
**Strategy:** Horizontal scaling + workflow optimization  
**Rationale:** Vertical scaling insufficient, need redundancy

**Action Plan:**
1. Immediate: Audit and optimize workflows (target 20% reduction in duration)
2. Month 1: Procure and deploy 3rd runner
3. Month 2: Validate capacity, adjust monitoring thresholds
4. Estimated Cost: $4,000 (hardware) + 40 hours (labor)
5. Expected Capacity Increase: +100% (12 → 24 concurrent jobs)

---

#### Scenario 3: Temporary Spike (Monorepo Migration)
**Characteristics:** 3-month project with +200% workflow increase, then returns to normal  
**Strategy:** Cloud burst runners  
**Rationale:** Avoid capex for temporary need

**Action Plan:**
1. Week 1: Deploy 2 AWS EC2 runners (c5.4xlarge, 16 vCPU, 32 GB)
2. Label runners: `cloud`, `temporary`, `burst`
3. Configure workflows to use cloud runners for non-critical jobs
4. Week 12: Decommission cloud runners
5. Estimated Cost: $600/month * 3 months = $1,800
6. Benefit: No permanent infrastructure investment

---

#### Scenario 4: Cost Optimization (Low Utilization)
**Characteristics:** Primary utilization < 30% sustained, budget pressure  
**Strategy:** Downsize or repurpose excess capacity  
**Rationale:** Over-provisioned, optimize resource allocation

**Action Plan:**
1. Review if backup runner needed (evaluate SLO requirements)
2. Consider: Repurpose backup runner for other workloads (dev/test environments)
3. Alternative: Reduce backup runner specs (vertical downsize)
4. Estimated Savings: $100-200/month (power, maintenance)

---

## Cost Analysis

### Current Operating Costs

**Hardware (One-time):**
- Primary Runner: $4,500 (amortized over 5 years = $75/month)
- Backup Runner: $2,800 (amortized over 5 years = $47/month)
- Monitoring Stack: $300 (amortized = $5/month)
- **Total Hardware:** $127/month

**Operational (Monthly):**
- Power (24/7): $80
- Network bandwidth: $50
- Maintenance/support: $40
- Monitoring tools (Grafana Cloud if used): $0 (self-hosted)
- **Total Operational:** $170/month

**Labor (Monthly):**
- SRE maintenance (8 hours/month @ $75/hr): $600
- **Total Cost:** $897/month

**Per-Workflow-Run Cost:** $897 / 6,000 runs = **$0.15/run**

### Scaling Cost Projections

#### Option 1: Vertical Scaling (Primary Runner Upgrade)

**Investment:**
- Hardware upgrade (RAM + CPU): $1,500
- Installation labor (4 hours): $300
- **Total Investment:** $1,800

**Ongoing:**
- Additional power: +$15/month
- Amortized hardware: +$25/month
- **Total New Monthly Cost:** $937/month (+$40)

**Capacity Increase:** +50% (12 → 18 concurrent jobs)  
**New Per-Run Cost:** $937 / 9,000 runs = **$0.10/run** (33% reduction)

**ROI:** Break-even at 18 months

---

#### Option 2: Horizontal Scaling (Add 3rd Runner)

**Investment:**
- New server: $3,500
- Setup/configuration (16 hours): $1,200
- Monitoring integration: $200
- **Total Investment:** $4,900

**Ongoing:**
- Power: +$40/month
- Maintenance: +$20/month
- Amortized hardware: +$58/month
- SRE time: +$200/month (additional maintenance)
- **Total New Monthly Cost:** $1,215/month (+$318)

**Capacity Increase:** +100% (12 → 24 concurrent jobs)  
**New Per-Run Cost:** $1,215 / 12,000 runs = **$0.10/run** (33% reduction)

**ROI:** Break-even at 15 months

---

#### Option 3: Cloud Burst (AWS EC2)

**No Upfront Investment**

**Ongoing (per runner):**
- EC2 c5.4xlarge (16 vCPU, 32 GB): $0.68/hour
- Data transfer: $0.09/GB
- Estimated usage: 120 hours/month (5 hours/day weekdays)
- **Cost per Runner:** $82/month + data transfer
- **2 Cloud Runners:** $164/month

**Capacity Increase:** +66% (12 → 20 concurrent jobs)  
**Total Monthly Cost:** $1,061/month (+$164)  
**Per-Run Cost:** $1,061 / 10,000 runs = **$0.11/run**

**ROI:** Immediate (no capex), but higher opex long-term

**Best For:** Temporary capacity needs (< 6 months)

---

## Capacity Optimization Strategies

### Workflow Optimization

**Impact:** 20-40% capacity increase without hardware investment

#### 1. Caching Dependencies
**Current:** 30% of workflows re-download dependencies  
**Solution:** Implement GitHub Actions cache for npm, Maven, Docker layers  
**Expected Savings:** 2-3 minutes per workflow = 10-15% duration reduction

**Implementation:**
```yaml
# .github/workflows/ci-local.yml
- uses: actions/cache@v3
  with:
    path: |
      ~/.m2/repository
      ~/.npm
      /var/lib/docker
    key: ${{ runner.os }}-build-${{ hashFiles('**/pom.xml', '**/package-lock.json') }}
```

---

#### 2. Parallelization
**Current:** Some workflows run sequentially when could be parallel  
**Solution:** Split jobs to run concurrently  
**Expected Savings:** 30-40% reduction in total workflow time

**Example:**
```yaml
# Before: Sequential (25 minutes total)
jobs:
  build-and-test:
    steps:
      - Build (10 min)
      - Unit tests (8 min)
      - E2E tests (7 min)

# After: Parallel (10 minutes total - longest job)
jobs:
  build:
    steps:
      - Build (10 min)
  unit-tests:
    needs: build
    steps:
      - Unit tests (8 min)
  e2e-tests:
    needs: build
    steps:
      - E2E tests (7 min)
```

---

#### 3. Workflow Efficiency Audit
**Process:**
1. Identify slowest workflows (P95 duration)
2. Profile execution time per step
3. Optimize bottlenecks (downloads, builds, tests)
4. Implement incremental builds

**Target Workflows:**
- `ci-local`: 18 min (P95) → Target 12 min (33% reduction)
- `test-e2e`: 25 min (P95) → Target 18 min (28% reduction)

---

### Resource Waste Reduction

#### 1. Automatic Cleanup
**Current:** Old Docker images, workflow artifacts accumulate  
**Solution:** Automated cleanup scripts (already implemented in runner-degradation runbook)

**Expected Savings:** Prevent disk exhaustion, reduce cleanup incidents

#### 2. Off-Peak Scheduling
**Current:** Heavy jobs run anytime  
**Solution:** Schedule resource-intensive jobs during off-peak hours (nights, weekends)

**Expected Benefit:** Reduce contention during business hours, improve queue times by 20%

**Implementation:**
```yaml
# .github/workflows/heavy-job.yml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:  # Allow manual trigger if needed
```

---

## Capacity Planning Calendar

### Quarterly Review Schedule

**Q1 (January-March):**
- Week 1: Review previous quarter metrics
- Week 4: Update growth forecast
- Week 8: Validate capacity planning model
- Week 12: Prepare Q2 budget recommendations

**Q2 (April-June):**
- Week 1: Execute planned scaling projects (if scheduled)
- Week 4: Validate new capacity
- Week 8: Adjust monitoring thresholds
- Week 12: Prepare Q3 forecast

**Q3 (July-September):**
- Week 1: Review utilization trends
- Week 4: Audit workflow efficiency
- Week 8: Implement optimization projects
- Week 12: Prepare Q4 budget

**Q4 (October-December):**
- Week 1: Annual capacity review
- Week 4: Plan next year capacity roadmap
- Week 8: Budget finalization
- Week 12: Document lessons learned

---

### Monthly Capacity Report

**Generated:** 1st Monday of each month  
**Distribution:** SRE team, Engineering leadership  
**Format:** Markdown report + Grafana dashboard snapshot

**Report Contents:**
1. Executive Summary
   - Current utilization status (🟢 🟡 🔴)
   - Key metrics vs. targets
   - Recommendations (if any)

2. Utilization Trends
   - CPU, memory, disk usage (30-day rolling)
   - Job queue time trends
   - Workflow duration trends

3. Growth Analysis
   - Actual vs. forecasted growth
   - Forecast adjustment (if needed)
   - Time to capacity exhaustion

4. Cost Analysis
   - Current operating costs
   - Cost per workflow run
   - Projected costs (next quarter)

5. Action Items
   - Scaling projects (if needed)
   - Optimization opportunities
   - Monitoring improvements

**Automation:**
```bash
# Generate report
cd /home/ryan/repos/PAWS360
./scripts/generate-capacity-report.sh --period 30d --output reports/capacity-$(date +%Y%m).md

# Email to stakeholders
./scripts/send-capacity-report.sh --to sre-team@example.com --to eng-leadership@example.com
```

---

## Action Items & Next Steps

### Immediate (Next 30 Days)
- [ ] Review current capacity metrics weekly
- [ ] Implement workflow caching (10-15% duration reduction)
- [ ] Audit slowest workflows for optimization opportunities
- [ ] Validate growth forecast accuracy

### Short-Term (Next 90 Days)
- [ ] Implement workflow parallelization (30% duration reduction)
- [ ] Review off-peak scheduling opportunities
- [ ] Generate first monthly capacity report
- [ ] Document capacity planning process improvements

### Long-Term (Next 6-12 Months)
- [ ] Execute vertical scaling project (Q2 2024) if forecast validates
- [ ] Evaluate cloud burst runners for temporary capacity needs
- [ ] Implement predictive alerting for capacity exhaustion
- [ ] Review SLOs and adjust capacity targets

---

## Related Documentation

- [Runner Capacity Planning Runbook](./runbooks/runner-capacity-planning.md) - Operational procedures
- [CI/CD Architecture](./infrastructure/ci-cd-architecture.md) - Infrastructure design
- [Operations Playbook](./operations-playbook.md) - Daily operations
- [Performance Degradation Runbook](./runbooks/performance-degradation.md) - Performance issues

---

**Document Owner:** SRE Team  
**Review Frequency:** Quarterly  
**Next Review:** 2024-04-XX
