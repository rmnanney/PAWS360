# Feature Specification: Enable GitLab Runner on local Proxmox

**Feature Branch**: `001-gitlab-runner-proxmox`  
**Created**: 2025-11-30  
**JIRA**: SCRUM-85
**Status**: Draft  
**Input**: User request: "Enable a GitLab runner on local Proxmox infrastructure to facilitate deployment and expedite running tests or other GitLab CI/CD tasks that can be sped up on local infrastructure."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Provision and register a GitLab runner (Priority: P1)

As a developer or CI operator, I want a GitLab Runner provisioned on the local
Proxmox cluster and registered to our GitLab project (or group) so CI jobs can
execute on local infrastructure and reduce runtime latency for tests and builds.

**Why this priority**: This is core functionality — without a registered runner
CI jobs cannot execute on the local Proxmox infrastructure.

**Independent Test**: Submit a small CI job that prints environment info and
exits successfully on the new runner. Verify the job runs on the target runner
and returns success within the CI pipeline.

**Acceptance Scenarios**:

1. **Given** a configured Proxmox node with capacity for a runner VM/container,
   **When** the provisioning step is executed, **Then** a runner instance is
   created and visible in the GitLab UI as `001-gitlab-runner-proxmox` (or
   equivalent), and jobs can be targeted to it.
2. **Given** the runner is registered, **When** a representative test job is
   queued, **Then** the job is picked up by the runner and completes successfully.

---

### User Story 2 - Runner for deploy tasks with controlled network access (Priority: P2)

As an SRE or DevOps engineer, I want the runner to support deployment-related
jobs that require access to internal networks (e.g. private inventories or
internal package registries) while keeping host and secret access constrained
and auditable.

**Why this priority**: Deployment pipelines often need access to internal
services and secrets; providing a runner that can safely perform those tasks
enables full CI/CD validation in the local environment.

**Independent Test**: Configure a deployment-check job that attempts a dry-run
against a (staged) internal target reachable from the runner. The dry-run
must succeed or return a clearly documented connectivity diagnostic instead of
failing the whole pipeline.

**Acceptance Scenarios**:

1. **Given** required secrets and network access are configured for the runner,
   **When** a deployment dry-run job runs, **Then** it completes and reports
   success or a clear troubleshooting diagnostic (reachability, missing
   credentials) but does not leak secrets in CI logs.

---

### User Story 3 - Observability, lifecycle and automated re-provision (Priority: P3)

As an engineer operating local CI runners, I want basic observability and a
defined lifecycle (health checks, restart on failure, simple reprovisioning
steps) so the runner remains reliable over time and can be recovered quickly
without manual intervention.

**Why this priority**: Operational reliability matters for consistent CI runs
and to avoid developer interruptions.

**Independent Test**: Trigger a simulated failure (small resource exhaustion or
process restart) and confirm runner health checks detect it, attempt a
recovery (restart) and return to 'online' state in GitLab.

**Acceptance Scenarios**:

1. **Given** runner health monitoring is configured, **When** a temporary
   failure occurs, **Then** monitoring shows the failure, an automated recovery
   attempt takes place, and the runner becomes available again within agreed
   minutes.

---

### Edge Cases

- Network partitioning: Runner is provisioned but cannot reach GitLab or target
  hosts — runner must surface clear diagnostics and not expose secrets.
- Resource exhaustion: Provisioned runner runs out of CPU/memory — pipeline
  must be resilient (fail fast with a clear error) and operators must be able
  to reprovision the runner quickly.
- Secrets misconfiguration: Missing or invalid runner registration tokens or
  SSH keys must be detected and surfaced in CI as diagnostics, not raw secrets.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provision a runner instance on Proxmox that
  registers with the target GitLab instance (project or group), and the
  instance MUST be addressable from GitLab (registered in the runners list).
- **FR-002**: The runner MUST be able to execute representative CI jobs (test
  and build tasks) and report job status back to GitLab within the expected
  CI execution workflow.
