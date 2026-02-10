# GitLab Runner Operations Guide

Operational guide for managing GitLab Runners on Proxmox infrastructure.

## Table of Contents

- [Provisioning](#provisioning)
- [Deployment Runner Security](#deployment-runner-security)
- [Monitoring](#monitoring)
- [Lifecycle Management](#lifecycle-management)
- [Troubleshooting](#troubleshooting)
- [Scaling](#scaling)

## Provisioning

### Initial Runner Provisioning

1. **Prepare configuration**:
   ```bash
   cd infrastructure/ansible
   
   # Edit inventory
   vim inventories/runners/hosts
   
   # Edit variables
   vim group_vars/runners.yml
   ```

2. **Configure secrets** (Ansible Vault):
   ```bash
   # Create vault file
   ansible-vault create group_vars/vault.yml
   
   # Add registration token
   # vault_gitlab_registration_token: "REPLACE_ME"
   ```

3. **Run provisioning playbook**:
   ```bash
   # Existing host
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass
   
   # New VM on Proxmox
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass --extra-vars "create_vm=true"
   ```

4. **Verify installation**:
   ```bash
   ssh root@gitlab-runner-01
   gitlab-runner list
   gitlab-runner verify
   systemctl status gitlab-runner
   ```

### Re-provisioning

To completely rebuild a runner:

```bash
ansible-playbook -i inventories/runners playbooks/reprovision-gitlab-runner.yml --ask-vault-pass
```

## Deployment Runner Security

### Restricted Tags

Deployment runners MUST use specific tags to control job execution:

```yaml
# group_vars/runners.yml
runner_tags: "proxmox-local,deploy,restricted"
```

Only jobs explicitly tagged with `proxmox-local` and `deploy` will run on this runner.

### Network Access Controls

**Principle**: Deployment runners should have **minimal** network access.

#### Allowed Outbound Connections

- **GitLab API** (HTTPS 443): Required for runner communication
- **NTP** (UDP 123): Time synchronization
- **Internal deployment targets**: Specific services only

#### Firewall Configuration

Configured automatically in `tasks/configure-firewall.yml`:

```yaml
# Outbound: HTTPS (443), NTP (123), SSH (22 - optional)
# Inbound: SSH (22), monitoring (9100, 8080)
```

Manual verification:
```bash
# Check UFW rules
ufw status verbose

# Check iptables
iptables -L -n -v
```

### Secret Handling Best Practices

1. **Never hardcode secrets** in repository or playbooks
2. **Use Ansible Vault** for registration tokens
3. **Use GitLab CI/CD variables** for deployment credentials:
   - Mark as **Protected** (only runs on protected branches)
   - Mark as **Masked** (hidden in job logs)
4. **Rotate secrets regularly** (quarterly minimum)

#### Secret Rotation Procedure

```bash
# 1. Generate new registration token in GitLab
# 2. Update Ansible Vault
ansible-vault edit group_vars/vault.yml

# 3. Re-register runner
ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass --tags register

# 4. Verify new registration
ssh root@gitlab-runner-01 gitlab-runner verify
```

### Restricted Runner Configuration

```yaml
# config.toml restrictions
runner_docker_allowed_images:
  - "alpine:*"
  - "ubuntu:22.04"
  - "your-registry.com/deploy-image:*"

runner_docker_allowed_services:
  - "postgres:14"
  - "redis:7"

# Disable running untagged jobs
run_untagged: false

# Restrict to specific projects/groups
locked: true
access_level: "not_protected"  # or "ref_protected" for protected branches only
```

### Privileged Mode Considerations

**Warning**: `privileged: true` grants containers extensive host access.

**When to use**:
- Docker-in-Docker (DinD) workflows required
- Building container images in CI

**Alternatives**:
- **Kaniko**: Build images without privileged mode
- **Buildah**: Rootless container builds
- **Separate build runner**: Dedicated runner for image builds

**If privileged mode is required**:
1. Document the justification
2. Use strict `allowed_images` whitelist
3. Monitor for abnormal container behavior
4. Consider rootless Docker

```yaml
# Rootless Docker alternative (Ubuntu 20.04+)
# See: https://docs.docker.com/engine/security/rootless/
```

## Monitoring

### Metrics Endpoints

- **Node Exporter** (port 9100): System metrics
- **cAdvisor** (port 8080): Container metrics
- **GitLab Runner** (port 9252): Runner metrics (requires config)

### Prometheus Configuration

Add scrape targets to `monitoring/prometheus/gitlab-runner-targets.yml`:

```yaml
- job_name: 'gitlab-runner-node'
  static_configs:
    - targets: ['gitlab-runner-01:9100']
      labels:
        runner: 'gitlab-runner-01'
        role: 'ci'

- job_name: 'gitlab-runner-cadvisor'
  static_configs:
    - targets: ['gitlab-runner-01:8080']
      labels:
        runner: 'gitlab-runner-01'
```

Reload Prometheus:
```bash
curl -X POST http://prometheus:9090/-/reload
```

### Grafana Dashboard

Import dashboard from `monitoring/dashboards/gitlab-runner-dashboard.json`:

1. Navigate to Grafana → Dashboards → Import
2. Upload JSON file
3. Select Prometheus data source
4. View runner metrics

### Alerts

Configured in `monitoring/prometheus/alerts/gitlab-runner.yml`:

- **RunnerDown**: Runner not responding for 5 minutes
- **HighDiskUsage**: Disk usage > 85%
- **JobQueueBacklog**: Jobs queued for > 10 minutes

Configure alert notifications:
```bash
# Edit Prometheus alertmanager configuration
vim monitoring/prometheus/alertmanager.yml

# Add notification receivers (email, Slack, PagerDuty)
```

## Lifecycle Management

### Manual Restart

```bash
# SSH to runner host
ssh root@gitlab-runner-01

# Restart service
systemctl restart gitlab-runner

# Verify status
systemctl status gitlab-runner
gitlab-runner verify
```

### Automated Restart (Ansible)

```bash
cd infrastructure/ansible
ansible runners -i inventories/runners -m systemd -a "name=gitlab-runner state=restarted" --become
```

### Configuration Updates

```bash
# Edit configuration
vim group_vars/runners.yml

# Re-run playbook (idempotent)
ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass --tags config

# Verify changes
ssh root@gitlab-runner-01 cat /etc/gitlab-runner/config.toml
```

### Backup Configuration

```bash
# Backup config.toml
ssh root@gitlab-runner-01 "sudo cp /etc/gitlab-runner/config.toml /root/config.toml.backup.$(date +%Y%m%d)"

# Backup to control host
scp root@gitlab-runner-01:/etc/gitlab-runner/config.toml backups/config.toml.$(date +%Y%m%d)
```

### Restore Configuration

```bash
# Restore from backup
scp backups/config.toml.20251201 root@gitlab-runner-01:/etc/gitlab-runner/config.toml

# Restart runner
ssh root@gitlab-runner-01 systemctl restart gitlab-runner
```

## Troubleshooting

### Runner Not Picking Up Jobs

**Symptoms**: Jobs stuck in "pending" state

**Diagnosis**:
```bash
ssh root@gitlab-runner-01

# Check runner status
gitlab-runner verify

# Check logs
journalctl -u gitlab-runner -f

# Check Docker
docker info
docker ps
```

**Solutions**:
1. Verify runner tags match job tags
2. Check runner is registered: `gitlab-runner list`
3. Verify network connectivity: `curl -I https://gitlab.example.com`
4. Check runner capacity: `gitlab-runner status`

### Docker Permission Denied

**Symptoms**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**:
```bash
# Add gitlab-runner to docker group
usermod -aG docker gitlab-runner

# Restart service
systemctl restart gitlab-runner
```

### High Disk Usage

**Symptoms**: Disk usage > 85%, jobs failing with "no space left on device"

**Diagnosis**:
```bash
# Check disk usage
df -h

# Check Docker disk usage
docker system df

# Find large directories
du -sh /var/lib/docker/* | sort -hr | head -10
```

**Solutions**:
```bash
# Clean Docker images/containers
docker system prune -a --volumes

# Clean GitLab Runner cache
rm -rf /var/lib/gitlab-runner/cache/*

# Increase disk size (Proxmox)
# See Proxmox documentation for VM disk expansion
```

### Network Connectivity Issues

**Symptoms**: Jobs failing with connection timeouts

**Diagnosis**:
```bash
# Test GitLab connectivity
curl -I https://gitlab.example.com

# Check DNS
nslookup gitlab.example.com

# Check routes
ip route

# Test deployment targets
curl -I https://internal-app.example.com
```

**Solutions**:
1. Verify firewall rules: `ufw status` or `iptables -L`
2. Check DNS configuration: `/etc/resolv.conf`
3. Verify NTP synchronization: `timedatectl status`

### Runner Registration Failed

**Symptoms**: `registration failed` error during provisioning

**Diagnosis**:
```bash
# Test registration manually
gitlab-runner register --url https://gitlab.example.com --registration-token REPLACE_ME

# Check GitLab API
curl -I https://gitlab.example.com/api/v4/runners
```

**Solutions**:
1. Verify registration token is correct
2. Check GitLab URL is accessible
3. Ensure runner version is compatible with GitLab version
4. Check firewall allows HTTPS (443) outbound

## Scaling

### Adding Additional Runners

1. **Update inventory**:
   ```ini
   # inventories/runners/hosts
   [runners]
   gitlab-runner-01 ansible_host=192.168.1.100
   gitlab-runner-02 ansible_host=192.168.1.101
   gitlab-runner-03 ansible_host=192.168.1.102
   ```

2. **Configure per-host variables** (optional):
   ```yaml
   # inventories/runners/host_vars/gitlab-runner-02.yml
   runner_tags: "proxmox-local,build,java"
   runner_concurrent: 2
   ```

3. **Provision new runners**:
   ```bash
   # Provision specific host
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --limit gitlab-runner-02 --ask-vault-pass
   
   # Provision all new runners
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass
   ```

### Specialized Runner Roles

**Build Runners** (general CI/CD):
```yaml
runner_tags: "proxmox-local,build,ci"
runner_concurrent: 2
runner_docker_privileged: false
```

**Deployment Runners** (restricted access):
```yaml
runner_tags: "proxmox-local,deploy,restricted"
runner_concurrent: 1
runner_docker_privileged: false
run_untagged: false
locked: true
```

**Image Build Runners** (Docker-in-Docker):
```yaml
runner_tags: "proxmox-local,docker,build-images"
runner_concurrent: 1
runner_docker_privileged: true
runner_docker_allowed_images: ["docker:*-dind"]
```

### Load Balancing

GitLab automatically distributes jobs across available runners with matching tags.

**Optimization**:
- Use `concurrent` setting to control parallel jobs per runner
- Monitor runner utilization in GitLab Admin → Runners
- Add runners when queue times exceed SLA

### Runner Groups (GitLab Premium)

Organize runners by environment or purpose:
- `production-runners`: Production deployments only
- `development-runners`: Dev/test builds
- `build-runners`: General CI builds

Configure in GitLab: Admin → Runners → Create Runner Group

## Maintenance Schedule

### Daily
- Monitor runner health in Grafana dashboard
- Check job queue times in GitLab

### Weekly
- Review runner logs for errors: `journalctl -u gitlab-runner --since "1 week ago"`
- Clean Docker cache: `docker system prune -f`

### Monthly
- Check disk usage and clean if > 70%
- Review and update `allowed_images` list
- Verify backup configuration files

### Quarterly
- Rotate registration tokens
- Update GitLab Runner to latest version
- Review and update firewall rules
- Audit runner access logs

## Support

For issues or questions:
- Infrastructure team: #infrastructure-support
- GitLab documentation: https://docs.gitlab.com/runner/
- JIRA: Create ticket with label `gitlab-runner`
