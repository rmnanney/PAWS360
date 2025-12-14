# Infrastructure Impact Analysis: GitHub Runner Deployment Stabilization

**Feature ID:** 001-github-runner-deploy  
**JIRA Epic:** INFRA-472  
**Date:** 2025-01-XX  
**Author:** DevOps Team  
**Status:** Planning  

---

## Executive Summary

This document analyzes the infrastructure impact of implementing dual GitHub Actions runner groups for production deployment stabilization. The implementation introduces new compute resources, modifies existing CI/CD workflows, and extends monitoring capabilities. Total resource footprint: 2 Linux/x64 hosts, negligible impact on existing infrastructure.

## Scope

### In Scope
- GitHub Actions self-hosted runners (primary + secondary)
- Runner infrastructure provisioning and configuration
- CI/CD workflow modifications
- Monitoring dashboard and alerting
- Secrets management infrastructure

### Out of Scope
- Application code changes (no changes to PAWS360 application)
- Database schema modifications
- Network topology changes (existing network sufficient)
- Load balancer configuration changes

## New Infrastructure Resources

### Compute Resources

#### Primary Runner Host
- **Hostname:** `production-runner-01` (to be provisioned)
- **OS:** Ubuntu 22.04 LTS (Linux/x64)
- **CPU:** 4 cores minimum (8 cores recommended)
- **Memory:** 8GB minimum (16GB recommended)
- **Disk:** 50GB minimum (100GB recommended)
  - OS: 20GB
  - Docker images: 20GB
  - Deployment artifacts: 10GB
- **Network:** 1Gbps connection to production infrastructure
- **Location:** Same datacenter/region as production infrastructure
- **Estimated Cost:** ~$50-100/month (depends on hosting provider)

#### Secondary Runner Host
- **Hostname:** `production-runner-02` (to be provisioned)
- **OS:** Ubuntu 22.04 LTS (Linux/x64)
- **CPU:** 4 cores minimum (8 cores recommended)
- **Memory:** 8GB minimum (16GB recommended)
- **Disk:** 50GB minimum (100GB recommended)
- **Network:** 1Gbps connection to production infrastructure
- **Location:** Same datacenter/region as production infrastructure
- **Estimated Cost:** ~$50-100/month (depends on hosting provider)

**Total New Compute Cost:** ~$100-200/month

### GitHub Organization Resources

#### Runner Groups
- **Primary Runner Group:** `production-primary`
  - Labels: `self-hosted`, `linux`, `x64`, `production`, `primary`
  - Concurrency: 1 active job
  - Idle runners: 1 (always available)

- **Secondary Runner Group:** `production-secondary`
  - Labels: `self-hosted`, `linux`, `x64`, `production`, `secondary`
  - Concurrency: 1 active job
  - Idle runners: 1 (activated on primary failure)

