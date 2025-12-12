# Ansible Runner Inventory Guide

**Feature ID:** 001-github-runner-deploy  
**JIRA Epic:** INFRA-472  
**Date:** 2025-01-XX  
**Author:** DevOps Team  

---

## Purpose

This guide documents how to configure Ansible inventory for GitHub Actions self-hosted runners, including group structure, host variables, and monitoring integration. All infrastructure addresses MUST use Ansible inventory variables (IaC mandate - no hardcoded IPs).

## Inventory Structure

### Directory Layout

```
infrastructure/ansible/
├── inventories/
│   ├── production/
│   │   ├── hosts                  # Main inventory file
│   │   └── group_vars/
│   │       ├── all.yml           # Variables for all hosts
│   │       ├── runners.yml       # Runner-specific variables
│   │       └── monitoring.yml    # Monitoring stack addresses
│   └── staging/
│       ├── hosts
│       └── group_vars/
│           ├── all.yml
│           ├── runners.yml
│           └── monitoring.yml
└── playbooks/
    ├── runner-provision.yml       # Provision runner hosts
    ├── runner-configure.yml       # Configure runners
    └── runner-decommission.yml    # Remove runners
```

## Host Groups

### `[runners]` Group

This group contains all GitHub Actions self-hosted runner hosts.

#### Production Inventory Example

**File:** `infrastructure/ansible/inventories/production/hosts`

```ini
[runners]
production-runner-01 ansible_host=<IP_OR_FQDN> runner_group=primary runner_priority=1
production-runner-02 ansible_host=<IP_OR_FQDN> runner_group=secondary runner_priority=2

[runners:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/paws360_deploy
ansible_python_interpreter=/usr/bin/python3

[monitoring]
monitoring-stack ansible_host=192.168.0.200

[all:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

**Important Notes:**
- Replace `<IP_OR_FQDN>` with actual values from authoritative source
- `runner_priority` determines failover order (1=primary, 2=secondary)
- `runner_group` used to assign GitHub Actions runner labels

#### Staging Inventory Example

**File:** `infrastructure/ansible/inventories/staging/hosts`

```ini
[runners]
dell-r640-01 ansible_host=192.168.0.51 runner_group=primary runner_priority=1
dell-r640-02 ansible_host=192.168.0.52 runner_group=secondary runner_priority=2

