Proxmox Template Role
=====================

This Ansible role provides helper tasks to:

- Ensure proxmoxer is available on the controller (Python library used by community.proxmox modules)
- Query and clone an existing Proxmox template into one or more VMs
- Render cloud-init user-data from the provided Jinja2 template

Usage notes:
- Requires the `community.general` collection (provides `community.general.proxmox`).
- The playbook expects `proxmol_api_url`, `proxmol_api_user`, and a secure `proxmol_api_password` to be set (use Ansible Vault or environment variables)
- This role intentionally keeps examples and variables conservative — update memory/cores, storage names, and node targets for your Proxmox environment.