**GitHub Actions Minutes Impact:** Reduced (self-hosted runners don't consume GitHub-hosted minutes)

### Monitoring Infrastructure

#### Grafana Dashboard
- **Dashboard:** `github-runners`
- **Panels:** 6 (success rate, duration, failover events, availability, failures)
- **Storage Impact:** Minimal (~1MB for dashboard definition)

#### Prometheus Metrics
- **New Metrics:** 7 (runner_availability, deployment_success_rate, duration, failover_events, preflight_failures, health_gate_failures, queue_depth)
- **Retention:** 90 days (standard retention policy)
- **Storage Impact:** ~10MB/day = ~900MB total

#### Alerts
- **New Alerts:** 4 (PrimaryRunnerDown, BothRunnersDown, DeploymentFailureRate, FailoverFrequency)
- **Alert Manager Impact:** Negligible (existing alert manager)

**Total Monitoring Impact:** ~1GB storage, negligible compute

### Secrets Infrastructure

#### GitHub Secrets
- **New Secrets:** 2-4 (RUNNER_TOKEN_PRIMARY, RUNNER_TOKEN_SECONDARY, plus deployment-specific)
- **Rotation Schedule:** 90 days maximum age
- **Storage Impact:** Negligible (GitHub-managed)

## Modified Infrastructure Resources

### GitHub Workflows

#### `.github/workflows/ci.yml`
- **Current:** Lines 960-1092 (deploy-to-production job)
- **Modifications:**
  - Add `concurrency` group for production deploys
  - Add runner labels: `[self-hosted, linux, x64, production]`
  - Add preflight checks step
  - Add failover logic step
  - Add health gates step
  - Add metrics collection step
- **Risk Level:** Medium (production workflow changes)
- **Rollback Strategy:** Git revert to previous workflow version

### Ansible Inventory

#### `infrastructure/ansible/inventories/production/hosts`
- **Current State:** Points to localhost (placeholder)
- **Modifications Required:**
  - Add `production-runner-01` to `[runners]` group
  - Add `production-runner-02` to `[runners]` group
  - Update monitoring variables with runner hosts
- **Risk Level:** Low (additive changes only)

### Monitoring Stack

#### Prometheus Configuration
- **Location:** 192.168.0.200:9090
- **Modifications:**
  - Add scrape config for runner metrics
  - Add Push Gateway target (192.168.0.200:9091)
- **Risk Level:** Low (additive scrape targets)

#### Grafana Configuration
- **Location:** 192.168.0.200:3000
- **Modifications:**
  - Import `github-runners` dashboard
  - Add data source for runner metrics
- **Risk Level:** Low (new dashboard, no changes to existing)

## Network Impact

### Firewall Rules

#### Production Runners → Production Infrastructure
- **Protocol:** TCP
- **Ports:** 22 (SSH), 443 (HTTPS), 5432 (PostgreSQL), 6379 (Redis)
- **Direction:** Outbound from runners
- **Justification:** Runners need to deploy to production services

#### Production Runners → GitHub
- **Protocol:** TCP
- **Ports:** 443 (HTTPS)
- **Direction:** Outbound from runners
- **Justification:** Runners pull jobs from GitHub Actions API

#### Production Runners → Monitoring Stack
- **Protocol:** TCP
- **Ports:** 9091 (Prometheus Push Gateway)
- **Direction:** Outbound from runners
- **Justification:** Runners push metrics to monitoring

### Bandwidth Impact

#### Deployment Traffic
- **Frequency:** ~5-10 deployments/day
- **Size per Deployment:** ~500MB (Docker images, artifacts)
- **Daily Bandwidth:** ~2.5-5GB/day
- **Peak Bandwidth:** 100Mbps during deployment

#### Metrics Traffic
- **Frequency:** After each deployment
- **Size per Push:** ~10KB
- **Daily Bandwidth:** ~50-100KB/day
- **Impact:** Negligible

**Total Network Impact:** Minimal, well within existing capacity

## Storage Impact

### Runner Hosts

#### Disk Usage Breakdown
- **OS and Runtime:** 20GB
- **Docker Images:** 20GB (cached base images, layers)
- **Deployment Artifacts:** 10GB (temporary build outputs)
- **Logs:** 5GB (retained 7 days locally)
- **Total per Host:** 55GB used / 100GB total

#### Growth Projections
- **Daily Growth:** ~500MB (logs + artifacts)
- **Monthly Growth:** ~15GB
- **Time to Capacity:** ~3 months (at which point cleanup runs)

### Monitoring Stack

#### Metrics Storage
- **Rate:** ~10MB/day (runner metrics + deployment events)
- **Retention:** 90 days
- **Total Impact:** ~900MB
- **Existing Capacity:** 500GB available, sufficient

### Centralized Logging (Grafana Loki)

#### Log Volume
- **Rate:** ~100MB/day (runner logs, deployment logs)
- **Retention:** 90 days
- **Total Impact:** ~9GB
- **Existing Capacity:** 1TB available, sufficient

**Total Storage Impact:** ~10GB (monitoring + logs), negligible on runner hosts

## Performance Impact

### CI/CD Pipeline

#### Deployment Duration
- **Current:** Varies widely (15-45 minutes due to failures)
- **Target:** p95 ≤10 minutes
- **Expected Improvement:** 50-70% reduction in deployment time
- **Justification:** Failover eliminates manual intervention delays

#### Queue Time
- **Current:** Immediate (GitHub-hosted runners)
- **Expected:** <30 seconds (self-hosted runner startup)
- **Risk:** Queue timeout if both runners busy (30min limit)

### Production Services

#### Deployment Impact
- **Rolling Deployment:** No downtime (existing pattern maintained)
- **Health Gate Validation:** ~1-2 minutes additional validation time
- **Risk:** Health gate false positives may delay deployments

### Monitoring Stack

#### Metrics Collection
- **Scrape Frequency:** Every 15 seconds (Prometheus default)
- **CPU Impact:** <1% on monitoring host
- **Memory Impact:** <100MB additional

#### Dashboard Rendering
- **Query Frequency:** Real-time (Grafana auto-refresh)
- **CPU Impact:** <5% during active viewing
- **Risk:** Dashboard complexity may slow queries (optimize as needed)

## Security Impact

### Attack Surface

#### New Endpoints
- **Runner SSH:** Port 22 (restricted to Ansible control node)
- **Docker Daemon:** Unix socket only (no TCP exposure)
- **Metrics Push:** Port 9091 (restricted to runner hosts)

#### Authentication
- **Runner Registration:** GitHub tokens (90-day rotation)
- **SSH Access:** SSH keys only (password auth disabled)
- **Deployment Secrets:** GitHub Secrets (encrypted at rest)

### Secret Exposure Risk

#### Mitigation Measures
- All secrets in GitHub Secrets (no plaintext in code)
- Sensitive output masking enabled in workflows
- Secrets never persisted to runner disk
- Audit logging for all secret access

#### Risk Level
- **Before Implementation:** High (manual deployments, ad-hoc secrets)
- **After Implementation:** Low (centralized secrets, automated rotation)

### Compliance Impact

#### Audit Trail
- **Deployment Attribution:** User, timestamp, commit SHA logged
- **Failover Events:** Logged with reason and runner details
- **Secret Access:** Logged to centralized logging (1-year retention)

#### Regulatory Compliance
- **FERPA:** No impact (no student data on runner hosts)
- **SOC 2:** Improved (better audit trail, secrets management)
- **ISO 27001:** Aligned (security controls documented)

## Availability Impact

### Failure Modes

#### Single Runner Failure
- **Impact:** Failover to secondary within 30 seconds
- **Service Availability:** Maintained
- **User Experience:** Transparent (no visible impact)

#### Both Runners Failure
- **Impact:** Deployment blocked until runner restored
- **Service Availability:** Maintained (existing deployment continues running)
- **User Experience:** Deployment delays (alert on-call)

### Recovery Time Objectives (RTO)

| Failure Mode | Detection Time | Recovery Time | Total RTO | Impact |
|--------------|----------------|---------------|-----------|---------|
| Primary runner down | <5 minutes | 30 seconds (failover) | <6 minutes | None (failover) |
| Both runners down | <5 minutes | ~15 minutes (manual) | <20 minutes | Deployment blocked |
| Network partition | <5 minutes | Depends on cause | Variable | Deployment blocked |
| Secrets rotation failure | Immediate | <10 minutes (manual fix) | <10 minutes | Deployment blocked |

### Service Level Objectives (SLO)

#### Deployment Success Rate
- **Target:** ≥95% successful deployments
- **Current:** ~70-80% (due to runner failures)
- **Expected:** 95-98% (with failover)

#### Deployment Duration
- **Target:** p95 ≤10 minutes
- **Current:** p95 ~30 minutes (includes retries)
- **Expected:** p95 ~8-10 minutes

## Cost Impact

### Capital Expenses (CapEx)

| Item | Quantity | Unit Cost | Total |
|------|----------|-----------|-------|
| Runner Hosts | 2 | $0 (virtualized) | $0 |
| Storage | 200GB | $0 (existing capacity) | $0 |
| **Total CapEx** | | | **$0** |

### Operational Expenses (OpEx)

| Item | Monthly Cost | Annual Cost |
|------|--------------|-------------|
| Runner Host 1 | $50-100 | $600-1,200 |
| Runner Host 2 | $50-100 | $600-1,200 |
| Monitoring Storage | $0 (existing) | $0 |
| GitHub Actions Minutes | -$200 (savings) | -$2,400 |
| Maintenance (SRE time) | $500 (estimated) | $6,000 |
| **Total OpEx** | **$400-700** | **$4,800-8,400** |
| **Net Savings** | **-$100-200** | **-$1,200-2,400** |

**ROI:** Positive after factoring GitHub Actions minute savings and reduced incident response time.

## Dependencies

### External Dependencies

1. **GitHub Organization Admin Access**
   - Required for: Runner registration, secrets management
   - Owner: DevOps Team
   - Risk: Low (access already available)

2. **Runner Host Provisioning**
   - Required for: Virtual machine creation, OS installation
   - Owner: Infrastructure Team
   - Risk: Low (standard provisioning process)

3. **Production Infrastructure Access**
   - Required for: Ansible inventory, deployment targets
   - Owner: SRE Team
   - Risk: Medium (inventory currently points to localhost)

### Internal Dependencies

1. **Ansible Inventory Finalization**
   - Required for: Runner provisioning, monitoring wiring
   - Blocked by: Authoritative source for production addresses
   - Risk: High (critical blocker for implementation)

2. **Monitoring Stack Availability**
   - Required for: Metrics collection, dashboards, alerts
   - Owner: SRE Team
   - Risk: Low (stack operational at 192.168.0.200)

3. **Secrets Management Coordination**
   - Required for: Runner tokens, deployment secrets
   - Owner: Security Team
   - Risk: Medium (rotation during implementation)

## Risk Assessment

### High Risks

#### Risk: Incomplete Production Inventory
- **Probability:** High
- **Impact:** High (blocks implementation)
- **Mitigation:** Identify authoritative source immediately, document in Ansible inventory guide
- **Owner:** SRE Team

### Medium Risks

#### Risk: Secret Rotation During Implementation
- **Probability:** Medium
- **Impact:** Medium (temporary deployment disruption)
- **Mitigation:** Coordinate with security team, test rotation on staging first
- **Owner:** DevOps Team

#### Risk: Workflow Changes Break Production Deployment
- **Probability:** Low
- **Impact:** High (production deployment blocked)
- **Mitigation:** Test on staging environment first, maintain rollback plan (git revert)
- **Owner:** DevOps Team

### Low Risks

#### Risk: Monitoring Integration Complexity
- **Probability:** Low
- **Impact:** Low (monitoring optional, not blocking)
- **Mitigation:** Leverage existing Prometheus/Grafana stack, use standard integrations
- **Owner:** SRE Team

## Rollback Plan

### Phase 1: Runner Provisioning
- **Rollback:** Decommission runner hosts (no impact on production)
- **Time:** <15 minutes

### Phase 2: Workflow Modifications
- **Rollback:** Git revert to previous ci.yml version
- **Time:** <5 minutes
- **Risk:** May require manual deployment to restore previous state

### Phase 3: Monitoring Integration
- **Rollback:** Remove dashboard, disable alerts (no impact on production)
- **Time:** <10 minutes

### Complete Rollback
- **Total Time:** <30 minutes
- **Service Impact:** None (rollback is transparent to production services)

## Validation Criteria

### Pre-Deployment Validation
- [ ] Runner hosts provisioned and accessible via SSH
- [ ] Ansible inventory updated with runner hosts
- [ ] GitHub runner registration tokens generated
- [ ] Monitoring stack operational and accessible
- [ ] Staging environment tested with new workflow

### Post-Deployment Validation
- [ ] Both runners registered and healthy in GitHub
- [ ] Preflight checks pass on both runners
- [ ] Failover mechanism tested (disable primary, verify secondary activates)
- [ ] Metrics flowing to Prometheus Push Gateway
- [ ] Grafana dashboard displays runner health
- [ ] Alerts configured and routing to on-call

### Success Criteria (30-Day Evaluation)
- [ ] Deployment success rate ≥95%
- [ ] p95 deployment duration ≤10 minutes
- [ ] Failover success rate ≥90%
- [ ] Zero secret leakage incidents
- [ ] <5 minutes to diagnose deployment failures

## Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Setup (T001-T012) | 2-3 days | JIRA access, context files |
| Phase 2: Foundation (T013-T021) | 3-5 days | Ansible inventory, runner hosts |
| Phase 3: US1 Implementation (T022-T042) | 5-7 days | Phase 2 complete, staging environment |
| Phase 4: US2 Diagnostics (T043-T063) | 3-5 days | US1 complete, monitoring stack |
| Phase 5: US3 Guardrails (T064-T085) | 3-5 days | US2 complete, approval process |
| Phase 6: Polish (T086-T104) | 2-3 days | All user stories complete |
| **Total Implementation Time** | **18-28 days** | All dependencies resolved |

**Note:** Timeline assumes no blockers. Production inventory finalization is critical path.

## Conclusion

The GitHub runner deployment stabilization feature introduces minimal infrastructure impact while significantly improving deployment reliability. Total resource footprint: 2 Linux/x64 hosts, ~1GB monitoring storage, negligible network impact. Expected ROI: Positive due to GitHub Actions minute savings and reduced incident response time. Critical blocker: Production inventory finalization (authoritative source needed).

**Recommendation:** Proceed with implementation after resolving production inventory dependency.

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Next Review:** After Phase 1 completion
