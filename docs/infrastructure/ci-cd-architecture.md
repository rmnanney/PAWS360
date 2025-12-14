# CI/CD Infrastructure Architecture

**JIRA:** INFRA-474  
**Last Updated:** 2024-01-XX  
**Status:** Production  
**Owner:** SRE Team

---

## Overview

This document describes the architecture of the PAWS360 CI/CD infrastructure, including runner deployment, monitoring, and operational procedures.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          GitHub.com (Cloud)                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  PAWS360 Repository                                              │   │
│  │  - Workflows (.github/workflows/)                                │   │
│  │  - Runner Registration                                           │   │
│  │  - Job Queue Management                                          │   │
│  └────────────┬─────────────────────────┬──────────────────────────┘   │
└───────────────┼─────────────────────────┼──────────────────────────────┘
                │                         │
                │ HTTPS/WebHook           │ HTTPS/WebHook
                ▼                         ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│  Primary Runner             │ │  Backup Runner              │
│  dell-r640-01-runner        │ │  Serotonin-paws360          │
├─────────────────────────────┤ ├─────────────────────────────┤
│  Hardware:                  │ │  Hardware:                  │
│  - CPU: 24 cores            │ │  - CPU: 16 cores            │
│  - RAM: 128 GB              │ │  - RAM: 64 GB               │
│  - Disk: 1 TB SSD           │ │  - Disk: 500 GB SSD         │
│                             │ │                             │
│  Software:                  │ │  Software:                  │
│  - GitHub Actions Runner    │ │  - GitHub Actions Runner    │
│  - Docker Engine 20.10+     │ │  - Docker Engine 20.10+     │
│  - Node Exporter            │ │  - Node Exporter            │
│  - Promtail Agent           │ │  - Promtail Agent           │
│                             │ │                             │
│  Labels:                    │ │  Labels:                    │
│  - self-hosted              │ │  - self-hosted              │
│  - primary                  │ │  - backup                   │
│  - high-capacity            │ │  - standard-capacity        │
└────────────┬────────────────┘ └────────────┬────────────────┘
             │                               │
             │ Metrics/Logs                  │ Metrics/Logs
             └────────────┬──────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│         Monitoring Stack (192.168.0.200)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │  Prometheus      │  │  Loki            │                │
│  │  Port: 9090      │  │  Port: 3100      │                │
│  │                  │  │                  │                │
│  │  - Metrics DB    │  │  - Log Storage   │                │
│  │  - Alert Engine  │  │  - Query Engine  │                │
│  │  - 15d retention │  │  - 30d retention │                │
│  └────────┬─────────┘  └────────┬─────────┘                │
│           └────────────┬─────────┘                          │
│                        │                                    │
│           ┌────────────▼─────────┐                          │
│           │  Grafana             │                          │
│           │  Port: 3000          │                          │
│           │                      │                          │
│           │  Dashboards:         │                          │
│           │  - SRE Overview      │                          │
│           │  - Runner Metrics    │                          │
│           │  - Alert History     │                          │
│           └──────────────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Details

### GitHub Actions Runners

#### Primary Runner: dell-r640-01-runner

**Purpose:** Main CI/CD execution environment  
**Location:** On-premises data center  
**IP Address:** 192.168.0.201 (internal)

**Specifications:**
- **CPU:** 24 cores (Intel Xeon)
- **Memory:** 128 GB DDR4 ECC
- **Storage:** 1 TB NVMe SSD
- **Network:** 10 Gbps

**Capacity:**
- Max Concurrent Jobs: 8
- Typical Job Duration: 8-12 minutes
- Daily Workflow Runs: ~150

**Runner Configuration:**
```bash
# Location: /home/runner/actions-runner/
Runner Name: dell-r640-01-runner
Runner Group: Default
Labels: self-hosted, Linux, X64, primary, high-capacity
Work Folder: _work
```

**Systemd Service:**
- Service Name: `actions.runner.rpalermodrums-PAWS360.dell-r640-01-runner.service`
- Auto-start: Enabled
- Restart Policy: on-failure

#### Backup Runner: Serotonin-paws360

**Purpose:** Failover and overflow capacity  
**Location:** On-premises (secondary location)  
**IP Address:** 192.168.0.202 (internal)

**Specifications:**
- **CPU:** 16 cores (AMD Ryzen)
- **Memory:** 64 GB DDR4
- **Storage:** 500 GB SSD
- **Network:** 1 Gbps

**Capacity:**
- Max Concurrent Jobs: 4
- Typical Job Duration: 10-15 minutes
- Daily Workflow Runs: ~50 (overflow)

**Runner Configuration:**
```bash
# Location: /home/runner/actions-runner/
Runner Name: Serotonin-paws360
Runner Group: Default
Labels: self-hosted, Linux, X64, backup, standard-capacity
Work Folder: _work
```

