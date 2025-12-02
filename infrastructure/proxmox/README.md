# Proxmox provisioning helper (Terraform + Ansible)

This folder contains two complementary approaches for provisioning VMs and templates in a Proxmox cluster.

- A Terraform module (`/terraform-module`) using the community/telmate provider to create templates, cloud-init-enabled images and VMs.
- An Ansible role & playbook (`../ansible/roles/proxmox-template` & `../ansible/playbooks/provision-proxmox.yml`) that clones templates, configures cloud-init, and can be used by your existing infrastructure/ansible workflow.

Why both? Terraform is excellent for lifecycle management of templates and image resources. Ansible is convenient for day-to-day cloning, cloud-init templating and tying the provisioned instances into the rest of the repo’s configuration management.

This work is tracked under SCRUM-76.  Treat the files in this directory as examples / starting points — update your environment-specific values and secrets before applying.

Security note: These files contain placeholders for credentials (PVE host, user, token). Do NOT commit real credentials — use Ansible Vault or the repo’s secrets mechanism.

Next steps:
- Customize variables (terraform.tfvars or environment secrets)
- Run terraform init/apply from the `terraform-module/` directory to create templates or cloud-init images
- Use the Ansible playbook to clone and bootstrap VMs from templates
