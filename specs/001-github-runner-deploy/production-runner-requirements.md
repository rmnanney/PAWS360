# Production Runner Infrastructure Requirements

**Feature**: 001-github-runner-deploy  
**JIRA Epic**: INFRA-472  
**JIRA Story**: INFRA-473 (User Story 1)  
**Status**: Requirements defined, awaiting infrastructure provisioning  
**Created**: 2025-12-10  
**Updated**: 2025-12-10

## Overview

This document defines the infrastructure requirements for production GitHub Actions self-hosted runners needed to complete User Story 1 (INFRA-473). All implementation code is complete and validated in staging. Only infrastructure provisioning remains.

## Current Implementation Status

### ✅ Complete (42/46 tasks = 91%)
- **Code Implementation**: 100% complete
  - GitHub Actions workflows with concurrency control, failover logic
  - Ansible playbooks for idempotent deployment and rollback
  - Monitoring stack (Prometheus exporter, Grafana dashboards, alert rules)
  - Test scenarios and validation scripts
  - Documentation and runbooks

- **Staging Validation**: 100% complete
  - Staging runner: dell-r640-01-runner at 192.168.0.51 (ONLINE)
  - Monitoring: Prometheus + Grafana + Alerts (functional)
  - Validation: 8/8 automated tests passing
  - Script: `tests/ci/validate-staging-runner.sh`

### ❌ Pending (4/46 tasks = 9%)
- T042a: Provision production-runner-01 (primary)
- T042b: Provision production-runner-02 (secondary)
- T042c: Deploy monitoring to production runners
- T042d: Production validation and SRE sign-off

## Infrastructure Requirements

### T042a: production-runner-01.paws360.local (Primary Runner)

#### Host Specifications
- **Hostname**: `production-runner-01.paws360.local`
- **Role**: Primary production deployment runner
- **OS**: Linux (Ubuntu 20.04 LTS or 22.04 LTS recommended)
- **CPU**: 4+ cores (8 recommended for build performance)
- **Memory**: 16GB minimum (32GB recommended)
- **Disk**: 100GB minimum (SSD recommended for build cache)
- **Network**: 1Gbps minimum, must reach production environment endpoints

#### Network Configuration
- **DNS Required**: A record for `production-runner-01.paws360.local`
- **IP Address**: From production IP range (to be assigned by network team)
- **Inbound Ports**:
  - SSH (22/tcp) - restricted to jump host or admin workstations
  - Runner-exporter (9101/tcp) - from Prometheus host (192.168.0.200)
- **Outbound Access Required**:
  - GitHub API (api.github.com:443)
  - GitHub Actions (pipelines.actions.githubusercontent.com:443)
  - Production environment endpoints (application servers, databases)
  - Container registries (if using Docker/Podman for builds)
  - Ansible control targets in production environment

#### Firewall Rules
```bash
# Allow Prometheus scraping from monitoring host
sudo ufw allow from 192.168.0.200 to any port 9101 proto tcp comment "Runner exporter for Prometheus"

# Allow SSH from admin networks (adjust source as needed)
sudo ufw allow from <admin-network-cidr> to any port 22 proto tcp comment "SSH admin access"

# Enable UFW
sudo ufw --force enable
```

#### Software Requirements
- **GitHub Actions Runner**: Latest stable version from https://github.com/actions/runner/releases
- **Container Runtime**: Docker 20.10+ or Podman 4.0+ (for job isolation)
- **Python**: 3.8+ (for runner-exporter monitoring script)
- **Systemd**: For runner service management
- **User Account**: `actions-runner` user with limited privileges

#### Security Configuration
- Runner user: `actions-runner` (no interactive shell, no sudo)
- SSH access: Key-based authentication only (no password auth)
- Service isolation: Systemd hardening (PrivateTmp, ProtectSystem, etc.)
- Secret handling: GitHub Secrets only (no local secret files)
- Process limits: Configure cgroups/resource limits if needed

### T042b: production-runner-02.paws360.local (Secondary Runner)

#### Host Specifications
**Same as production-runner-01** with the following differences:
- **Hostname**: `production-runner-02.paws360.local`
- **Role**: Secondary/failover production deployment runner
- **Runner Labels**: `[self-hosted, production, secondary]` (vs. `primary`)

