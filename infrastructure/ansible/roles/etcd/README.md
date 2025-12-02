etcd role
=========

Installs and configures an etcd cluster for use as a consensus store (suitable for Patroni or other cluster coordination).

This role downloads a specified etcd release, installs it under /usr/local/bin, and creates a systemd service.

Security (recommended for production):
- TLS: this role can optionally generate a CA and host certificates (set `etcd_tls_enable: true`) and installs them to `{{ etcd_tls_cert_dir }}`. The cert generation uses the `community.crypto` collection and is performed on the Ansible controller (run_once) and then distributed to etcd hosts.
- Authentication: enable `etcd_auth_enable: true` and set `etcd_root_user`/`etcd_root_password` (use Ansible Vault or a secrets manager for these values). When enabled, the role will still require manual bootstrapping steps for enabling authentication in an existing cluster — consult the etcd docs for rolling enablement.

NOTE: generated self-signed certificates are useful for staging and testing; for production we recommend using a long-lived CA from a proper PKI or integrating with a certificate manager (Vault/CFSSL/ACME) and limiting access to private keys.

Key variables:
- etcd_version
- etcd_cluster (list of host:clientURL strings)
- etcd_name (defaults to inventory_hostname)
