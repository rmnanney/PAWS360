# Data model: GitLab Runner on Proxmox

**Feature**: 001-gitlab-runner-proxmox
**Created**: 2025-11-30

## Entities

### ProxmoxHost
- id: string (unique identifier, e.g., 'pve01')
- ip_address: string (management interface)
- name: string (human friendly)
- cpu_cores: integer
- memory_mb: integer
- disk_gb: integer
- status: enum [online, offline, degraded]
- last_checkin: timestamp

### RunnerInstance
- id: string (UUID)
- name: string (e.g., '001-gitlab-runner-proxmox')
- proxmox_host_id: string (FK -> ProxmoxHost)
- vm_or_lxc: enum [vm, lxc]
- executor: enum [docker, shell, ephemeral_vm]
- registered_with: string (gitlab url)
- registered_token_hash: string (hashed reference, secrets elsewhere)
- scope: enum [restricted_build, deployment]
- last_checkin: timestamp
- status: enum [registering, online, offline, error, deprovisioned]

### SecretReference
- id: string
- runner_id: string
- name: string (e.g., 'registration_token')
- location_hint: string (where the secret is stored, e.g., 'gitlab-ci-variables')

### NetworkSegment
- id: string
- name: string
- cidr: string
- required_for: list (e.g., [deployment-dry-run])

## Relationship Notes
- ProxmoxHost (1) -> RunnerInstance (many)
- RunnerInstance (1) -> SecretReference (many)
- RunnerInstance (many) -> NetworkSegment (many, via access policy)

## Validation Rules
- RunnerInstance.name must be unique among active runners
- registered_with must be a valid URL and reachable from the Proxmox host
- executor 'docker' requires Docker available on the host/VM

## State transitions (RunnerInstance.status)
- registering -> online on successful registration and first check-in
- online -> offline if check-in misses threshold (e.g., 5 minutes)
- online -> error if provisioning fails or job executor crashes
- offline -> deprovisioned on admin delete