#### Network Configuration
- **DNS Required**: A record for `production-runner-02.paws360.local`
- **IP Address**: Different IP from production-runner-01 (from production range)
- **All other network requirements same as production-runner-01**

#### Failover Behavior
- **Primary Preferred**: GitHub Actions runner selection prefers primary label
- **Automatic Failover**: If primary offline/unhealthy, jobs route to secondary
- **Hot Standby**: Secondary runner always online and ready (not cold spare)
- **Monitored Separately**: Both runners have independent metrics/alerts

### T042c: Monitoring Configuration

#### Prometheus Scrape Configuration
Location: `/etc/prometheus/prometheus.yml` on Prometheus host (192.168.0.200)

```yaml
scrape_configs:
  - job_name: 'github-runner-health'
    scrape_interval: 15s
    scrape_timeout: 10s
    honor_labels: true
    static_configs:
      - targets:
          - 'production-runner-01.paws360.local:9101'
        labels:
          service: 'github-runner'
          environment: 'production'
          runner_name: 'production-runner-01'
          authorized_for_prod: 'true'
      - targets:
          - 'production-runner-02.paws360.local:9101'
        labels:
          service: 'github-runner'
          environment: 'production'
          runner_name: 'production-runner-02'
          authorized_for_prod: 'true'
```

#### Grafana Dashboard
- **Source**: `monitoring/grafana/dashboards/runner-health.json`
- **Deployment**: Via Grafana API or Ansible role `cloudalchemy.grafana`
- **Dashboard UID**: `github-runner-health`
- **Panels**: Runner status, CPU usage, memory usage, disk usage, health timeline

#### Prometheus Alert Rules
- **Source**: `infrastructure/ansible/roles/cloudalchemy.prometheus/files/runner-alerts.yml`
- **Alert Group**: `github_runner_health`
- **Alerts**:
  - `GitHubRunnerOffline`: Critical, fires after 5min offline (primary) or 10min (secondary)
  - `GitHubRunnerHighCPU`: Warning, fires when CPU >90% for 10min
  - `GitHubRunnerHighMemory`: Warning, fires when memory >85% for 10min
  - `GitHubRunnerHighDisk`: Warning, fires when disk >85% for 15min
- **Routing**: All alerts to `oncall-sre` receiver

#### Runner-Exporter Service
- **Binary**: `scripts/monitoring/runner-exporter.py`
- **Port**: 9101/tcp
- **Metrics Exposed**:
  - `runner_status` (1=online, 0=offline)
  - `runner_cpu_usage_percent` (0-100)
  - `runner_memory_usage_percent` (0-100)
  - `runner_disk_usage_percent` (0-100)
- **Environment Variables**:
  - `ENVIRONMENT=production`
  - `AUTHORIZED_FOR_PROD=true`
  - `RUNNER_NAME=production-runner-01` (or production-runner-02)

### T042d: Validation and Sign-off

#### Pre-Production Validation Tests
Execute these tests before production deployment authorization:

1. **Runner Registration**: Verify both runners visible in GitHub
   ```bash
   gh api /repos/rmnanney/PAWS360/actions/runners | \
     jq '.runners[] | select(.labels[].name == "production")'
   ```

2. **Service Health**: Verify systemd services active
   ```bash
   ssh production-runner-01 'systemctl is-active actions.runner.*'
   ssh production-runner-02 'systemctl is-active actions.runner.*'
   ```

3. **Network Connectivity**: Verify runners can reach production endpoints
   ```bash
   # Test from each runner to production application servers
   ssh production-runner-01 'curl -s -o /dev/null -w "%{http_code}" https://production.paws360.local/health'
   ```

4. **Monitoring Integration**: Verify metrics collection
   ```bash
   # Query Prometheus for runner metrics
   curl -s "http://192.168.0.200:9090/api/v1/query?query=runner_status{environment='production'}" | jq
   ```

5. **Alert Configuration**: Verify alerts loaded
   ```bash
   curl -s "http://192.168.0.200:9090/api/v1/rules" | \
     jq '.data.groups[] | select(.name == "github_runner_health")'
   ```

