# Quickstart — Provision a GitLab Runner on Proxmox

This quickstart covers provisioning a single, restricted GitLab Runner on a
Proxmox host, using Ansible to create a VM/LXC, installing Docker, registering
the runner against a self-hosted GitLab, and verifying a sample CI job runs.

Prerequisites
- Proxmox admin access
- Access to the self-hosted GitLab instance and a registration token
- Ansible control host (or run from a dev workstation with Ansible and SSH access)

Steps (high-level)
1. Prepare the environment
   - Store runner registration token in GitLab / centralized secrets manager or Ansible Vault
   - Ensure Proxmox node has capacity (CPU, RAM, disk)
   - Configure inventory file at `infrastructure/ansible/inventories/runners/hosts`
   - Update variables in `infrastructure/ansible/group_vars/runners.yml`

2. Run Ansible playbook to provision GitLab Runner
   ```bash
   cd infrastructure/ansible
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml
   ```
   
   To create a new VM on Proxmox (optional):
   ```bash
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --extra-vars "create_vm=true"
   ```
   
   The playbook will:
   - Create a VM named from `vm_list` variable (if create_vm=true)
   - Install Docker using geerlingguy.docker role
   - Install GitLab Runner package
   - Register runner with GitLab using the registration token
   - Deploy config.toml with Docker executor settings
   - Set up monitoring (node_exporter, cAdvisor) if enabled

3. Verify runner registration
   ```bash
   # SSH to runner host
   ssh root@gitlab-runner-01
   
   # Check runner status
   gitlab-runner list
   gitlab-runner verify
   systemctl status gitlab-runner
   ```

4. Validate with CI job
   - Add validation job from `specs/001-gitlab-runner-proxmox/validation/runner-health.gitlab-ci.yml`
   - Commit and push to trigger pipeline
   - Confirm job runs on tag `proxmox-local`

5. Test idempotence (optional)
   ```bash
   # Re-run playbook - should show no changes
   ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml
   ```

Quick verification CI job (example .gitlab-ci.yml snippet):

```yaml
job:test-on-proxmox:
  tags:
    - gitlab-runner-proxmox
  script:
    - echo "Hello from local runner"
    - uname -a
```

Notes
- Secrets (registration tokens) must not be printed in logs — use GitLab variables
- For deployment-related jobs, provision a separate, dedicated runner with
  controlled network access after a security review
