#!/usr/bin/env bash
set -euo pipefail

# Helper script: provision staging VMs on Proxmox then bootstrap HA services
# Requirements:
# - PROXMOX_PASS env var set (or use -var)
# - Access to Proxmox API
# - Ansible controller with SSH access to created VMs (keys)

MODULE_DIR="$(dirname "$0")/terraform-module"

if [ -z "${PROXMOX_PASS:-}" ] && ([ -z "${PROXMOX_API_TOKEN_ID:-}" ] || [ -z "${PROXMOX_API_TOKEN_SECRET:-}" ]); then
  echo "Please export either PROXMOX_PASS (password) OR PROXMOX_API_TOKEN_ID and PROXMOX_API_TOKEN_SECRET (token id and secret)"
  exit 1
fi

echo "==> Provisioning VMs via Ansible (staging) — Ansible-only provisioning"

# Export environment variables expected by the playbook/roles so the Ansible run
# is fully non-interactive and supports both token and username/password auth.
export PM_API_URL="${PM_API_URL:-${PROXMOX_API_URL:-https://pve.example.local:8006/api2/json}}"
export PM_USER="${PM_USER:-${PROXMOX_API_USER:-root@pam}}"
export PROXMOX_API_TOKEN_ID="${PROXMOX_API_TOKEN_ID:-}" 
export PROXMOX_API_TOKEN_SECRET="${PROXMOX_API_TOKEN_SECRET:-}"
export PROXMOX_PASS="${PROXMOX_PASS:-${PROXMOX_API_TOKEN_SECRET:-}}"

# Run the Ansible provisioning playbook (non-interactive; uses env vars)
ansible-playbook infrastructure/ansible/playbooks/provision-proxmox.yml -e "proxmol_api_url=${PM_API_URL} proxmol_api_user=${PM_USER} proxmol_api_password=${PROXMOX_PASS} proxmol_api_token_id=${PROXMOX_API_TOKEN_ID} proxmol_api_token_secret=${PROXMOX_API_TOKEN_SECRET}"

echo "==> Run Ansible provisioning to clone/configure VMs"
ansible-playbook infrastructure/ansible/playbooks/provision-proxmox.yml

echo "==> Bootstrap HA services on staging"
ansible-playbook -i infrastructure/ansible/inventories/staging infrastructure/ansible/playbooks/bootstrap-staging-ha.yml

echo "==> Run health checks"
ansible-playbook -i infrastructure/ansible/inventories/staging infrastructure/ansible/playbooks/health-check-staging.yml

echo "Staging provisioning complete — check the playbook outputs for errors"