6. **Failover Test**: Verify secondary takeover
   ```bash
   # Stop primary runner service
   ssh production-runner-01 'sudo systemctl stop actions.runner.*'
   
   # Trigger test workflow, verify it runs on secondary
   gh workflow run ci.yml --ref 001-github-runner-deploy
   
   # Restart primary
   ssh production-runner-01 'sudo systemctl start actions.runner.*'
   ```

7. **Security Review**: Verify hardening
   - Runner user privileges (no unnecessary sudo)
   - SSH access controls (key-based only)
   - Firewall rules (minimal required ports)
   - Secret handling (GitHub Secrets only)

8. **Test Scenarios**: Run automated test suite
   ```bash
   # Execute all User Story 1 test scenarios against production runners
   export FORCE_LIVE=true
   bash tests/ci/run-all-tests.sh
   ```

#### SRE Sign-off Requirements
Document the following in `specs/001-github-runner-deploy/production-runner-signoff.md`:

- [ ] Infrastructure provisioned (both runners)
- [ ] Network/DNS configuration complete
- [ ] Monitoring deployed and operational
- [ ] All validation tests passed
- [ ] Security review completed
- [ ] Failover behavior verified
- [ ] Runbooks reviewed and accessible
- [ ] SRE team approval signatures

## Ansible Inventory Structure

### File: `infrastructure/ansible/inventories/runners/hosts`

```ini
[github_runners:children]
github_runners_staging
github_runners_production

[github_runners_staging]
dell-r640-01 ansible_host=192.168.0.51 ansible_user=ryan runner_name=dell-r640-01-runner runner_labels='["self-hosted","Linux","X64","staging","primary"]' environment=staging authorized_for_prod=false

[github_runners_production]
production-runner-01 ansible_host=<IP_TO_BE_ASSIGNED> ansible_user=actions-runner runner_name=production-runner-01 runner_labels='["self-hosted","production","primary"]' environment=production authorized_for_prod=true
production-runner-02 ansible_host=<IP_TO_BE_ASSIGNED> ansible_user=actions-runner runner_name=production-runner-02 runner_labels='["self-hosted","production","secondary"]' environment=production authorized_for_prod=true

[github_runners:vars]
runner_exporter_port=9101
prometheus_host=192.168.0.200
github_repository=rmnanney/PAWS360
```

## Provisioning Playbooks

All Ansible playbooks are already created and tested in staging:

1. **Runner Installation**: `infrastructure/ansible/playbooks/provision-github-runner.yml`
   - Installs GitHub Actions runner software
   - Registers runner with GitHub
   - Configures systemd service
   - Sets up runner-exporter monitoring

2. **Monitoring Deployment**: `infrastructure/ansible/playbooks/deploy-runner-monitoring.yml`
   - Deploys runner-exporter service
   - Configures Prometheus scraping
   - Deploys Grafana dashboard
   - Configures alert rules

3. **Validation**: `tests/ci/validate-staging-runner.sh`
   - Can be adapted for production validation
   - Tests runner registration, service status, metrics, alerts

## Deployment Procedure

Once infrastructure is provisioned, execute these steps:

### Step 1: Provision Primary Runner (T042a)
```bash
# Add host to Ansible inventory (update IP address)
vim infrastructure/ansible/inventories/runners/hosts

# Run provisioning playbook
ansible-playbook -i infrastructure/ansible/inventories/runners/hosts \
  infrastructure/ansible/playbooks/provision-github-runner.yml \
  -l production-runner-01

# Verify runner online
gh api /repos/rmnanney/PAWS360/actions/runners | \
  jq '.runners[] | select(.name == "production-runner-01")'
```

### Step 2: Provision Secondary Runner (T042b)
```bash
# Add host to Ansible inventory (update IP address)
vim infrastructure/ansible/inventories/runners/hosts

# Run provisioning playbook
ansible-playbook -i infrastructure/ansible/inventories/runners/hosts \
  infrastructure/ansible/playbooks/provision-github-runner.yml \
  -l production-runner-02

# Verify runner online
gh api /repos/rmnanney/PAWS360/actions/runners | \
  jq '.runners[] | select(.name == "production-runner-02")'
```

