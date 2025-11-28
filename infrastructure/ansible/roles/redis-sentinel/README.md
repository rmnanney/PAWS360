Redis + Sentinel role
=====================

Installs Redis and configures a simple Sentinel-managed cluster. This role is a starting point and must be adjusted for production.

Security notes:
- ACL / password: set `redis_password` (preferably via Ansible Vault or a secrets manager) and the templates will enable `requirepass` / `masterauth` for a minimal ACL configuration.
- TLS: enabling TLS for Redis requires a TLS-capable Redis build (or placing TLS in front of the service via an edge proxy like stunnel or HAProxy). This role does not create a TLS gateway automatically but can be extended to do so.

Responsibilities:
- Install redis-server
- Render redis.conf and sentinel.conf
- Enable services and ensure basic sentinel monitoring is in place
