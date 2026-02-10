# PAWS360 Deployment Expectations & Full Verification Guide

> Version: 2025-11-23  
> Scope: Proxmox + Terraform + Ansible HA Staging → Production Promotion  
> Audience: DevOps / Platform / QA / Security Engineering

## 1. Purpose
This document defines the end-to-end deployment expectations for PAWS360 and the comprehensive verification activities required to consider an environment READY. It standardizes: provisioning workflow, required services, configuration baselines, validation, resilience testing, promotion gates, and rollback/disaster recovery criteria.

## 2. Environment Definitions
| Environment | Purpose | Characteristics | Promotion Source |
|-------------|---------|-----------------|------------------|
| `local` | Developer iteration | Minimal services, mock integrations | N/A |
| `staging` | Integrated HA validation | Full HA stack, synthetic & demo seed data | `local` (feature branch merged) |
| `production` | Live student data | Hardened security, observability, backups | `staging` (green + approval) |

## 3. Core Technology Stack (Deployable Units)
- Virtualization: Proxmox (VM templates + clones via Terraform provider)
- Provisioning: Terraform module (`infrastructure/proxmox/terraform-module/`) + example topology file (`examples/staging.tf`)
- Orchestration: Ansible playbooks & roles (`infrastructure/ansible/`)
- Database HA: PostgreSQL via Patroni (etcd-backed consensus)
- Consensus Store: etcd cluster (3 nodes)
- Caching/Session/Queue (future): Redis (Sentinel + Cluster mode across 3 nodes)
- Application Layer: Web/API (Spring Boot backend + Next.js frontend) — placeholder nodes in current staging topology
- Monitoring (future hardening): Node exporter / app metrics / log shipping (to be integrated)

## 4. Prerequisites
### 4.1 Operator Workstation
- Installed: `terraform >= 1.5`, `ansible >= 2.15`, `python3`, `jq`, `ssh-agent`
- Access: Proxmox API token with clone + template privileges
- Network: Reachable Proxmox + all VM IP ranges (e.g. `10.0.50.0/24`)

### 4.2 Secrets & Credentials (Minimum)
- Proxmox API token exported: `export PROXMOX_API_TOKEN=...`
- SSH private key loaded into agent for Ansible (`ssh-add ~/.ssh/id_rsa_paws360`)
- (Pending Hardening) Etcd + Redis + Patroni service passwords & TLS artifacts (currently NOT enforced).

### 4.3 Proxmox Template Baseline
- Base template created (Ubuntu 22.04 LTS or agreed image) with cloud-init enabled
- Public SSH key baked or injected via Terraform variables
- Template name aligned with `variables.tf` (`template_name`)

## 5. Deployment Workflow (Staging Reference)
High-level sequence (Automated Script Option):
1. Terraform plan → apply infrastructure (VM clones + static IP assignment)
2. Ansible provisioning for base OS adjustments / prerequisites
3. HA bootstrap playbook (etcd → Patroni → Redis Sentinel/Cluster → App services)
4. Health-check playbook (port/service readiness)
5. Functional + HA + performance validations
6. Security & configuration conformance scan
7. Promotion decision or remediation

### 5.1 Manual Command Sequence
```bash
# Navigate to repo root
cd /home/ryan/repos/PAWS360

# (Optional) Review staging topology
terraform -chdir=infrastructure/proxmox/terraform-module/examples init
terraform -chdir=infrastructure/proxmox/terraform-module/examples plan -var="proxmox_api_token=$PROXMOX_API_TOKEN"

# Apply infrastructure
terraform -chdir=infrastructure/proxmox/terraform-module/examples apply -auto-approve -var="proxmox_api_token=$PROXMOX_API_TOKEN"

# Provision & bootstrap (script wraps ansible plays)
bash infrastructure/proxmox/deploy-staging.sh

# Or run individual playbooks (if debugging)
ansible-playbook -i infrastructure/ansible/inventories/staging/hosts \
  infrastructure/ansible/playbooks/bootstrap-staging-ha.yml

ansible-playbook -i infrastructure/ansible/inventories/staging/hosts \
  infrastructure/ansible/playbooks/health-check-staging.yml
```

