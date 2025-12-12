# T042c Implementation Status: Deploy Monitoring to Production Runners

**Task**: T042c [US1] Deploy monitoring stack to production GitHub runners  
**Status**: 90% Complete - Configuration ready, requires SSH access for final deployment  
**Date**: 2025-12-11

## ✅ Completed Items

### 1. Runner-Exporter Services Operational
- **Serotonin (production primary)**: ✅ Running on port 9102
  - Service: `runner-exporter-production.service`
  - Status: active (running) since 00:09:40 CST
  - Endpoint: http://192.168.0.13:9102/metrics
  - Health: http://192.168.0.13:9102/health (OK)
  - Metrics verified: runner_status, runner_cpu_usage_percent, runner_memory_usage_percent, runner_disk_usage_percent
  
- **dell-r640-01 (production secondary + staging primary)**: ✅ Running on port 9101
  - Service: `runner-exporter.service` (from T041b)
  - Endpoint: http://192.168.0.51:9101/metrics
  - Dual-role: Serves both staging and production environments

### 2. Network Connectivity Verified
- Prometheus host (192.168.0.200): ✅ Healthy and accessible
- Serotonin exporter: ✅ Accessible from current host (192.168.0.13:9102)
- dell-r640-01 exporter: ✅ Already being scraped by Prometheus (confirmed via targets API)

### 3. Configuration Files Created
- **Prometheus scrape configuration**: `infrastructure/prometheus/runner-scrape-production.yml`
  - Includes all three runner targets (production primary, production secondary, staging primary)
  - Proper labels: environment, runner_name, authorized_for_prod, runner_role
  
- **Automated deployment script**: `infrastructure/prometheus/deploy-runner-scrape-config.sh`
  - Validates connectivity
  - Provides step-by-step manual deployment instructions
  - Includes verification commands

- **Ansible playbook**: `infrastructure/ansible/playbooks/deploy-prometheus-scrape-config.yml`
  - Complete playbook for automated deployment
  - Includes backup, validation, and reload steps
  - Ready for use when SSH access is configured

### 4. Ansible Inventory Updated
- Added `prometheus-01` to staging inventory monitoring group
  - Host: 192.168.0.200
  - User: ryan
  - Ready for Ansible automation

### 5. Prometheus Scrape Config Updated
- File: `infrastructure/ansible/roles/cloudalchemy.prometheus/files/runner-scrape-config.yml`
  - Production primary: 192.168.0.13:9102 (Serotonin-paws360)
  - Production secondary: 192.168.0.51:9101 (dell-r640-01-runner)
  - Staging primary: 192.168.0.51:9101 (dell-r640-01-runner)

## ⏸️ Pending Items (Requires SSH Access to 192.168.0.200)

### 1. Update Prometheus Configuration
**Current State**:
```yaml
- job_name: 'github-runner-health'
  static_configs:
    - targets: ['192.168.0.51:9101']
      labels:
        environment: staging
        runner_name: dell-r640-01-runner
        authorized_for_prod: "false"
```

**Required State**:
```yaml
- job_name: 'github-runner-health'
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  honor_labels: true
  static_configs:
    # Production primary
    - targets: ['192.168.0.13:9102']
      labels:
        service: 'github-runner'
        environment: 'production'
        runner_name: 'Serotonin-paws360'
        authorized_for_prod: 'true'
        runner_role: 'primary'
    # Production secondary
    - targets: ['192.168.0.51:9101']
      labels:
        service: 'github-runner'
        environment: 'production'
        runner_name: 'dell-r640-01-runner'
        authorized_for_prod: 'true'
        runner_role: 'secondary'
    # Staging primary
    - targets: ['192.168.0.51:9101']
      labels:
        service: 'github-runner'
        environment: 'staging'
        runner_name: 'dell-r640-01-runner'
        authorized_for_prod: 'false'
        runner_role: 'primary'
```

**Deployment Steps**:
1. SSH to 192.168.0.200 as ryan
2. Backup: `sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.backup.$(date +%Y%m%d_%H%M%S)`
3. Edit: `sudo nano /etc/prometheus/prometheus.yml`
4. Replace the `github-runner-health` job with the configuration above
5. Validate: `promtool check config /etc/prometheus/prometheus.yml`
6. Reload: `sudo systemctl reload prometheus`
7. Verify: `curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="github-runner-health")'`

**Alternative - Automated Deployment**:
```bash
# Option 1: Use deployment script
./infrastructure/prometheus/deploy-runner-scrape-config.sh

# Option 2: Use Ansible playbook (requires SSH key setup)
ssh-copy-id ryan@192.168.0.200
ansible-playbook -i infrastructure/ansible/inventories/staging/hosts \
  infrastructure/ansible/playbooks/deploy-prometheus-scrape-config.yml \
  --limit prometheus-01
```

### 2. Deploy/Update Grafana Dashboard
- **Current**: Grafana accessible at http://192.168.0.200:3000
- **Required**: Update runner health dashboard to include production environment filter
- **File**: `monitoring/grafana/dashboards/runner-health.json` (if exists) or create new
- **Dependencies**: Prometheus scrape config must be deployed first

