---
title: "GitLab Runner on Proxmox"
last_updated: "2025-12-01"
owner: "DevOps Team"
services: ["gitlab-runner", "node-exporter", "cadvisor"]
dependencies: ["proxmox", "docker", "gitlab"]
ansible_playbook: "infrastructure/ansible/playbooks/provision-gitlab-runner.yml"
ansible_role: "infrastructure/ansible/roles/gitlab-runner"
inventory: "infrastructure/ansible/inventories/runners/hosts"
jira_tickets: ["SCRUM-85"]
monitoring:
  - endpoint: "http://gitlab-runner-01:9100/metrics"
    type: "node_exporter"
  - endpoint: "http://gitlab-runner-01:8080/metrics"
    type: "cadvisor"
  - endpoint: "http://gitlab-runner-01:9252/metrics"
    type: "gitlab-runner"
prometheus_config: "monitoring/prometheus/gitlab-runner-targets.yml"
grafana_dashboard: "monitoring/dashboards/gitlab-runner-dashboard.json"
alert_rules: "monitoring/prometheus/alerts/gitlab-runner.yml"
ai_agent_instructions:
  - "Runner provisioning is performed using Ansible; ensure registration tokens are stored in Ansible Vault and never printed in logs."
  - "Use Docker executor for job isolation with allowed_images whitelist for security."
  - "For deployment runners, implement network restrictions and tag-based job control."
  - "Monitor runner health via Prometheus metrics at ports 9100 (node_exporter), 8080 (cAdvisor), 9252 (runner metrics)."
  - "Reprovision runners using: ansible-playbook -i inventories/runners playbooks/reprovision-gitlab-runner.yml"

---

# GitLab Runner on Proxmox — Context

This file provides operational context for provisioning and maintaining the
GitLab Runner on the Proxmox cluster. It is machine-readable and intended for
AI-driven automation and operator reference.

## Implementation Status

- **Phase 1-6**: Complete (Setup, Foundational, User Stories 1-3, Polish)
- **User Story 1 (MVP)**: ✅ Provision and register runner with Docker executor
- **User Story 2**: ✅ Deployment support with network access and secret handling
- **User Story 3**: ✅ Monitoring, alerting, and lifecycle management

## Key operational notes

- **Provisioning**: Ansible playbook at `infrastructure/ansible/playbooks/provision-gitlab-runner.yml`
- **Runner Role**: `infrastructure/ansible/roles/gitlab-runner` with tasks: install-docker.yml, install-runner.yml, register-runner.yml, monitoring.yml
- **Registration**: Tokens stored in Ansible Vault (`group_vars/vault.yml`)
- **Monitoring**: Integrated with Prometheus + Grafana
  - Node metrics: port 9100
  - Container metrics: port 8080
  - Runner metrics: port 9252
- **Alerts**: RunnerDown, HighDiskUsage, JobQueueBacklog (see alert_rules)
- **Security**: Image/service restrictions, network firewall, secret rotation schedule
- **Lifecycle**: Reprovisioning playbook available for runner rebuilds

## Quick Reference

```bash
# Provision new runner
cd infrastructure/ansible
ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml --ask-vault-pass

# Verify runner
ssh root@gitlab-runner-01 gitlab-runner list
ssh root@gitlab-runner-01 gitlab-runner verify

# Reprovision runner
ansible-playbook -i inventories/runners playbooks/reprovision-gitlab-runner.yml --limit gitlab-runner-01 --ask-vault-pass

# Check monitoring
curl http://gitlab-runner-01:9100/metrics  # Node exporter
curl http://gitlab-runner-01:8080/metrics  # cAdvisor
```

## Documentation

- Operations Guide: `docs/gitlab-runner-operations.md`
- Security Hardening: `docs/gitlab-runner-security.md`
- Role README: `infrastructure/ansible/roles/gitlab-runner/README.md`
- Quickstart: `specs/001-gitlab-runner-proxmox/quickstart.md`