[runners:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/paws360_staging
ansible_python_interpreter=/usr/bin/python3

[monitoring]
monitoring-stack ansible_host=192.168.0.200

[all:vars]
ansible_connection=ssh
```

## Group Variables

### All Hosts (`group_vars/all.yml`)

Common variables for all hosts in inventory.

```yaml
---
# Timezone configuration
timezone: "America/New_York"

# NTP servers
ntp_servers:
  - "0.pool.ntp.org"
  - "1.pool.ntp.org"

# DNS servers
dns_nameservers:
  - "8.8.8.8"
  - "8.8.4.4"

# Docker configuration
docker_edition: "ce"
docker_compose_version: "2.23.0"

# Logging
log_retention_days: 90
```

### Runner Hosts (`group_vars/runners.yml`)

Variables specific to GitHub Actions runner hosts.

```yaml
---
# GitHub runner configuration
github_runner_version: "2.311.0"
github_runner_user: "runner"
github_runner_group: "runner"
github_runner_home: "/opt/github-runner"

# Runner labels (dynamically set based on runner_group)
github_runner_labels:
  - "self-hosted"
  - "linux"
  - "x64"
  - "production"
  - "{{ runner_group }}"  # primary or secondary

# Runner configuration
github_runner_ephemeral: true  # JIT runner preferred
github_runner_concurrency: 1   # One job at a time

# Docker configuration
docker_users:
  - "{{ github_runner_user }}"

# Preflight check thresholds
preflight_cpu_percent_max: 80
preflight_memory_percent_max: 80
preflight_disk_gb_min: 10
preflight_network_timeout_seconds: 5

# Health gate configuration
health_gate_timeout_seconds: 300  # 5 minutes per service
health_gate_retry_count: 3
health_gate_retry_backoff: 2  # Exponential backoff multiplier

# Required secrets (presence validation only)
required_secrets:
  - DB_PASSWORD
  - REDIS_PASSWORD
  - API_KEY

# Deployment targets (for preflight network checks)
deployment_targets:
  - "api.paws360.local"
  - "db.paws360.local"
  - "redis.paws360.local"

# Monitoring
prometheus_pushgateway_url: "{{ monitoring.prometheus.host }}:{{ monitoring.prometheus.pushgateway_port }}"
```

### Monitoring Stack (`group_vars/monitoring.yml`)

**CRITICAL:** All scripts and workflows MUST reference these variables, not hardcoded IPs.

```yaml
---
# Monitoring stack addresses
monitoring:
  prometheus:
    host: "192.168.0.200"
    port: 9090
    pushgateway_port: 9091
    url: "http://{{ monitoring.prometheus.host }}:{{ monitoring.prometheus.port }}"
    pushgateway_url: "http://{{ monitoring.prometheus.host }}:{{ monitoring.prometheus.pushgateway_port }}"
  
  grafana:
    host: "192.168.0.200"
    port: 3000
    url: "http://{{ monitoring.grafana.host }}:{{ monitoring.grafana.port }}"
  
  loki:
    host: "192.168.0.200"
    port: 3100
    url: "http://{{ monitoring.loki.host }}:{{ monitoring.loki.port }}"

# Alert manager configuration
alertmanager:
  host: "192.168.0.200"
  port: 9093
  url: "http://{{ alertmanager.host }}:{{ alertmanager.port }}"

# Grafana dashboard IDs
dashboards:
  github_runners: "github-runners"
  deployment_metrics: "deployment-metrics"
```

## Using Inventory Variables in Scripts

### Retrieving Variables from Inventory

#### Method 1: `ansible-inventory` Command

```bash
#!/usr/bin/env bash
# scripts/deployment/preflight-checks.sh

# Get Prometheus URL from inventory
PROMETHEUS_URL=$(ansible-inventory -i infrastructure/ansible/inventories/production/hosts \
  --host monitoring-stack --yaml | \
  yq '.monitoring.prometheus.url')

echo "Pushing metrics to: ${PROMETHEUS_URL}"
```

#### Method 2: Ansible Playbook

```yaml
# playbooks/collect-deployment-metrics.yml
---
- name: Collect deployment metrics
  hosts: runners
  tasks:
    - name: Push metrics to Prometheus
      shell: |
        cat <<EOF | curl --data-binary @- {{ monitoring.prometheus.pushgateway_url }}/metrics/job/github-actions/instance/{{ inventory_hostname }}
        # TYPE deployment_success_total counter
        deployment_success_total{workflow="ci",branch="main"} 1
        EOF
```

#### Method 3: Environment File Generation

```yaml
# playbooks/generate-env-file.yml
---
- name: Generate environment file for CI
  hosts: localhost
  tasks:
    - name: Create .env file with monitoring URLs
      copy:
        dest: ".env.monitoring"
        content: |
          PROMETHEUS_URL={{ monitoring.prometheus.url }}
          PROMETHEUS_PUSHGATEWAY_URL={{ monitoring.prometheus.pushgateway_url }}
          GRAFANA_URL={{ monitoring.grafana.url }}
          LOKI_URL={{ monitoring.loki.url }}
```

### Using Variables in GitHub Workflows

**File:** `.github/workflows/ci.yml`

```yaml
jobs:
  deploy-to-production:
    runs-on: [self-hosted, linux, x64, production]
    steps:
      - name: Get monitoring addresses
        id: monitoring
        run: |
          ansible-inventory -i infrastructure/ansible/inventories/production/hosts \
            --host monitoring-stack --yaml | \
            yq -r '.monitoring.prometheus.pushgateway_url' > pushgateway_url.txt
          echo "pushgateway_url=$(cat pushgateway_url.txt)" >> $GITHUB_OUTPUT
      
      - name: Push deployment metrics
        run: |
          curl --data-binary @- ${{ steps.monitoring.outputs.pushgateway_url }}/metrics/job/github-actions << EOF
          deployment_success_total{workflow="ci"} 1
          EOF
```

## Playbook Examples

### Runner Provisioning Playbook

**File:** `infrastructure/ansible/playbooks/runner-provision.yml`

```yaml
---
- name: Provision GitHub Actions Runner
  hosts: runners
  become: yes
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install required packages
      apt:
        name:
          - curl
          - jq
          - git
          - docker.io
          - docker-compose
        state: present
    
    - name: Create runner user
      user:
        name: "{{ github_runner_user }}"
        shell: /bin/bash
        create_home: yes
        groups: docker
        append: yes
    
    - name: Create runner directory
      file:
        path: "{{ github_runner_home }}"
        state: directory
        owner: "{{ github_runner_user }}"
        group: "{{ github_runner_group }}"
        mode: '0755'
    
    - name: Download GitHub runner
      get_url:
        url: "https://github.com/actions/runner/releases/download/v{{ github_runner_version }}/actions-runner-linux-x64-{{ github_runner_version }}.tar.gz"
        dest: "/tmp/actions-runner.tar.gz"
    
    - name: Extract runner
      unarchive:
        src: "/tmp/actions-runner.tar.gz"
        dest: "{{ github_runner_home }}"
        remote_src: yes
        owner: "{{ github_runner_user }}"
        group: "{{ github_runner_group }}"
```

### Runner Configuration Playbook

**File:** `infrastructure/ansible/playbooks/runner-configure.yml`

```yaml
---
- name: Configure GitHub Actions Runner
  hosts: runners
  become: yes
  vars:
    runner_token: "{{ lookup('env', 'GITHUB_RUNNER_TOKEN') }}"
  tasks:
    - name: Configure runner
      become_user: "{{ github_runner_user }}"
      shell: |
        cd {{ github_runner_home }}
        ./config.sh \
          --url https://github.com/YOUR_ORG/PAWS360 \
          --token {{ runner_token }} \
          --name {{ inventory_hostname }} \
          --labels {{ github_runner_labels | join(',') }} \
          --work _work \
          --unattended \
          {% if github_runner_ephemeral %}--ephemeral{% endif %}
    
    - name: Install runner service
      shell: |
        cd {{ github_runner_home }}
        ./svc.sh install {{ github_runner_user }}
    
    - name: Start runner service
      shell: |
        cd {{ github_runner_home }}
        ./svc.sh start
```

### Runner Health Check Playbook

**File:** `infrastructure/ansible/playbooks/runner-health-check.yml`

```yaml
---
- name: Check Runner Health
  hosts: runners
  become: yes
  tasks:
    - name: Check runner service status
      systemd:
        name: actions.runner.*
        state: started
      register: runner_service
    
    - name: Check disk space
      shell: df -h {{ github_runner_home }} | awk 'NR==2 {print $4}'
      register: disk_space
    
    - name: Check CPU usage
      shell: top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
      register: cpu_usage
    
    - name: Check memory usage
      shell: free | grep Mem | awk '{print ($3/$2) * 100.0}'
      register: memory_usage
    
    - name: Report health status
      debug:
        msg: |
          Runner: {{ inventory_hostname }}
          Service: {{ runner_service.status.ActiveState }}
          Disk: {{ disk_space.stdout }}
          CPU: {{ cpu_usage.stdout }}%
          Memory: {{ memory_usage.stdout }}%
```

## Inventory Validation

### Command: `ansible-inventory --list`

Validate inventory structure and variable resolution:

```bash
ansible-inventory -i infrastructure/ansible/inventories/production/hosts --list --yaml
```

Expected output (excerpt):

```yaml
all:
  children:
    runners:
      hosts:
        production-runner-01:
          ansible_host: <IP_OR_FQDN>
          runner_group: primary
          runner_priority: 1
          github_runner_labels:
            - self-hosted
            - linux
            - x64
            - production
            - primary
        production-runner-02:
          ansible_host: <IP_OR_FQDN>
          runner_group: secondary
          runner_priority: 2
    monitoring:
      hosts:
        monitoring-stack:
          ansible_host: 192.168.0.200
          monitoring:
            prometheus:
              host: 192.168.0.200
              port: 9090
```

### Command: `ansible-inventory --graph`

Visualize inventory hierarchy:

```bash
ansible-inventory -i infrastructure/ansible/inventories/production/hosts --graph
```

Expected output:

```
@all:
  |--@runners:
  |  |--production-runner-01
  |  |--production-runner-02
  |--@monitoring:
  |  |--monitoring-stack
  |--@ungrouped:
```

## Troubleshooting

### Issue: "Host not found in inventory"

**Cause:** Hostname typo or missing host entry

**Solution:**
```bash
# List all hosts in inventory
ansible-inventory -i infrastructure/ansible/inventories/production/hosts --list

# Check specific host
ansible-inventory -i infrastructure/ansible/inventories/production/hosts --host production-runner-01
```

### Issue: "Variable not defined"

**Cause:** Missing group_vars file or typo in variable name

**Solution:**
```bash
# Check variable resolution for host
ansible-inventory -i infrastructure/ansible/inventories/production/hosts --host production-runner-01 --yaml | grep -A5 "monitoring"

# Validate group_vars file syntax
ansible-playbook --syntax-check playbooks/runner-provision.yml
```

### Issue: "Hardcoded IP detected in script"

**Cause:** Script not using inventory variables (IaC mandate violation)

**Solution:**
```bash
# Run constitutional compliance check
./scripts/compliance/constitutional-self-check.sh

# Fix by replacing hardcoded IP with inventory lookup
# BAD:
PROMETHEUS_URL="http://192.168.0.200:9090"

# GOOD:
PROMETHEUS_URL=$(ansible-inventory -i infrastructure/ansible/inventories/production/hosts \
  --host monitoring-stack --yaml | yq '.monitoring.prometheus.url')
```

## Security Best Practices

### SSH Key Management

1. **Generate dedicated SSH key for Ansible:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/paws360_deploy -C "ansible-deploy@paws360"
   ```

2. **Add public key to runner hosts:**
   ```bash
   ssh-copy-id -i ~/.ssh/paws360_deploy.pub ubuntu@<RUNNER_HOST>
   ```

3. **Set restrictive permissions:**
   ```bash
   chmod 600 ~/.ssh/paws360_deploy
   ```

### Inventory Encryption (Ansible Vault)

Encrypt sensitive variables (future enhancement):

```bash
# Encrypt group_vars file
ansible-vault encrypt infrastructure/ansible/inventories/production/group_vars/all.yml

# Edit encrypted file
ansible-vault edit infrastructure/ansible/inventories/production/group_vars/all.yml

# Run playbook with vault password
ansible-playbook -i infrastructure/ansible/inventories/production/hosts \
  --ask-vault-pass \
  playbooks/runner-provision.yml
```

## Related Documentation

- JIRA: INFRA-472 (Epic), INFRA-473 (User Story 1)
- Context: `contexts/infrastructure/github-runners.md`
- Infrastructure Impact: `docs/infrastructure/runner-deployment-impact.md`
- Ansible Playbooks: `infrastructure/ansible/playbooks/runner-*.yml`

## Appendix: Production Inventory Finalization

**STATUS:** BLOCKED - Awaiting authoritative source for production addresses

### Required Information

1. **Production Runner Hosts:**
   - Primary runner host IP/FQDN
   - Secondary runner host IP/FQDN
   - SSH access credentials

2. **Deployment Targets:**
   - API service address
   - Database address
   - Redis address

3. **Monitoring Stack:**
   - Prometheus address (currently 192.168.0.200, needs confirmation)
   - Grafana address
   - Loki address (if different)

### Next Steps

1. Identify authoritative source for production inventory (NetBox, CMDB, documentation)
2. Update `infrastructure/ansible/inventories/production/hosts` with correct addresses
3. Validate connectivity: `ansible -i infrastructure/ansible/inventories/production/hosts runners -m ping`
4. Proceed with Phase 2 implementation (runner provisioning)

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Next Review:** After production inventory finalization
