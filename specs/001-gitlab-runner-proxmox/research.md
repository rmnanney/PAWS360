# Phase 0 Research: GitLab Runner on Proxmox

**Feature**: Enable GitLab Runner on local Proxmox (SCRUM-85)  
**Created**: 2025-11-30  
**Last Updated**: 2025-11-30 (final research round)

---

## Open questions resolved

### Decision 1 — Runner registration target
**Rationale**: Self-hosted GitLab instance (on-prem) reduces cross-network
complexity, keeps registration tokens internal, and aligns with private
inventory access requirements for deployment-related tasks. Using an on-prem
GitLab also simplifies observability and auditing for local runners.

*Alternatives considered*:
- GitLab.com — simpler for public repos but would complicate access to private
  network resources and may expose additional network configuration hurdles.
- Custom hybrid approach — supported if specific integration constraints exist.

### Decision 2 — Job executor
**Rationale**: Docker executor — provides per-job container isolation and
reproducibility at a moderate operational cost. It keeps jobs sandboxed and
reduces host contamination risk compared with shell executor.

*Alternatives considered*:
- Shell executor — simpler but reduces isolation and is not recommended for
  shared runners.
- Ephemeral VMs/LXC per job — strongest isolation but higher complexity and
  resource overhead; may be considered for high-security workloads later.

### Decision 3 — Runner scope
**Rationale**: Start with a restricted runner for builds/tests only. This
reduces attack surface and avoids exposing internal inventories during early
adoption. Provision a dedicated deployment runner later (separate instance)
after a formal security review if pre-deploy checks on internal targets are
required.

---

## Deployment pattern comparison (VM vs LXC vs system container)

| Option | Isolation | Docker-in-Docker | Provisioning | Notes |
|--------|-----------|------------------|--------------|-------|
| **KVM VM** (recommended) | Full hardware virt | Works out-of-box | ~2 min clone from template | Cleanest; best Docker support |
| **LXC privileged** | Namespace + cgroups | Requires nesting + capabilities | ~30 s create | Lighter; requires `features: nesting=1,keyctl=1` |
| **LXC unprivileged** | Strongest container isolation | Complex; often fails | ~30 s create | Not recommended for DinD |
| **Runner as container on host** | Shares host Docker | N/A (uses host daemon) | Instant | Couples runner to host lifecycle |

**Recommendation**: Use a lightweight KVM VM cloned from an existing cloud-init
template. The repo already has `infrastructure/ansible/roles/proxmox-template`
that handles template lookup and cloning.

---

## Docker executor specifics

### Executor workflow
1. Runner pulls job spec from GitLab.
2. Starts a container from the specified `image`.
3. Attaches helper container for clone/artifacts/cache.
4. Runs `before_script`, `script`, `after_script` inside job container.
5. Uploads artifacts/cache, then removes containers.

### Docker-in-Docker (DinD)
- Needed when CI jobs must run `docker build`, `docker push`.
- Requires `privileged: true` on the runner **or** rootless DinD with
  `services_privileged` and `allowed_privileged_services` whitelist.
- Safer alternative: use Kaniko or Buildah (no privileged needed).

### Recommended `config.toml` snippet
```toml
[[runners]]
  name = "proxmox-docker-runner"
  url = "https://gitlab.example.local"
  token = "REDACTED"
  executor = "docker"
  [runners.docker]
    image = "docker:stable"
    privileged = true          # for DinD; consider rootless alternative
    disable_cache = false
    volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
    pull_policy = ["always", "if-not-present"]
    allowed_images = ["docker:*", "maven:*", "node:*", "openjdk:*", "python:*"]
    allowed_services = ["docker:dind", "postgres:*", "redis:*"]
    shm_size = 268435456       # 256 MB
```

### Caching strategy
- **Distributed cache**: Configure `[runners.cache]` → S3 or MinIO.
- **Local cache**: Use Docker volumes (`/cache`) for single-runner setups.
- For layer caching in `docker build`, mount `/var/lib/docker` as a volume or
  use BuildKit with `--cache-from`.

---

## Secret & registration handling

| Approach | Pros | Cons |
|----------|------|------|
| **GitLab CI/CD protected variables** | Native; masked in logs | Accessible only during CI; not for infra playbooks |
| **Ansible Vault** | Versioned with repo | Requires decryption key management |
| **HashiCorp Vault** | Centralized; short-lived tokens | Extra infra component |
| **1Password/Bitwarden CLI** | Team-friendly | External dependency |

**Recommendation**: Store the GitLab **registration token** as a protected
CI/CD variable in the GitLab project or group. For Ansible runs, pass token
via `--extra-vars "@vault.yml"` (Ansible Vault encrypted).

### Non-interactive registration command
```bash
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.example.local" \
  --registration-token "$REG_TOKEN" \
  --executor docker \
  --docker-image "docker:stable" \
  --description "proxmox-vm-docker-runner" \
  --tag-list "proxmox-local,ci,docker" \
  --run-untagged="false" \
  --locked="true"
```

---

## Networking & storage recommendations

### Network requirements
| Service | Port | Direction | Notes |
|---------|------|-----------|-------|
| GitLab HTTPS | 443 | Runner → GitLab | API + Git clone |
| Docker registry | 5000 (or 443) | Runner → registry | Image pulls |
| SSH (optional) | 22 | Admin → Runner | Management |
| NTP | 123/UDP | Runner → NTP server | Time sync for TLS |

