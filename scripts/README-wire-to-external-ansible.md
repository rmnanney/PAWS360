Wire PAWS360 Ansible changes into an external infrastructure repo
===============================================================

What this does
--------------
This project includes a helper script `scripts/wire-to-external-ansible.sh` which safely copies a set of updated Ansible role files, playbooks, and example CI workflows from this PAWS360 repository into another ansible deployment repository (defaults to `~/repos/infrastructure/ansible`).

Files that will be copied
------------------------
- infrastructure/ansible/roles/etcd
- infrastructure/ansible/roles/postgres-patroni
- infrastructure/ansible/roles/redis-sentinel
- infrastructure/ansible/playbooks/bootstrap-staging-ha.yml
- infrastructure/ansible/group_vars/staging/vault.yml.example
- docs/INFRA-PROXMOX-PROVISIONING.md
- .github/workflows/provision-staging.yml
- .github/workflows/bootstrap-staging.yml

How it behaves
--------------
- Performs a dry-run (rsync) and shows what will change.
- If file exists in target, creates a timestamped backup before overwriting.
- If target is a git repo, creates a new branch and commits the changes.

Usage
-----
Default action (copies to $HOME/repos/infrastructure/ansible):

```bash
./scripts/wire-to-external-ansible.sh
```

To target a different path:

```bash
TARGET_DIR=/path/to/your/infra/ansible ./scripts/wire-to-external-ansible.sh
```

Safety notes
------------
- Do not run on production repositories without reviewing the changes first. The script creates backups of overwritten files and commits changes on a branch.
- If the target repository has unique conventions or additional gating, review the files copied and make any adjustments before merging.