### Step 3: Deploy Monitoring (T042c)
```bash
# Deploy monitoring to both runners
ansible-playbook -i infrastructure/ansible/inventories/runners/hosts \
  infrastructure/ansible/playbooks/deploy-runner-monitoring.yml \
  -l github_runners_production

# Verify metrics endpoints
curl http://production-runner-01.paws360.local:9101/metrics
curl http://production-runner-02.paws360.local:9101/metrics

# Verify Prometheus scraping
curl -s "http://192.168.0.200:9090/api/v1/targets" | \
  jq '.data.activeTargets[] | select(.labels.job == "github-runner-health")'
```

### Step 4: Validation and Sign-off (T042d)
```bash
# Run all validation tests (see T042d section above)
# Document results in production-runner-signoff.md
# Obtain SRE team approval
```

## Decision Points for Infrastructure Team

### Decision 1: Infrastructure Platform
- **Option A**: Provision new VMs on existing hypervisor (Proxmox/VMware/KVM)
- **Option B**: Provision new physical hosts
- **Option C**: Repurpose existing infrastructure (if available and appropriate)

**Recommendation**: Option A (VMs) for flexibility and resource efficiency

### Decision 2: IP Addressing
- **Required**: 2 IP addresses from production IP range
- **DNS Zone**: paws360.local domain
- **Subnet**: Must be routable to production environment endpoints

**Action Required**: Network team to assign IPs and configure DNS

### Decision 3: Security Posture
- **Isolation Level**: Runner-specific subnet or integrated with production?
- **Access Controls**: Jump host required or direct SSH?
- **Egress Filtering**: Allow all outbound or restrict to known endpoints?

**Recommendation**: Follow existing production security policies

### Decision 4: Resource Allocation
- **Immediate Needs**: 2 runners (primary + secondary) for MVP
- **Future Growth**: May need additional runners for concurrency (US2/US3)
- **Overprovisioning**: Consider sizing for future growth

**Recommendation**: Start with specified minimum specs, monitor usage, scale as needed

## Risk Assessment

### Risk 1: Infrastructure Provisioning Delays
- **Impact**: Blocks US1 completion (4 tasks remaining)
- **Mitigation**: All code is complete; infrastructure can be provisioned anytime
- **Workaround**: Continue with US2/US3 implementation (diagnostics, safeguards)

### Risk 2: Network Configuration Issues
- **Impact**: Runners cannot reach production endpoints
- **Mitigation**: Validate connectivity during T042d validation phase
- **Rollback**: Runners can be removed from GitHub if issues detected

### Risk 3: Resource Contention
- **Impact**: Concurrent deployments compete for runner resources
- **Mitigation**: Concurrency control enforced in workflow (T026)
- **Monitoring**: CPU/memory alerts configured (T016)

## Next Steps

### For Infrastructure/Operations Team:
1. Review infrastructure requirements in this document
2. Provision VMs/hosts for production-runner-01 and production-runner-02
3. Assign IP addresses and configure DNS (paws360.local zone)
4. Configure network/firewall rules per specifications
5. Notify development team when infrastructure is ready

### For Development Team:
1. Wait for infrastructure provisioning (blocked on ops team)
2. Update Ansible inventory with assigned IP addresses
3. Execute provisioning playbooks (T042a, T042b)
4. Deploy monitoring (T042c)
5. Run validation tests and obtain sign-off (T042d)

### For SRE Team:
1. Review validation requirements in T042d section
2. Participate in failover testing
3. Review and approve runbooks
4. Sign off on production runner deployment authorization

## References

- **User Story**: `specs/001-github-runner-deploy/spec.md` (INFRA-473)
- **Implementation Plan**: `specs/001-github-runner-deploy/plan.md`
- **Task List**: `specs/001-github-runner-deploy/tasks.md`
- **Staging Validation**: `tests/ci/validate-staging-runner.sh`
- **Runner Context**: `contexts/infrastructure/github-runners.md`
- **Monitoring Context**: `contexts/infrastructure/monitoring-stack.md`

## Approval

- **Infrastructure Requirements Defined By**: GitHub Copilot (Implementation Agent)
- **Date**: 2025-12-10
- **Infrastructure Team Review**: [ ] Pending
- **Network Team Review**: [ ] Pending
- **Security Team Review**: [ ] Pending
- **SRE Team Approval**: [ ] Pending

---

**Note**: This document serves as the handoff specification for infrastructure provisioning. Once infrastructure is ready, tasks T042a-d can be executed to complete User Story 1 (INFRA-473).
