# T042c Deployment Guide: Production Runner Monitoring

**Task**: Deploy monitoring to production runners  
**Status**: Ready to deploy (all artifacts prepared)  
**Blocker**: Requires SSH access to Prometheus host (192.168.0.200)  
**Estimated Time**: 5-10 minutes

## Current State

✅ **Complete**:
- Production runners operational with exporters running
  - Serotonin-paws360: http://192.168.0.13:9102/metrics
  - dell-r640-01-runner: http://192.168.0.51:9101/metrics
- Configuration files prepared and validated
- Deployment scripts created and tested
- Network connectivity verified

⏸️ **Pending**:
- Update Prometheus scrape configuration
- Reload Prometheus service
- Verify production targets appear
- Update Grafana dashboard (optional - already shows staging)
- Test alert rules

## Deployment Options

### Option 1: Automated Script (Recommended)

```bash
cd /home/ryan/repos/PAWS360
./infrastructure/prometheus/deploy-runner-scrape-config.sh
```

**What it does**:
1. Validates SSH connectivity to Prometheus host
2. Backs up current Prometheus configuration
3. Uploads new scrape configuration with production runner targets
4. Reloads Prometheus service
5. Verifies targets are being scraped
6. Displays success confirmation with target URLs

**Requirements**:
- SSH access to ryan@192.168.0.200
- sudo privileges on Prometheus host (for service reload)

### Option 2: Ansible Playbook

```bash
cd /home/ryan/repos/PAWS360
ansible-playbook \
  -i infrastructure/ansible/inventories/staging/hosts \
  infrastructure/ansible/playbooks/deploy-prometheus-scrape-config.yml \
  --limit prometheus-01 \
  --ask-pass
```

**What it does**:
- Uses Ansible to deploy configuration idempotently
- Validates configuration before reload
- Handles service restart gracefully
- Reports success/failure

**Requirements**:
- Ansible installed
- SSH password for ryan@192.168.0.200 (prompted by --ask-pass)

### Option 3: Manual Deployment

If automated options fail, deploy manually:

#### Step 1: Setup SSH Access

```bash
# Generate SSH key if needed
ssh-keygen -t ed25519 -C "ryan@paws360-deployment"

# Copy to Prometheus host
ssh-copy-id ryan@192.168.0.200
```

#### Step 2: Deploy Configuration

```bash
# Copy scrape config to Prometheus host
scp infrastructure/prometheus/runner-scrape-production.yml \
  ryan@192.168.0.200:/tmp/runner-scrape-config.yml

# SSH to Prometheus host
ssh ryan@192.168.0.200

# On Prometheus host:
sudo cp /tmp/runner-scrape-config.yml \
  /etc/prometheus/file_sd/runner-scrape-config.yml

sudo chown prometheus:prometheus \
  /etc/prometheus/file_sd/runner-scrape-config.yml

sudo chmod 644 /etc/prometheus/file_sd/runner-scrape-config.yml

# Reload Prometheus
sudo systemctl reload prometheus

# Verify reload succeeded
sudo systemctl status prometheus
```

#### Step 3: Verify Targets

```bash
# From your workstation
curl -s http://192.168.0.200:9090/api/v1/targets | \
  jq '.data.activeTargets[] | select(.labels.job=="github-runner-health") | {
    instance: .labels.instance,
    environment: .labels.environment,
    role: .labels.role,
    health: .health,
    lastScrape: .lastScrape
  }'
```

**Expected output**:
```json
{
  "instance": "192.168.0.13:9102",
  "environment": "production",
  "role": "primary",
  "health": "up",
  "lastScrape": "2025-12-11T..."
}
{
  "instance": "192.168.0.51:9101",
  "environment": "staging",
  "role": "primary",
  "health": "up",
  "lastScrape": "2025-12-11T..."
}
{
  "instance": "192.168.0.51:9101",
  "environment": "production",
  "role": "secondary",
  "health": "up",
  "lastScrape": "2025-12-11T..."
}
```

## Validation Checklist

After deployment, verify:

