Postgres Patroni role
=====================

Installs and configures Patroni-managed PostgreSQL nodes suitable for HA. This role is intentionally minimal and designed as a starting point — a production deployment must integrate an etcd/consul cluster and proper TLS/authentication.

High-level responsibilities:
- Install PostgreSQL and Patroni
- Create Patroni configuration from template
- Ensure systemd service enabled and running
- Configure WAL archiving and backup hooks (left as placeholders)

Security & production notes:
- Patroni requires a distributed consensus store (etcd/consul). Deploy that before enabling Patroni on DB nodes.
- Use Ansible Vault for secrets (Postgres passwords, Patroni secrets).
