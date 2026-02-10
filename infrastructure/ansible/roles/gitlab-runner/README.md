# GitLab Runner Ansible Role

Ansible role for provisioning and configuring GitLab Runner on Proxmox infrastructure with Docker executor.

## Features

- Automated GitLab Runner installation and registration
- Docker executor with configurable privileges and restrictions
- Network validation for deployment tasks
- Monitoring integration (node_exporter, cAdvisor)
- Idempotent playbook design
- Support for Debian/Ubuntu and RedHat/CentOS distributions

## Requirements

- Ansible >= 2.9
- Target host: Ubuntu 20.04+ or Debian 11+ or CentOS 8+
- GitLab instance URL and registration token
- Proxmox cluster (optional, for VM provisioning)

## Role Variables

See `defaults/main.yml` for all available variables. Key variables:

### GitLab Configuration

```yaml
gitlab_url: "https://gitlab.example.com"
gitlab_registration_token: "{{ vault_gitlab_registration_token }}"  # Store in Ansible Vault
```

### Runner Configuration

```yaml
runner_name: "{{ ansible_hostname }}-runner"
runner_tags: "proxmox-local,ci,docker"
runner_executor: "docker"
runner_concurrent: 1
```

### Docker Executor Settings

```yaml
runner_docker_image: "alpine:latest"
runner_docker_privileged: true
runner_docker_pull_policy: "if-not-present"
runner_docker_volumes:
  - "/var/run/docker.sock:/var/run/docker.sock"
  - "/cache"
```

### Secret Management

**IMPORTANT**: Never commit registration tokens to version control!

#### Using Ansible Vault (Recommended)

1. Create encrypted vault file:
   ```bash
   cd infrastructure/ansible
   ansible-vault create group_vars/vault.yml
   ```

2. Add your GitLab registration token:
   ```yaml
   ---
   vault_gitlab_registration_token: "your-actual-registration-token"
   ```

3. Reference in `group_vars/runners.yml`:
   ```yaml
   gitlab_registration_token: "{{ vault_gitlab_registration_token }}"
   ```

4. Store vault password in a secure location:
   - `.vault_pass` file (add to .gitignore)
   - Environment variable: `ANSIBLE_VAULT_PASSWORD_FILE`
   - Password manager integration

5. Run playbook with vault password:
   ```bash
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass
   # OR
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --vault-password-file .vault_pass
   ```

#### Using GitLab CI/CD Variables (Alternative)

For CI/CD pipelines, store the token in GitLab CI/CD variables:

1. Navigate to: GitLab Project → Settings → CI/CD → Variables
2. Add variable:
   - Key: `GITLAB_RUNNER_REGISTRATION_TOKEN`
   - Value: Your registration token
   - Flags: ✓ Protected, ✓ Masked
3. Reference in pipeline:
   ```yaml
   deploy:runner:
     script:
       - ansible-playbook ... --extra-vars "gitlab_registration_token=$GITLAB_RUNNER_REGISTRATION_TOKEN"
   ```

#### Using HashiCorp Vault (Enterprise)

For production environments with HashiCorp Vault:

```yaml
# group_vars/runners.yml
gitlab_registration_token: "{{ lookup('hashi_vault', 'secret=secret/gitlab/runner:token') }}"
```

## Dependencies

- `geerlingguy.docker` (version 6.1.0)
- `proxmox-template` (optional, for VM creation)

Install dependencies:
```bash
cd infrastructure/ansible
ansible-galaxy install -r requirements.yml
```

## Example Playbook

See `playbooks/provision-gitlab-runner.yml` for the complete example.

```yaml
- name: Provision GitLab Runner
  hosts: runners
  become: true
  roles:
    - role: geerlingguy.docker
    - role: gitlab-runner
```

## Usage

### Provision Runner on Existing Host

1. Configure inventory:
   ```ini
   # inventories/runners/hosts
   [runners]
   gitlab-runner-01 ansible_host=192.168.1.100 ansible_user=root
   ```

2. Configure variables:
   ```bash
   # Edit group_vars/runners.yml with your GitLab URL and settings
   vim group_vars/runners.yml
   ```

3. Run playbook:
   ```bash
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml
   ```

### Provision Runner with New VM on Proxmox

1. Configure VM settings in `group_vars/runners.yml`:
   ```yaml
   create_vm: true
   vm_list:
     - name: gitlab-runner-01
       node: pve-node-1
       cores: 4
       memory: 8192
       disk_size: 100
       ip_address: 192.168.1.100/24
   ```

2. Run playbook with VM creation:
   ```bash
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --extra-vars "create_vm=true"
   ```

## Validation

### Verify Runner Registration

```bash
# SSH to runner host
ssh root@gitlab-runner-01

# Check runner status
gitlab-runner list
gitlab-runner verify
systemctl status gitlab-runner
```

### Test with CI Job

Add to your `.gitlab-ci.yml`:
```yaml
test:runner:
  tags:
    - proxmox-local
  script:
    - echo "Hello from local runner!"
    - docker info
```

### Idempotence Test

```bash
# Re-run playbook - should show minimal/no changes
ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml
```

## Security Best Practices

1. **Privileged Mode**: Only enable `runner_docker_privileged: true` when necessary
   - Required for Docker-in-Docker (DinD) workflows
   - Consider rootless Docker as alternative for reduced risk

2. **Image Restrictions**: Use `runner_docker_allowed_images` to whitelist trusted images
   ```yaml
   runner_docker_allowed_images:
     - "alpine:*"
     - "ubuntu:22.04"
   ```

3. **Network Segmentation**: Isolate runner hosts in dedicated network segment
   - Limit outbound access to necessary services only
   - Use firewall rules (see `tasks/configure-firewall.yml`)

4. **Secret Rotation**: Rotate registration tokens regularly
   - Update token in Ansible Vault
   - Re-run registration task

5. **Tag Restrictions**: Use specific tags to control which jobs run on which runners
   - Avoid `run-untagged` for production runners
   - Use separate runners for build vs deployment

## Monitoring

When `enable_monitoring: true`, the role installs:

- **node_exporter** (port 9100): System metrics
- **cAdvisor** (port 8080): Container metrics

Configure Prometheus scrape targets in `monitoring/prometheus/gitlab-runner-targets.yml`.

View Grafana dashboard: Import `monitoring/dashboards/gitlab-runner-dashboard.json`

## Troubleshooting

### Runner Not Registering

```bash
# Check registration token
gitlab-runner verify

# Re-register manually
gitlab-runner register --url https://gitlab.example.com --registration-token REPLACE_ME
```

### Docker Permission Denied

```bash
# Ensure gitlab-runner user is in docker group
usermod -aG docker gitlab-runner
systemctl restart gitlab-runner
```

### Network Connectivity Issues

```bash
# Test GitLab connectivity
curl -I https://gitlab.example.com

# Check DNS
nslookup gitlab.example.com

# Verify firewall rules
iptables -L -n
```

## License

MIT (align with PAWS360 repository license)

## Author

PAWS360 Infrastructure Team