- Ensure DNS resolution of GitLab hostname from runner VM.
- If using internal CA, distribute `ca.pem` to runner and set `tls-ca-file`.

### Storage layout
| Mount | Purpose | Sizing |
|-------|---------|--------|
| `/` (root) | OS + gitlab-runner binary | 20 GB |
| `/var/lib/docker` | Docker images/containers | 50–100 GB SSD |
| `/cache` | CI cache volume | 20 GB |

For multiple runners sharing cache, configure MinIO bucket:
```toml
[runners.cache]
  Type = "s3"
  Shared = true
  [runners.cache.s3]
    ServerAddress = "minio.example.local:9000"
    BucketName = "gitlab-runner-cache"
    AccessKey = "ACCESSKEY"
    SecretKey = "SECRETKEY"
    Insecure = false
```

---

## Monitoring & observability

### Metrics to collect
- **Runner service**: `gitlab-runner` process up, last check-in timestamp.
- **Node metrics**: CPU, memory, disk I/O, network (via `node_exporter`).
- **Container metrics**: Per-job container CPU/memory (via `cAdvisor`).
- **Job metrics**: Duration, queue time, success/failure rate (from GitLab API
  or runner logs).

### Prometheus scrape targets
```yaml
scrape_configs:
  - job_name: gitlab-runner-node
    static_configs:
      - targets: ['runner-vm.example.local:9100']
  - job_name: gitlab-runner-cadvisor
    static_configs:
      - targets: ['runner-vm.example.local:8080']
```

### Alerting suggestions
| Alert | Condition | Severity |
|-------|-----------|----------|
| RunnerDown | `up{job="gitlab-runner-node"} == 0` for 5 m | Critical |
| HighDiskUsage | `node_filesystem_avail_bytes{mountpoint="/var/lib/docker"}` < 10 GB | Warning |
| JobQueueBacklog | GitLab pending jobs > 10 for 10 m | Warning |

---

## Ansible provisioning outline

### Proposed role structure
```
infrastructure/ansible/roles/gitlab-runner/
├── defaults/main.yml       # gitlab_url, runner_tags, docker_image defaults
├── tasks/
│   ├── main.yml            # orchestration
│   ├── install-docker.yml  # install Docker CE
│   ├── install-runner.yml  # install gitlab-runner package
│   ├── register-runner.yml # non-interactive registration
│   └── monitoring.yml      # install node_exporter, cadvisor
├── templates/
│   └── config.toml.j2      # runner config template
└── handlers/main.yml       # restart gitlab-runner
```

### Playbook sketch (`playbooks/provision-gitlab-runner.yml`)
```yaml
- name: Provision GitLab Runner on Proxmox VM
  hosts: runners
  become: true
  vars_files:
    - ../group_vars/runners.yml
  roles:
    - role: proxmox-template
      when: create_vm | default(false)
    - role: geerlingguy.docker
    - role: gitlab-runner
```

### Key variables (`group_vars/runners.yml`)
```yaml
gitlab_url: "https://gitlab.example.local"
gitlab_registration_token: "{{ vault_gitlab_registration_token }}"
runner_tags: ["proxmox-local", "ci", "docker"]
runner_executor: docker
runner_docker_image: "docker:stable"
runner_privileged: true
create_vm: true
vm_list:
  - name: gitlab-runner-01
    node: pve-node-1
    cores: 4
    memory: 8192
```

---

## Acceptance tests & CI validation

### Provision validation
1. Ansible reports `changed=0` on idempotent re-run.
2. `systemctl is-active gitlab-runner` → `active`.
3. Runner appears in GitLab UI (Settings → CI/CD → Runners) with correct tags.

### Functional validation (`.gitlab-ci.yml`)
```yaml
stages:
  - validate

runner-health:
  stage: validate
  tags: [proxmox-local]
  script:
    - echo "Runner is alive"
    - docker info   # verifies Docker access if privileged
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

### DinD validation (optional)
```yaml
build-test:
  stage: validate
  tags: [proxmox-local]
  image: docker:stable
  services:
    - docker:dind
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker build -t test-image:ci .
```

---

## Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Registration token leaked | Medium | High | Store in Vault/protected var; rotate regularly |
| Privileged container escape | Low | Critical | Limit `privileged` to DinD service only; use rootless DinD |
| Resource exhaustion | Medium | Medium | Set Docker memory/CPU limits; alert on disk usage |
| Runner offline (network) | Low | Medium | Add connectivity pre-check in deploy job |
| Stale runner config | Low | Low | Ansible idempotent runs; GitOps for config.toml |

---

## Next steps / Phase 1 inputs

- ✅ Data model (`data-model.md`) — completed
- ✅ Quickstart (`quickstart.md`) — completed
- ✅ OpenAPI contract (`contracts/provision-runner-openapi.yml`) — completed

## Phase 2 — Implementation tasks (ready to generate)

1. Create Ansible role skeleton at `infrastructure/ansible/roles/gitlab-runner/`.
2. Add playbook `infrastructure/ansible/playbooks/provision-gitlab-runner.yml`.
3. Add example variables `infrastructure/ansible/group_vars/runners.yml`.
4. Create minimal CI validation job in `specs/001-gitlab-runner-proxmox/quickstart.md`.
5. Update `requirements.yml` if new Galaxy roles needed.
6. Document operational runbook in `docs/gitlab-runner-operations.md`.
7. Add monitoring dashboards (Grafana JSON) under `monitoring/dashboards/`.
8. Create PR and request review.