## 6. Configuration Expectations (Baseline)
| Category | Expectation | Verification Method |
|----------|-------------|---------------------|
| Networking | Static IPs match staging inventory | Compare Terraform outputs vs inventory file |
| SSH Access | Key-based login for ops user | `ssh ops@<vm-ip>` success w/o password |
| Time Sync | NTP active (chrony/systemd-timesyncd) | `timedatectl status` consistent across nodes |
| Packages | Required runtime libs installed (Postgres, Redis, etcd) | `ansible -m shell -a 'which patroni'` |
| Firewall (future) | Only required ports open | `nmap -p 22,2379,5432,6379 <ip>` |

## 7. Component Verification Matrix
Each component MUST pass its section before environment is considered READY.

### 7.1 Etcd Cluster
| Check | Command | Expected |
|-------|---------|----------|
| Member list | `ETCDCTL_API=3 etcdctl --endpoints=http://<etcd1>:2379 member list` | 3 members listed, all started |
| Health | `ETCDCTL_API=3 etcdctl --endpoints=http://<etcd1>:2379 endpoint health` | `healthy` per endpoint |
| Leader election | `ETCDCTL_API=3 etcdctl --endpoints=http://<etcd1>:2379 endpoint status` | One node `Leader:true` |

### 7.2 Patroni / PostgreSQL HA
| Check | Command | Expected |
|-------|---------|----------|
| Patroni API | `curl http://<db1>:8008/health` | JSON `"state": "running"` |
| Cluster state | `curl http://<db1>:8008` | One leader, others replicas |
| Replication slots | `psql -h <leader> -U postgres -c "select slot_name, active from pg_replication_slots;"` | Slot per replica, active |
| Failover simulation | Stop leader patroni service | Replica promoted within timeout (<60s) |
| Data continuity | Insert row pre-failover → query post-failover | Row persists |

### 7.3 Redis Sentinel + Cluster
| Check | Command | Expected |
|-------|---------|----------|
| Cluster nodes | `redis-cli -c -h <redis1> cluster nodes` | All 3 nodes; master + replicas |
| Slot coverage | `redis-cli -c -h <redis1> cluster slots` | Slots 0–16383 fully assigned |
| Sentinel monitoring | `redis-cli -h <redis1> -p 26379 SENTINEL masters` | Master entry present |
| Failover | Stop master redis service | Sentinel promotes replica (<30s) |
| Data consistency | Set/get during failover | No data loss |

### 7.4 Application Layer (Web/API)
| Check | Command | Expected |
|-------|---------|----------|
| Port listen | `curl -I http://<web1>:8080` | HTTP 200/302 response |
| Basic API ping | `curl http://<web1>:8080/actuator/health` (Spring) | `"status":"UP"` |
| Frontend landing | `curl -I http://<web1>:3000` or browser | 200 / assets served |
| DB connectivity | API endpoint performing DB query | Successful JSON payload |

### 7.5 Global Health Checks (Ansible)
Run: `ansible-playbook -i infrastructure/ansible/inventories/staging/hosts infrastructure/ansible/playbooks/health-check-staging.yml` → All tasks green.

## 8. High Availability & Resilience Tests
| Scenario | Action | Expected Recovery |
|----------|--------|-------------------|
| Etcd node loss | Power off one etcd VM | Cluster remains healthy (quorum retained) |
| Postgres leader loss | Stop Patroni on leader | Replica promoted <60s, writes resume |
| Redis master loss | Stop master redis process | Sentinel promotes replica <30s |
| Network partition (single node) | Block traffic (`iptables -A INPUT -s <peer> -j DROP`) | Cluster isolates node; upon restore rejoins cleanly |
| Disk pressure (DB) | Fill /var/lib/postgresql to 90% | Alerts triggered (future monitoring) |

All resilience tests MUST be documented (timestamp, node, outcome) in a change record before promotion.

## 9. Performance / Load Baseline (Initial Targets)
| Metric | Target (Staging) | Tool |
|--------|------------------|------|
| Postgres write TPS | >= 500 simple inserts | `pgbench` |
| Redis SET/GET latency (p95) | < 5ms | `redis-benchmark` |
| API median latency | < 150ms | `k6` / `wrk` |
| Frontend initial load | < 2.5s (unprimed) | Browser devtools |

