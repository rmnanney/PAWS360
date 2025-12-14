# Artifact Cache Playbook

This playbook provisions local artifact caches to speed up CI and builds.

What it provisions:
- Sonatype Nexus (Docker container) for Maven proxy on port 8081
- Optional Docker registry pull-through cache on port 5000

Usage:

1. Run the playbook against the host you want to host the services (e.g. `webservers`):

```bash
ansible-playbook -i inventories/staging/hosts playbooks/provision-artifact-caches.yml
```

2. To enable the Docker registry mirror, set `enable_registry_mirror=true` when running the playbook:

```bash
ansible-playbook -i inventories/staging/hosts playbooks/provision-artifact-caches.yml -e enable_registry_mirror=true
```

3. Configure Maven clients to use the Nexus mirror by running the `maven-client` role against runner hosts; the playbook can be extended to do this automatically.

TLS / Reverse Proxy:
- This playbook does not automatically configure TLS. If you have a reverse proxy (nginx) and `geerlingguy.certbot` available, add tasks to configure an upstream and obtain Let's Encrypt certificates. We can add that if you want TLS enabled by default.
