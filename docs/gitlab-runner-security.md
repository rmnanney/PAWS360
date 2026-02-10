# GitLab Runner Security Hardening Checklist

Security best practices and hardening measures for GitLab Runner on Proxmox.

## Overview

This document provides security guidelines for deploying and operating GitLab Runners in a production environment.

## Security Hardening Checklist

### Privileged Mode

- [ ] **Privileged mode justification documented**
  - Document why `privileged: true` is required (e.g., Docker-in-Docker)
  - Evaluate alternatives: Kaniko, Buildah, rootless Docker
  - If privileged mode is necessary, document the risk acceptance

**Current Configuration**:
```yaml
runner_docker_privileged: true  # Required for DinD workflows
```

**Justification**: Needed for building container images in CI pipelines. Consider Kaniko for production.

**Mitigation**: Use `allowed_images` restrictions (see below).

### Image Restrictions

- [ ] **Allowed images whitelist configured**
  - Define explicit list of trusted base images
  - Use specific tags instead of `latest` where possible
  - Regularly review and update whitelist

**Configuration**:
```yaml
# group_vars/runners.yml
runner_docker_allowed_images:
  - "alpine:3.18"
  - "ubuntu:22.04"
  - "node:18-alpine"
  - "python:3.11-slim"
  - "openjdk:17-slim"
  - "maven:3.9-openjdk-17"
  - "your-registry.com/approved-image:*"
```

**Best Practices**:
- Pin major versions (e.g., `node:18` not `node:latest`)
- Use minimal images (alpine, slim variants)
- Whitelist only necessary images
- Use private registry for custom images

### Service Restrictions

- [ ] **Allowed services whitelist configured**
  - Limit services to required dependencies only
  - Use specific versions

**Configuration**:
```yaml
# group_vars/runners.yml
runner_docker_allowed_services:
  - "docker:24-dind"
  - "postgres:15"
  - "redis:7"
  - "mysql:8"
```

### Network Segmentation

- [ ] **Runner hosts isolated in dedicated network segment**
  - Use separate VLAN for runner infrastructure
  - Implement network access controls

**Recommended Network Architecture**:
```
Internet
   ↓
[Firewall]
   ↓
[GitLab Server] ← HTTPS (443) ← [Runner Segment]
                                       ↓
                              [gitlab-runner-01]
                              [gitlab-runner-02]
                                       ↓
                            [Internal Services] (deployment targets)
```

**Access Control**:
- Outbound: GitLab HTTPS (443), NTP (123), package repos
- Inbound: SSH (22) from admin network only, monitoring (9100, 8080) from Prometheus
- Blocked: Direct internet access, unnecessary internal services

### Secret Management

- [ ] **Registration tokens stored securely**
  - Use Ansible Vault for tokens
  - Never commit tokens to version control
  - Implement token rotation schedule

**Ansible Vault Usage**:
```bash
# Create encrypted vault
ansible-vault create group_vars/vault.yml

# Add token
vault_gitlab_registration_token: "YOUR_TOKEN_HERE"

# Reference in group_vars/runners.yml
gitlab_registration_token: "{{ vault_gitlab_registration_token }}"
```

**GitLab CI/CD Variables**:
- Mark deployment credentials as **Protected** (protected branches only)
- Mark all secrets as **Masked** (hidden in logs)
- Use environment-specific variables (dev, staging, prod)

### Secret Rotation Schedule

- [ ] **Token rotation implemented**
  - Quarterly rotation minimum
  - After personnel changes
  - After suspected compromise

**Rotation Procedure**:
```bash
# 1. Generate new token in GitLab
# 2. Update Ansible Vault
ansible-vault edit group_vars/vault.yml

# 3. Re-register runners
ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --tags register --ask-vault-pass

# 4. Verify
ansible runners -i inventories/runners -m command -a "gitlab-runner verify" --become
```

### Runner Tags and Job Control

- [ ] **Tags restrict job execution**
  - Use specific tags (no `run-untagged`)
  - Different runners for different purposes

**Tag Strategy**:
```yaml
# Build runners
runner_tags: "proxmox-local,ci,build"
run_untagged: false

# Deployment runners (separate hosts)
runner_tags: "proxmox-local,deploy,production"
run_untagged: false
locked: true
```

### Access Control

- [ ] **SSH access restricted**
  - Key-based authentication only (no passwords)
  - Limited to admin users
  - SSH from admin network only

**SSH Hardening** (`/etc/ssh/sshd_config`):
```
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers admin deploy-user
```

- [ ] **Sudo access limited**
  - gitlab-runner user has no sudo access
  - Use Ansible for privileged operations

### Logging and Auditing

- [ ] **Centralized logging configured**
  - Forward runner logs to SIEM/log aggregator
  - Monitor for suspicious activity

