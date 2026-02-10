# speckit.specify

This folder contains speckit specifications for deploying PAWS360 to a Proxmox cluster.

Files in this directory:
- stage.spec.yaml — deployment spec for a staging environment
- production.spec.yaml — deployment spec for production

These specs are intentionally generic and use template values for cluster names, storage pools, and cloud-init values. When running in your environment, replace placeholder values with correct Proxmox node/cluster names, image templates, and secrets.

Usage (example):
1. Install the speckit/your-deployer CLI that understands these specs (or adapt the YAML to your CD tool).
2. Provide the Proxmox URL and credentials via environment variables or the CLI.
3. Run: speckit apply -f speckit.specify/stage.spec.yaml

Note: Do not commit production credentials to source control. Keep secrets in a secure vault and reference them at deploy time.