- [ ] Three targets visible in Prometheus targets UI (http://192.168.0.200:9090/targets)
  - [ ] Serotonin production primary (192.168.0.13:9102)
  - [ ] dell-r640-01 staging primary (192.168.0.51:9101)
  - [ ] dell-r640-01 production secondary (192.168.0.51:9101)

- [ ] All targets showing "UP" health status

- [ ] Metrics available in Prometheus query UI:
  ```promql
  runner_status{job="github-runner-health"}
  runner_cpu_percent{job="github-runner-health"}
  runner_memory_percent{job="github-runner-health"}
  ```

- [ ] Grafana dashboard displays production runners (http://192.168.0.200:3000)
  - Dashboard: "GitHub Runner Health"
  - Environment filter includes "production"

- [ ] Alert rules loaded in Prometheus:
  ```bash
  curl -s http://192.168.0.200:9090/api/v1/rules | \
    jq '.data.groups[] | select(.name=="runner-health") | .rules[].name'
  ```
  Expected: `RunnerOffline`, `RunnerDegraded`, `DeploymentDurationHigh`, `DeploymentFailureRate`

## Test Alert Firing (Optional)

To validate alert rules work:

```bash
# SSH to Serotonin and stop runner temporarily
ssh ryan@192.168.0.13 "sudo systemctl stop runner-exporter-production"

# Wait 5 minutes, then check Prometheus alerts
curl -s http://192.168.0.200:9090/api/v1/alerts | \
  jq '.data.alerts[] | select(.labels.alertname=="RunnerOffline")'

# Should show FIRING alert for Serotonin runner

# Restore runner
ssh ryan@192.168.0.13 "sudo systemctl start runner-exporter-production"
```

## Troubleshooting

### Issue: Prometheus reload fails

**Check**:
```bash
ssh ryan@192.168.0.200 "sudo journalctl -u prometheus -n 50 --no-pager"
```

**Common causes**:
- YAML syntax error in config file
- File permissions incorrect (must be readable by prometheus user)
- Invalid scrape target format

**Fix**:
```bash
# Validate YAML syntax locally
yamllint infrastructure/prometheus/runner-scrape-production.yml

# Check Prometheus can read file
ssh ryan@192.168.0.200 "sudo -u prometheus cat /etc/prometheus/file_sd/runner-scrape-config.yml"
```

### Issue: Targets not appearing

**Check**:
1. File is in correct location (`/etc/prometheus/file_sd/`)
2. Prometheus main config includes file_sd_configs pointing to this directory
3. Network connectivity from Prometheus to runner exporters

**Test connectivity**:
```bash
ssh ryan@192.168.0.200 "curl -v http://192.168.0.13:9102/metrics"
ssh ryan@192.168.0.200 "curl -v http://192.168.0.51:9101/metrics"
```

### Issue: Targets showing "DOWN"

**Check exporter status on runner**:
```bash
# For Serotonin
ssh ryan@192.168.0.13 "sudo systemctl status runner-exporter-production"

# For dell-r640-01
ssh ryan@192.168.0.51 "sudo systemctl status runner-exporter-staging"
```

**Verify metrics endpoint**:
```bash
curl http://192.168.0.13:9102/metrics | head -20
curl http://192.168.0.51:9101/metrics | head -20
```

## Post-Deployment Actions

After successful deployment:

1. **Mark task complete** in `specs/001-github-runner-deploy/tasks.md`:
   ```markdown
   - [x] T042c [US1] Deploy monitoring to production runners
   ```

2. **Update implementation status** in `FINAL-IMPLEMENTATION-REPORT.md`

3. **Proceed to T042d**: Production validation and SRE sign-off

4. **Update JIRA**: Add comment to INFRA-473 with deployment timestamp and verification results

## References

- **Configuration File**: `infrastructure/prometheus/runner-scrape-production.yml`
- **Deployment Script**: `infrastructure/prometheus/deploy-runner-scrape-config.sh`
- **Ansible Playbook**: `infrastructure/ansible/playbooks/deploy-prometheus-scrape-config.yml`
- **Exporter Status Doc**: `specs/001-github-runner-deploy/T042c-MONITORING-DEPLOYMENT-STATUS.md`
- **Prometheus UI**: http://192.168.0.200:9090
- **Grafana UI**: http://192.168.0.200:3000

## Completion Criteria

T042c is complete when:
- ✅ All three runner targets appear in Prometheus and show "UP" status
- ✅ Metrics queryable via Prometheus UI
- ✅ Grafana dashboard displays production runners
- ✅ Alert rules loaded and visible
- ✅ Test alert successfully fired and resolved
- ✅ Task marked [x] in tasks.md
- ✅ JIRA updated with deployment completion