Performance results archived in `docs/portfolio/T058-PERFORMANCE-COMPLETION-REPORT.md` or successor artifact.

## 10. Security & Compliance (Current vs. Future)
| Control | Current State | Future Requirement |
|---------|---------------|--------------------|
| Etcd TLS | Not enabled | Mutual TLS, auth tokens |
| Postgres auth | Basic password (if set) | Managed secrets vault, rotation |
| Redis ACL/TLS | Not enabled | ACL roles + TLS certs |
| Secrets storage | Plain env/inventory | Encrypted Ansible Vault + external secret manager |
| Port exposure | Internal network only | Firewall enforced + segmentation |

Promotion to production is BLOCKED until future requirements implemented.

## 11. Observability & Logging (Roadmap)
- Metrics: Scrape etcd, Patroni, Postgres, Redis, JVM, Node.js
- Logging: Central aggregation (ELK/OpenSearch or Loki) + structured fields
- Alerts: HA failover threshold, replication lag, disk usage, error rate
- Dashboards: Cluster health, latency SLO, capacity trends

## 12. Disaster Recovery & Backup
| Aspect | Expectation | Verification |
|--------|------------|-------------|
| Postgres backups | Daily full + WAL archive | Restore test quarterly |
| Redis data | Snapshot + AOF (if persistence enabled) | Load into test instance |
| Template re-provision | Infra rebuild via Terraform in <30m | Timing measured |
| DR documentation | Up-to-date runbook | Reviewed by Ops quarterly |

Restore test MUST prove point-in-time recovery within defined RPO (<15m) & RTO (<60m).

## 13. CI/CD Promotion Gates
| Gate | Source Data | Pass Criteria |
|------|-------------|---------------|
| Infra Consistency | Terraform state vs inventory | No drift |
| Component Health | Health-check playbook | 100% success |
| HA Scenarios | Logged test outcomes | All green |
| Performance | Load test artifacts | Targets met |
| Security | Hardening checklist | All mandatory complete |
| DR Preparedness | Backup + restore evidence | Last test <90 days |

All gate artifacts attached to release ticket before approval.

## 14. Troubleshooting Quick Reference
| Symptom | Likely Cause | Action |
|---------|-------------|--------|
| Patroni not starting | etcd unreachable | Verify ports 2379, check member list |
| Redis failover slow | Sentinel misconfig / latency | Validate quorum, check logs `/var/log/redis/` |
| Etcd flapping | Clock skew | Ensure NTP sync |
| Terraform hangs | Proxmox API token perms | Reissue token with clone rights |
| SSH failures | Wrong key or cloud-init race | Reboot VM, inspect `/var/log/cloud-init.log` |

## 15. Acceptance Criteria Checklist
Mark all as COMPLETE for staging readiness.
- [ ] Terraform applied with no errors
- [ ] All VMs reachable via SSH
- [ ] Etcd cluster healthy (3/3 members)
- [ ] Patroni cluster running (1 leader + replicas)
- [ ] Redis cluster + sentinel operational
- [ ] Health-check playbook all green
- [ ] HA failover tests successful (etcd, Postgres, Redis)
- [ ] Performance baseline metrics achieved
- [ ] Security hardening items (current scope) acknowledged; future blockers documented
- [ ] DR backup schedule configured (even if initial)
- [ ] Promotion gates compiled (evidence bundle)

## 16. Open Items / Roadmap
- Implement full TLS for etcd, Redis, Postgres connections
- Introduce secret vault (HashiCorp Vault / Cloud provider option)
- Automate k6 performance runs in CI
- Add synthetic student workflow tests (end-to-end scenario) before production cutover
- Integrate monitoring & alerting stack

## 17. Change Management & Versioning
- Changes to this document require PR + approval from Platform + Security reviewers.
- Update version header and date; summarize delta in commit message.

## 18. Appendix: Sample Aggregated Verification Script (Future)
Placeholder for a consolidated `verify-staging.sh` (to orchestrate sequential checks and produce a JSON summary). Not yet implemented.

---
Document owner: Platform Engineering  
Questions: Open an issue tagged `deployment-expectations`