---

### Monitoring Infrastructure

#### Prometheus (Metrics Collection)

**Purpose:** Time-series metrics database and alerting engine  
**URL:** http://192.168.0.200:9090

**Data Sources:**
- Node Exporter (system metrics from runners)
- GitHub API (workflow metrics)
- Custom exporters (runner health)

**Key Metrics Collected:**
```promql
# System Metrics
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_disk_io_time_seconds_total
node_network_receive_bytes_total

# Runner Metrics (custom)
runner_health{runner="name"}
runner_concurrent_jobs
runner_job_duration_seconds

# Workflow Metrics
github_workflow_run_duration_seconds
github_workflow_run_conclusion_total
github_workflow_run_queue_duration_seconds
```

**Retention:** 15 days  
**Scrape Interval:** 30 seconds  
**Alert Evaluation:** Every 1 minute

**Alert Rules:**
- `RunnerHighCPU`: CPU > 85% for 5 minutes
- `RunnerHighMemory`: Memory > 85% for 5 minutes
- `RunnerOffline`: Runner unreachable for 2 minutes
- `RunnerPerformanceDegradation`: Job duration > 2x baseline

#### Loki (Log Aggregation)

**Purpose:** Centralized log collection and query engine  
**URL:** http://192.168.0.200:3100

**Log Sources:**
- systemd-journal (runner service logs)
- /var/log/* (system logs)
- Docker container logs
- GitHub Actions workflow logs

**Log Labels:**
```
{
  hostname="runner-name",
  job="systemd-journal",
  unit="actions.runner.*",
  level="info|warn|error"
}
```

**Retention:** 30 days  
**Ingestion Rate:** ~10 MB/day per runner

#### Grafana (Visualization)

**Purpose:** Monitoring dashboards and visualization  
**URL:** http://192.168.0.200:3000  
**Credentials:** admin / [stored in 1Password]

**Dashboards:**
1. **SRE Overview** (`/d/sre-overview`)
   - Runner status and health
   - Workflow success rates
   - Active alerts
   - MTTR metrics

2. **Runner Metrics** (`/d/runner-metrics`)
   - CPU, memory, disk utilization
   - Network throughput
   - Job execution trends

3. **Capacity Planning** (`/d/capacity`)
   - Utilization forecasting
   - Queue depth trends
   - Growth projections

---

## Data Flow

### Job Execution Flow

```
1. Developer pushes code → GitHub
                           ↓
2. GitHub evaluates workflow triggers
   (on: push, pull_request, schedule, etc.)
                           ↓
3. GitHub creates workflow run
   Adds to job queue
                           ↓
4. Available runner picks up job
   Selection criteria:
   - Runner status: online
   - Runner busy: false
   - Label match: self-hosted
   - Priority: primary > backup
                           ↓
5. Runner executes workflow steps
   - Checkout code
   - Setup environment
   - Run commands
   - Upload artifacts
                           ↓
6. Runner reports results to GitHub
   Updates job status: success/failure
                           ↓
7. Metrics exported to Prometheus
   Logs forwarded to Loki
```

### Failover Flow

```
1. Primary runner degradation detected
   (CPU > 85% for 5 minutes)
                           ↓
2. Prometheus alert fires: RunnerHighCPU
                           ↓
3. Alertmanager evaluates alert rules
   (severity, duration, conditions)
                           ↓
4. If degradation persists > 5 minutes:
   - GitHub marks runner as degraded
   - New jobs route to backup runner
                           ↓
5. Backup runner begins accepting jobs
   Capacity reduces from 12 → 4 concurrent
                           ↓
6. Monitoring tracks failover metrics
   - Failover duration
   - Job success rate during failover
   - Backup runner performance
                           ↓
7. When primary recovers:
   - Health check passes
   - Alert clears in Prometheus
   - Primary resumes accepting jobs
   - Gradual failback over 10 minutes
```

---

## High Availability Design

### Redundancy

**Runner Level:**
- 2 runners (primary + backup)
- Geographic diversity (different locations)
- Independent power/network

**Monitoring Level:**
- Single monitoring stack (acceptable for P2 service)
- Backed up daily
- Disaster recovery: Rebuild from IaC in 2 hours

### Failure Modes

| Failure | Detection Time | Failover Time | RTO | Impact |
|---------|---------------|---------------|-----|--------|
| Primary runner hardware failure | 2 minutes | 5 minutes | 7 minutes | Jobs queue briefly |
| Primary runner OS crash | 1 minute | 5 minutes | 6 minutes | In-flight jobs fail |
| Network partition | 2 minutes | 5 minutes | 7 minutes | Jobs route to backup |
| Both runners down | 2 minutes | N/A (manual) | 30 minutes | All jobs queue |
| Monitoring stack down | N/A | N/A | 2 hours | Blind execution |

### Service Level Objectives (SLOs)

**Availability:** 99% (allows ~7 hours downtime/month)  
**Job Success Rate:** 95% (excluding workflow bugs)  
**Mean Time to Detect (MTTD):** < 5 minutes  
**Mean Time to Recover (MTTR):** < 15 minutes  
**Failover Success Rate:** 99%

---

## Security

### Network Security

**Firewall Rules:**
```bash
# Inbound (runners)
Allow: GitHub IP ranges → Runners (443/tcp)
Allow: Monitoring → Runners (9100/tcp) # Node Exporter
Deny: All other inbound

# Outbound (runners)
Allow: Runners → GitHub (443/tcp)
Allow: Runners → Docker Hub (443/tcp)
Allow: Runners → Monitoring (9090/tcp, 3100/tcp)
Allow: Runners → Internal resources (as needed)
```

**GitHub Runner Authentication:**
- PAT stored in GitHub Secrets
- Runner registration token rotated every 90 days
- Runners authenticate via unique registration

### Access Control

**Runner SSH Access:**
- Limited to SRE team (3 members)
- SSH key-based authentication only
- Session logging enabled
- sudo requires password

**Monitoring Access:**
- Grafana: LDAP/SSO authentication
- Prometheus: Internal network only
- Read-only dashboards: Public (authenticated users)

### Secrets Management

**Workflow Secrets:**
- Stored in GitHub Secrets (encrypted at rest)
- Injected as environment variables during execution
- Never logged or exposed in output
- Rotated quarterly

**Infrastructure Secrets:**
- Stored in 1Password (SRE vault)
- Ansible Vault for playbook secrets
- Prometheus credentials in config files (file permissions 0600)

---

## Capacity & Performance

### Current Capacity

**Total Capacity:**
- 12 concurrent jobs (8 primary + 4 backup)
- ~200 workflow runs/day
- Peak utilization: 65%
- Average queue time: 2.3 minutes

**Resource Utilization:**
- Primary Runner: 55% avg (80% peak)
- Backup Runner: 20% avg (60% peak during failover)

### Performance Benchmarks

**Workflow Durations (P50 / P95):**
- `ci-quick`: 5 min / 8 min
- `ci-local`: 12 min / 18 min
- `test-e2e`: 15 min / 25 min

**Scaling Thresholds:**
- Add capacity when: utilization > 80% sustained
- Vertical scale when: individual runner maxed
- Horizontal scale when: queue time > 5 minutes

---

## Disaster Recovery

### Backup Strategy

**Runner Configuration:**
- Backed up: Runner config, systemd units
- Frequency: Weekly (automated)
- Retention: 4 weeks
- Location: GitHub repository (infrastructure/)

**Monitoring Data:**
- Prometheus: Daily snapshots
- Loki: Log retention 30 days (no backup)
- Grafana: Dashboard JSON in git

### Recovery Procedures

**Runner Rebuild:**
1. Provision hardware/VM
2. Run Ansible playbook: `setup-runner.yml`
3. Register runner with GitHub
4. Validate health checks
5. Enable in production

**Time to Recover:** 2 hours (primary), 4 hours (both)

**Monitoring Rebuild:**
1. Deploy monitoring stack: `docker-compose up`
2. Import Grafana dashboards
3. Restore Prometheus config
4. Validate metrics collection

**Time to Recover:** 1 hour

---

## Operational Procedures

### Daily Operations

**Automated:**
- Health checks every 15 minutes
- Log rotation daily
- Disk cleanup daily
- Metrics collection continuous

**Manual (if needed):**
- Review active alerts (morning)
- Check capacity trends (weekly)

### Maintenance Windows

**Monthly:**
- OS security updates (2nd Tuesday, 2-4 AM)
- Runner service restart
- Docker image cleanup
- Review monitoring retention

**Quarterly:**
- Hardware health check
- Capacity planning review
- Disaster recovery drill
- Documentation review

---

## Related Documentation

- [Runbooks](../runbooks/)
  - [Performance Degradation](../runbooks/performance-degradation.md)
  - [Failover Procedures](../runbooks/failover-procedures.md)
  - [Capacity Planning](../runbooks/runner-capacity-planning.md)
- [Test Scenarios](../../tests/ci/)
- [Monitoring Configuration](../../infrastructure/monitoring/)
- [Deployment Procedures](./PRODUCTION-DEPLOYMENT-GUIDE.md)

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-01-XX | 1.0 | Initial architecture documentation | SRE Team |

---

**Document Owner:** SRE Team  
**Review Frequency:** Quarterly  
**Next Review:** 2024-04-XX
