# Proxmox provisioning modules / playbooks (SCRUM-76)

This document explains the Terraform module and Ansible playbook added under `infrastructure/proxmox` and `infrastructure/ansible/roles/proxmox-template` to provision VM templates and create cloud-init-enabled VMs in a Proxmox cluster.

Naming convention (recommended)
------------------------------

For consistency and DNS-friendly operations we recommend creating VMs that are fully-qualified domain names (FQDNs) under the internal site domain. Example pattern used in this repository and examples: *.paws360.ryannanney.com (e.g. web-staging-01.paws360.ryannanney.com). The provisioning roles/templates support a `cloud_init_domain` variable and will generate FQDNs by appending the domain to the `cloud_init_hostname` when required.

Quick start (Terraform)

1. Update `infrastructure/proxmox/terraform-module/variables.tf` values in a `terraform.tfvars` or provide env vars for `pm_api_url`, `pm_user`, `pm_password`.
2. From `infrastructure/proxmox/terraform-module` run:

```bash
terraform init
terraform plan -var='pm_api_url=https://pve.example:8006/api2/json' -var='pm_user=root@pam' \
  -var='pm_password=$PROXMOX_PASS'
terraform apply -auto-approve
```

Quick start (Ansible)

1. Install collections & dependencies

```bash
ansible-galaxy collection install -r infrastructure/ansible/requirements.yml
pip install proxmoxer
```

2. From the repo root run the provision playbook and enter the Proxmox API token:

```bash
ansible-playbook infrastructure/ansible/playbooks/provision-proxmox.yml

Note about template lookup and cloning
-----------------------------------

The `proxmox-template` role now resolves an existing template VM *by name* (the `template_name` variable) using `community.proxmox.proxmox_vm_info` and extracts the numeric `vmid` to perform clone operations. This ensures the proxmox modules receive a numeric `clone`/`vmid` value rather than a string template name, avoiding type conversion errors during cloning.

If you want to preview a non-destructive run (check-mode) use:

```bash
ANSIBLE_ROLES_PATH=infrastructure/ansible/roles \
  ansible-playbook -i localhost, --check infrastructure/ansible/playbooks/provision-proxmox.yml \
  -e "proxmol_api_url=<your_api_url> proxmol_api_user=<user> proxmol_api_token_id=<token_id> proxmol_api_token_secret=<token_secret>"
```

Replace the `-e` values with your environment's settings — when the playbook is in check-mode it will query the API to verify template existence and will report any issues without creating VMs.
```

Bootstrap HA services (staging)

After provisioning the staging VMs (example in `terraform-module/examples/staging.tf`) you can bootstrap HA services using the repo inventory's staging group:

```bash
ansible-playbook -i infrastructure/ansible/inventories/staging infrastructure/ansible/playbooks/bootstrap-staging-ha.yml
```

Notes on network & IPs
- Assigning static IPs via cloud-init or DHCP reservations is recommended for production — update the Terraform module to set `ipconfig0` when needed.

etcd / Patroni / Redis cluster bootstrap

1. After the staging VMs are running and reachable via SSH, run the bootstrap playbook which will:
  - provision an etcd cluster on `[etcd]` hosts
  - configure Patroni on `[databases]` with etcd endpoints
  - configure Redis with Sentinel + attempt cluster bootstrap on `[redis]` hosts

```bash
ansible-playbook -i infrastructure/ansible/inventories/staging infrastructure/ansible/playbooks/bootstrap-staging-ha.yml
```

Health checks

Run a quick health check after provisioning & bootstrapping:

```bash
ansible-playbook -i infrastructure/ansible/inventories/staging infrastructure/ansible/playbooks/health-check-staging.yml
```

If anything fails, check logs on failing hosts and re-run the appropriate playbook (etcd first, then Patroni, then Redis, then app overlay).

Production hardening & secrets guidance
------------------------------------

This repository provides staging-friendly defaults; to move toward production-grade deployments follow these steps:

- TLS for etcd (recommended): set `etcd_tls_enable: true` in your inventory/group vars or host vars and ensure `etcd_tls_cert_dir` is writable. The role can generate a self-signed CA and host certs (useful for staging). For production, prefer a proper PKI (Vault/CFSSL) and avoid storing long-lived private keys in the repo.

- Authentication for etcd: set `etcd_auth_enable: true` and configure `etcd_root_password` via Ansible Vault or a secrets manager. Enabling auth in a live etcd cluster requires a careful rolling procedure; consult the etcd docs.

- Patroni + etcd TLS: enable `patroni_etcd_tls_enable: true` and ensure Patroni can read the CA and client certs at the configured paths (defaults are shown in the role). The bootstrap playbook now copies the etcd CA into Patroni hosts when TLS is turned on.

- Redis ACLs: set a strong `redis_password` (via Vault or CI secrets). The `redis.conf` template will enable `requirepass` and `masterauth` when a password is present; Sentinel will use `sentinel auth-pass` to monitor and failover correctly.

Using Ansible Vault (recommended for secrets)
-------------------------------------------

Create a vault file and store sensitive variables (example):

```bash
ansible-vault create infrastructure/ansible/group_vars/staging/vault.yml
# inside vault.yml put: etcd_root_password: "<strong-secret>"\nredis_password: "<very-strong-secret>"
```

Then invoke playbooks with `--ask-vault-pass` or configure a CI-secured vault password file (don't commit it).

CI automation & gated staging applies
---------------------------------

To reduce accidental production changes, CI actions should be gated. This repository adds an example GitHub Actions workflow that splits Terraform Plan and Apply into separate jobs and ties the Apply job to a protected `staging` environment. That means an administrator (or the environment's approvers) must approve the environment before the Apply job runs — this is a simple, safe way to gate infra provisioning from CI.

See `.github/workflows/provision-staging.yml` for an example. The plan step runs automatically, stores the plan file as an artifact, and the apply step requires environment approval via GitHub Environments.

End-to-end helper script

There's a helper script that runs an end-to-end flow for staging (terraform -> ansible provision -> bootstrap HA -> health check). It expects your environment variables and terraform credentials to be set.

```bash
export PROXMOX_PASS="<secret>"
export PM_API_URL="https://pve.example.local:8006/api2/json"
export PM_USER="root@pam"
infrastructure/proxmox/deploy-staging.sh
```

Note: This script is intended for environments you control; review and adapt before using in CI. It will attempt to provision real VMs in your Proxmox cluster.

Notes
- These are example templates and provisioning helpers — review and adapt to your Proxmox cluster topology.
- Do not commit credentials to the repo: use Vault, environment variables, or your CI secret storage.