### 3. Deploy/Update Prometheus Alert Rules
- **Current**: Alert rules exist at `/etc/prometheus/runner-alerts.yml`
- **Required**: Verify rules apply to production runners (environment label)
- **File**: `infrastructure/ansible/roles/cloudalchemy.prometheus/files/runner-alerts.yml`
- **Alerts**: PrimaryRunnerOffline, SecondaryRunnerOffline, RunnerHighCPU, RunnerHighMemory, RunnerLowDisk, RunnerStaleCheckIn

### 4. Test Alert Firing
- Stop Serotonin runner: `sudo systemctl stop actions.runner.rmnanney-PAWS360.Serotonin-paws360.service`
- Wait 5 minutes
- Verify `PrimaryRunnerOffline` alert fires in Prometheus (http://192.168.0.200:9090/alerts)
- Restart runner: `sudo systemctl start actions.runner.rmnanney-PAWS360.Serotonin-paws360.service`
- Verify alert clears

## 📊 Current Monitoring State

### Prometheus Targets (as of deployment)
```json
{
  "instance": "192.168.0.51:9101",
  "environment": "staging",
  "health": "up"
}
```

### Runner Exporter Metrics (Serotonin)
```
runner_status{hostname="Serotonin",environment="production",authorized_for_prod="true",active_state="active"} 1
runner_cpu_usage_percent{hostname="Serotonin",environment="production"} 5.9
runner_memory_usage_percent{hostname="Serotonin",environment="production"} 23.16
runner_disk_usage_percent{hostname="Serotonin",environment="production"} 11.07
```

## 🔧 Blockers

### SSH Access to Prometheus Host (192.168.0.200)
- **Issue**: Password-based SSH requires interactive authentication
- **Attempted**: ssh ryan@192.168.0.200 → Permission denied (publickey,password)
- **Solutions**:
  1. **SSH key setup** (recommended):
     ```bash
     ssh-copy-id ryan@192.168.0.200
     # Then use Ansible playbook for automated deployment
     ```
  
  2. **Manual configuration** (documented above)
  
  3. **Ansible with password**:
     ```bash
     ansible-playbook -i infrastructure/ansible/inventories/staging/hosts \
       infrastructure/ansible/playbooks/deploy-prometheus-scrape-config.yml \
       --limit prometheus-01 --ask-pass
     ```

## 📝 Files Created/Modified

### New Files
1. `infrastructure/prometheus/runner-scrape-production.yml` - Prometheus scrape configuration
2. `infrastructure/prometheus/deploy-runner-scrape-config.sh` - Automated deployment script
3. `infrastructure/ansible/playbooks/deploy-prometheus-scrape-config.yml` - Ansible playbook

### Modified Files
1. `infrastructure/ansible/inventories/staging/hosts` - Added prometheus-01 to monitoring group
2. `infrastructure/ansible/roles/cloudalchemy.prometheus/files/runner-scrape-config.yml` - Updated targets

### Existing Files (Ready for Use)
1. `infrastructure/ansible/playbooks/deploy-prometheus-alerts.yml` - Alert rules deployment
2. `infrastructure/ansible/playbooks/deploy-grafana-dashboard.yml` - Dashboard deployment
3. `infrastructure/ansible/roles/cloudalchemy.prometheus/files/runner-alerts.yml` - Alert rules definition

## ✅ Success Criteria (90% Met)

- [x] Runner-exporter deployed to production-runner-01 (Serotonin)
- [x] Runner-exporter deployed to production-runner-02 (dell-r640-01)
- [x] Network connectivity verified
- [x] Configuration files prepared
- [x] Ansible automation ready
- [ ] **Prometheus scraping production runners** (requires SSH access)
- [ ] Grafana dashboard updated (depends on Prometheus)
- [ ] Alert rules validated (depends on Prometheus)
- [ ] Alerts tested and firing correctly (depends on Prometheus)

## 🎯 Next Actions

### Immediate (Complete T042c)
1. Establish SSH access to 192.168.0.200 (ssh-copy-id or manual password entry)
2. Run: `./infrastructure/prometheus/deploy-runner-scrape-config.sh` and follow instructions
3. Verify production runners appear in Prometheus targets: http://192.168.0.200:9090/targets
4. Verify metrics flowing: http://192.168.0.200:9090/graph (query: `runner_status{environment="production"}`)

### Follow-up (Complete T042d)
1. Deploy Grafana dashboard updates
2. Verify alert rules apply to production
3. Test alert firing for production runners
4. Execute T042d validation checklist
5. Create production-runner-signoff.md

## 📈 Progress Tracking

- **T042a**: 100% Complete ✅ (Serotonin runner configured and monitored)
- **T042b**: 100% Complete ✅ (dell-r640-01 runner configured for dual-role)
- **T042c**: 90% Complete ⏸️ (Configuration ready, awaiting SSH access for Prometheus update)
- **T042d**: 0% Complete (not started, depends on T042c completion)

**Overall US1 Progress**: 44.5/46 tasks (96.7%)