- **FR-003**: The system MUST support a deployment-use configuration that can
  run jobs requiring access to internal inventory or private networks, with
  secrets management such that sensitive values are never printed in CI logs.
- **FR-004**: There MUST be minimal health and observability metrics (runner
  online/offline, last-check-in, recent job success/failures) available for
  basic operator monitoring.
- **FR-005**: The provisioning flow MUST be repeatable and documented so an
  operator can recreate or replace the runner with minimal manual steps.

### Key Entities *(include if feature involves infra/resources)*

- **Proxmox host(s)**: Physical or virtualized nodes hosting the runner VM or
  container (memory, CPU, disk capacity, networking details).
- **Runner instance**: The VM or container running the GitLab Runner process and
  providing an executor for CI jobs.
- **GitLab project/group**: The GitLab scope where the runner is registered and
  which defines which jobs it can pick up (project, group, shared).
- **Secrets/credentials**: Registration tokens, SSH keys, and other secrets the
  runner uses — MUST be stored securely and not printed to logs.
- **Network segments**: Internal networks and any firewalls required to reach
  internal deployment targets (for deployment-use runners).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A representative CI job (e.g., small unit-test job) must run and
  complete successfully on the new runner within 5 minutes of job scheduling
  in a normal test environment.
- **SC-002**: Runner should handle at least 1 concurrent job without resource
  failure for the initial MVP; documented scaling options evaluated before
  increasing concurrency.
- **SC-003**: Deployment dry-run jobs (when enabled) must produce either a
  successful check result or a clear reachability/credentials diagnostic; the
  workflow must not leak secrets in job logs.
- **SC-004**: Runner registration and last-check-in metrics must be visible in
  GitLab and updated within 2 minutes of runner being online.

## Constitution Check (mandatory)

Before this spec is accepted, confirm the following:
- JIRA/Epic referenced in the spec header and the ticket exists.
- Any infrastructure or automation changes reference or include `contexts/` entries
  with YAML frontmatter and last_updated date.
- Monitoring assessment included (metrics to collect, dashboards/alert plan) or
  a documented justification for no monitoring.
- If AI agents will act on this spec, note the `contexts/sessions/<owner>/` file
  and `current-session.yml` updates so the work remains auditable.

## Assumptions

- Default GitLab instance: Runner will register with the on-prem/self-hosted
  GitLab instance integrated with this infrastructure. This simplifies network
  access and simplifies secure registration token handling for local runners.
- Provisioning target: This spec assumes a Proxmox cluster capable of hosting
  lightweight VMs or LXC containers for runner execution.
- Secrets: Registration tokens and any SSH keys will be provided securely in a
  secrets manager or as repository/environment secrets at run-time; the project
  will not expose them in CI logs.
- Executor: The runner is expected to use the Docker executor by default to
  provide per-job isolation and reproducible execution environments on the
  Proxmox-hosted runner VM/container.

## Clarifications (finalized)

1. Runner registration target: Self-hosted on‑prem GitLab — this runner will
  register with the infrastructure's internal GitLab instance so tokens and
  network access remain local and auditable.

2. Executor choice: Docker executor — jobs run in isolated containers on the
  Proxmox-hosted runner VM/container, providing reproducibility and isolation.

3. Runner scope (decision): Restricted runner for builds/tests only — initial
  installation will provide a safe, limited-scope runner for CI builds and
  tests. A separate, dedicated deployment runner (with controlled network
  access) will be considered and provisioned later after security review.

- Q: Which GitLab instance should the runner register with? → A: Self-hosted GitLab instance (on-prem)

- Q: Which executor should be used for jobs on Proxmox? → A: Docker executor (isolated containers)

- Q: Scope for deployment jobs → B: Restricted runner (builds/tests only); dedicated deployment runner added later after security review
- Q: Which executor should be used for jobs on Proxmox? → A: Docker executor (isolated containers)