**Log Forwarding** (example with rsyslog):
```
# /etc/rsyslog.d/gitlab-runner.conf
if $programname == 'gitlab-runner' then @@logserver.example.com:514
```

- [ ] **Audit logging enabled**
  - Track runner registration/unregistration
  - Monitor configuration changes
  - Alert on anomalous job patterns

### System Hardening

- [ ] **OS security updates automated**
  - Unattended upgrades configured
  - Security patches applied weekly

**Unattended Upgrades** (Ubuntu/Debian):
```bash
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

- [ ] **Firewall rules enforced**
  - UFW or iptables configured
  - Only necessary ports open

**Firewall Rules** (UFW):
```bash
# Inbound
ufw allow 22/tcp   # SSH (from admin network only)
ufw allow 9100/tcp # node_exporter (from Prometheus only)
ufw allow 8080/tcp # cAdvisor (from Prometheus only)

# Outbound
ufw allow out 443/tcp  # HTTPS (GitLab)
ufw allow out 123/udp  # NTP
ufw allow out 53/udp   # DNS

# Default deny
ufw default deny incoming
ufw default allow outgoing
ufw enable
```

- [ ] **File integrity monitoring**
  - Monitor `/etc/gitlab-runner/`
  - Alert on unauthorized changes

**AIDE Configuration** (example):
```
/etc/gitlab-runner ConfChangelog
```

### Docker Security

- [ ] **Docker daemon secured**
  - Socket access restricted
  - Docker Content Trust enabled (optional)

**Docker Socket Permissions**:
```bash
# Only gitlab-runner and root can access
chmod 660 /var/run/docker.sock
chown root:docker /var/run/docker.sock
```

- [ ] **Container resource limits**
  - Memory limits configured
  - CPU limits enforced

**Resource Limits** (config.toml):
```toml
[runners.docker]
  memory = "2g"
  cpus = "2.0"
  cpu_shares = 1024
```

### Monitoring and Alerting

- [ ] **Security monitoring configured**
  - Failed login attempts monitored
  - Unusual network traffic alerted
  - Container escapes detected

**Prometheus Alerts**:
- RunnerDown
- HighDiskUsage (potential disk filling attack)
- TooManyContainers (potential resource exhaustion)
- UnauthorizedImagePull

### Compliance and Policies

- [ ] **Security policies documented**
  - Incident response plan
  - Acceptable use policy
  - Change management process

**Policy Documents**:
- `docs/incident-response-plan.md`
- `docs/acceptable-use-policy.md`
- `docs/change-management.md`

### Regular Security Reviews

- [ ] **Quarterly security audit**
  - Review access logs
  - Update allowed images
  - Verify firewall rules
  - Rotate secrets

**Audit Checklist**:
1. Review GitLab Runner access logs
2. Check for outdated images in whitelist
3. Verify firewall rules are current
4. Rotate registration tokens
5. Update OS security patches
6. Review monitoring alerts
7. Test incident response procedures

## Incident Response

### Suspected Compromise

If you suspect a runner has been compromised:

1. **Isolate** the runner:
   ```bash
   # Stop service
   systemctl stop gitlab-runner docker
   
   # Block network (firewall)
   ufw deny out
   ```

2. **Investigate**:
   ```bash
   # Check logs
   journalctl -u gitlab-runner --since "24 hours ago"
   
   # Check running containers
   docker ps -a
   
   # Check network connections
   netstat -tupan
   ```

3. **Preserve evidence**:
   ```bash
   # Backup logs
   tar -czf /root/runner-evidence-$(date +%Y%m%d).tar.gz \
     /var/log/gitlab-runner \
     /etc/gitlab-runner \
     /var/lib/docker/containers
   ```

4. **Notify** security team

5. **Reprovision**:
   ```bash
   ansible-playbook -i inventories/runners playbooks/reprovision-gitlab-runner.yml \
     --limit compromised-runner --ask-vault-pass
   ```

6. **Post-incident review**:
   - Root cause analysis
   - Update security controls
   - Document lessons learned

## Vulnerability Management

### Regular Updates

- **GitLab Runner**: Update quarterly or when security advisories are published
- **Docker Engine**: Follow Docker security advisories
- **Base OS**: Unattended security updates enabled
- **Base Images**: Rebuild monthly with latest patches

### Vulnerability Scanning

**Docker Image Scanning**:
```bash
# Use Trivy for vulnerability scanning
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image alpine:latest
```

**CVE Monitoring**:
- Subscribe to GitLab security mailing list
- Monitor Docker CVE database
- Set up automated vulnerability scanning in CI pipeline

## References

- [GitLab Runner Security Documentation](https://docs.gitlab.com/runner/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)

## Approval and Review

- **Created**: 2025-12-01
- **Last Reviewed**: 2025-12-01
- **Next Review**: 2026-03-01 (quarterly)
- **Approved by**: Infrastructure Security Team
