# Tasks: GitLab Runner on Proxmox

**Input**: Design documents from `/specs/001-gitlab-runner-proxmox/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/provision-runner-openapi.yml, quickstart.md  
**Branch**: `001-gitlab-runner-proxmox`  
**JIRA**: SCRUM-85

**Tests**: Not explicitly requested in spec - tasks focus on infrastructure provisioning and validation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Ansible structure

- [x] T001 Create Ansible role directory structure at `infrastructure/ansible/roles/gitlab-runner/` with subdirectories: defaults/, tasks/, templates/, handlers/
- [x] T002 [P] Create defaults file at `infrastructure/ansible/roles/gitlab-runner/defaults/main.yml` with variables: gitlab_url, runner_tags, runner_executor, runner_docker_image, runner_privileged
- [x] T003 [P] Create example inventory file at `infrastructure/ansible/inventories/runners/hosts` with runner group definition
- [x] T004 [P] Update `infrastructure/ansible/requirements.yml` to ensure geerlingguy.docker role is listed (verify existing entry)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core Ansible roles and playbook structure that MUST be complete before ANY user story provisioning

**⚠️ CRITICAL**: No runner provisioning can begin until this phase is complete

- [x] T005 Create main playbook at `infrastructure/ansible/playbooks/provision-gitlab-runner.yml` with hosts: runners, become: true, and role invocations for proxmox-template (conditional), geerlingguy.docker, and gitlab-runner
- [x] T006 [P] Create task orchestration file at `infrastructure/ansible/roles/gitlab-runner/tasks/main.yml` that includes install-docker.yml, install-runner.yml, register-runner.yml, monitoring.yml
- [x] T007 [P] Create handlers file at `infrastructure/ansible/roles/gitlab-runner/handlers/main.yml` with "restart gitlab-runner" handler
- [x] T008 [P] Create group_vars at `infrastructure/ansible/group_vars/runners.yml` with example variables: gitlab_url, gitlab_registration_token (vault reference), runner_tags, create_vm, vm_list

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Provision and register a GitLab runner (Priority: P1) 🎯 MVP

**Goal**: Provision a runner VM on Proxmox, install Docker and GitLab Runner, register with GitLab, verify with a test job

**Independent Test**: Submit a small CI job (echo "Hello from local runner") with tag `proxmox-local` and confirm it runs successfully on the new runner

### Implementation for User Story 1

- [x] T009 [P] [US1] Create Docker installation task at `infrastructure/ansible/roles/gitlab-runner/tasks/install-docker.yml` that invokes geerlingguy.docker role
- [x] T010 [P] [US1] Create runner installation task at `infrastructure/ansible/roles/gitlab-runner/tasks/install-runner.yml` that adds GitLab Runner package repository and installs gitlab-runner package
- [x] T011 [US1] Create runner registration task at `infrastructure/ansible/roles/gitlab-runner/tasks/register-runner.yml` with non-interactive gitlab-runner register command using variables from defaults
- [x] T012 [P] [US1] Create config.toml template at `infrastructure/ansible/roles/gitlab-runner/templates/config.toml.j2` with Docker executor configuration, privileged mode, volumes, pull_policy, allowed_images, allowed_services
- [x] T013 [US1] Add task to deploy config.toml template to `/etc/gitlab-runner/config.toml` in `tasks/register-runner.yml` and notify restart handler
- [x] T014 [US1] Add VM provisioning variables to `group_vars/runners.yml`: vm_list with name: gitlab-runner-01, node: pve-node-1, cores: 4, memory: 8192
- [x] T015 [US1] Create validation CI job file at `specs/001-gitlab-runner-proxmox/validation/runner-health.gitlab-ci.yml` with job that tags: [proxmox-local], script: echo + docker info
- [x] T016 [US1] Document provisioning steps in `specs/001-gitlab-runner-proxmox/quickstart.md` (update existing with Ansible command: ansible-playbook -i inventories/runners playbooks/provision-gitlab-runner.yml)
- [x] T017 [US1] Add idempotence validation: re-run playbook and verify changed=0 for all tasks

**Checkpoint**: At this point, User Story 1 should be fully functional - a runner is provisioned, registered, and can execute jobs

---

## Phase 4: User Story 2 - Runner for deploy tasks with controlled network access (Priority: P2)

**Goal**: Configure runner to support deployment dry-run jobs with network access to internal targets and secure secret handling

**Independent Test**: Create a deployment-check job that performs connectivity test to internal service and confirms either success or clear diagnostic without leaking secrets

### Implementation for User Story 2

- [x] T018 [P] [US2] Add network configuration variables to `group_vars/runners.yml`: required_networks (CIDR list), deployment_targets (hostname list for connectivity checks)
- [x] T019 [P] [US2] Create network validation task at `infrastructure/ansible/roles/gitlab-runner/tasks/validate-network.yml` that checks DNS resolution and HTTPS connectivity to GitLab URL
- [x] T020 [US2] Add secret reference documentation to `infrastructure/ansible/roles/gitlab-runner/README.md` explaining Ansible Vault usage for gitlab_registration_token and where to store vault password
- [x] T021 [US2] Create deployment validation job at `specs/001-gitlab-runner-proxmox/validation/deploy-dry-run.gitlab-ci.yml` with connectivity checks to internal targets (masked output for any credentials)
- [x] T022 [US2] Add firewall rules task at `infrastructure/ansible/roles/gitlab-runner/tasks/configure-firewall.yml` to allow outbound HTTPS (443), NTP (123), and SSH (22) if needed
- [x] T023 [US2] Update config.toml.j2 template to include volume mounts for cache: /cache and conditional docker socket mount
- [x] T024 [US2] Document deployment runner security constraints in `docs/gitlab-runner-operations.md` (create new file): restricted tags, network access, secret handling best practices

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - runner can execute builds/tests AND deployment dry-runs with proper network access

---

## Phase 5: User Story 3 - Observability, lifecycle and automated re-provision (Priority: P3)

**Goal**: Add health monitoring (node_exporter, cAdvisor), Prometheus integration, and playbook for runner reprovisioning

**Independent Test**: Trigger simulated failure (systemctl stop gitlab-runner), verify monitoring detects it, manually restart, confirm recovery in monitoring dashboard

### Implementation for User Story 3

- [x] T025 [P] [US3] Create monitoring installation task at `infrastructure/ansible/roles/gitlab-runner/tasks/monitoring.yml` that installs node_exporter and cAdvisor using package manager or systemd services
- [x] T026 [P] [US3] Add Prometheus scrape configuration template at `monitoring/prometheus/gitlab-runner-targets.yml` with job_name: gitlab-runner-node (port 9100) and gitlab-runner-cadvisor (port 8080)
- [x] T027 [P] [US3] Create Grafana dashboard JSON at `monitoring/dashboards/gitlab-runner-dashboard.json` with panels for: runner status, CPU/memory, disk usage, container metrics, job duration
- [x] T028 [US3] Add alerting rules file at `monitoring/prometheus/alerts/gitlab-runner.yml` with alerts: RunnerDown, HighDiskUsage, JobQueueBacklog
- [x] T029 [US3] Create reprovisioning playbook at `infrastructure/ansible/playbooks/reprovision-gitlab-runner.yml` that unregisters old runner, removes VM, then invokes provision playbook
- [x] T030 [US3] Add health check endpoint validation task in `tasks/monitoring.yml` that verifies node_exporter responds on port 9100
- [x] T031 [US3] Document monitoring setup in `docs/gitlab-runner-operations.md`: Prometheus target configuration, Grafana dashboard import, alert notification setup
- [x] T032 [US3] Add lifecycle documentation to `docs/gitlab-runner-operations.md`: manual restart procedure, reprovisioning command, backup/restore of config.toml

**Checkpoint**: All user stories should now be independently functional - runner is provisioned, supports deployment, and has full observability
- [ ] T030 [US3] Add health check endpoint validation task in `tasks/monitoring.yml` that verifies node_exporter responds on port 9100
- [ ] T031 [US3] Document monitoring setup in `docs/gitlab-runner-operations.md`: Prometheus target configuration, Grafana dashboard import, alert notification setup
- [ ] T032 [US3] Add lifecycle documentation to `docs/gitlab-runner-operations.md`: manual restart procedure, reprovisioning command, backup/restore of config.toml

**Checkpoint**: All user stories should now be independently functional - runner is provisioned, supports deployment, and has full observability

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation, and final integration

- [x] T033 [P] Create operational runbook at `docs/gitlab-runner-operations.md` (expand existing) with sections: provisioning, troubleshooting, monitoring, reprovisioning, scaling to multiple runners
- [x] T034 [P] Add DinD validation job (optional) at `specs/001-gitlab-runner-proxmox/validation/docker-build-test.gitlab-ci.yml` with docker:dind service and simple docker build command
- [x] T035 Update main README.md with link to gitlab-runner-operations.md and quick reference for provisioning command
- [x] T036 [P] Add security hardening checklist to `docs/gitlab-runner-security.md`: privileged mode justification, allowed_images restrictions, secret rotation schedule, network segmentation
- [x] T037 Run full quickstart.md validation: provision VM, register runner, execute validation jobs, verify monitoring
- [x] T038 Update `contexts/infrastructure/gitlab-runner-proxmox.md` with final ansible_playbook path and monitoring endpoints
- [x] T039 Create session summary at `contexts/sessions/ryan/2025-11-30-gitlab-runner-provisioning.md` (update existing) with implementation notes and decisions
- [x] T040 Run constitution check: verify JIRA linkage (SCRUM-85), contexts files present, monitoring configured, agent session recorded

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational (Phase 2) completion
  - User stories CAN proceed in parallel if staffed (each is independently testable)
  - Or sequentially in priority order: US1 (P1) → US2 (P2) → US3 (P3)
- **Polish (Phase 6)**: Depends on completion of US1 (MVP minimum) or all user stories for full feature

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories ✅ MVP
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent of US1 (adds network/deployment capabilities to existing runner)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independent of US1/US2 (adds monitoring overlay to existing runner)

### Within Each User Story

**User Story 1**:
1. Tasks T009-T010 can run in parallel (Docker install, runner install)
2. T011 depends on T010 (registration needs runner binary)
3. T012-T013 can run in parallel with T009-T011 (config template and deployment)
4. T014-T017 are sequential validation and documentation

**User Story 2**:
1. T018-T020 can run in parallel (configuration additions)
2. T021-T024 can run in parallel (validation jobs, documentation)

**User Story 3**:
1. T025-T028 can run in parallel (monitoring components)
2. T029-T032 are sequential documentation tasks

### Parallel Opportunities

**Maximum parallelization** (if 4 engineers available):
- Phase 1 (Setup): 1 engineer - 4 tasks can be done in parallel after T001
- Phase 2 (Foundational): 1 engineer - T005-T008 mostly parallel
- Phase 3 (US1): 2 engineers - T009/T010, T012/T013 parallel streams
- Phase 4 (US2): 2 engineers - T018-T024 mostly parallel
- Phase 5 (US3): 2 engineers - T025-T028 parallel
- Phase 6 (Polish): 3 engineers - T033-T040 mostly parallel

**Recommended MVP execution** (1-2 engineers):
1. Complete Phase 1 & 2 sequentially (foundational work)
2. Complete US1 (Phase 3) fully - achieves basic runner provisioning ✅ MVP STOP HERE
3. (Optional) Add US2 for deployment support
4. (Optional) Add US3 for monitoring
5. Complete Phase 6 for production readiness

### Story Completion Checkpoints

Each checkpoint verifies independent functionality:

- ✅ **After US1**: Can provision runner and execute basic CI jobs
- ✅ **After US2**: Runner can also perform deployment dry-runs
- ✅ **After US3**: Runner has full monitoring and lifecycle management

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)
**Deliver User Story 1 ONLY** - this provides:
- Provisioned runner VM on Proxmox
- GitLab Runner registered with Docker executor
- Basic CI job validation (test job runs successfully)
- Foundation for future deployment and monitoring enhancements

**Estimated effort**: ~8-12 tasks (Phase 1, Phase 2, US1 only)

### Incremental Delivery Plan

1. **Sprint 1 - MVP** (US1): Core runner provisioning and registration
2. **Sprint 2** (US2): Add deployment capabilities and network access
3. **Sprint 3** (US3): Add monitoring, alerting, and lifecycle automation
4. **Sprint 4** (Polish): Documentation, security hardening, full validation

### Risk Mitigation

- **Proxmox API access**: Verify existing `proxmox-template` role works before starting US1
- **GitLab registration token**: Prepare token in Ansible Vault during Phase 1
- **Docker privileged mode**: Document security implications in US1, consider rootless alternatives in US2
- **Network access**: Test connectivity to GitLab from Proxmox network before US1 registration

---

## Summary

- **Total Tasks**: 40
- **MVP Tasks**: 17 (Phase 1: 4, Phase 2: 4, US1: 9)
- **User Story 1 (P1)**: 9 tasks - provision and register runner ✅ MVP
- **User Story 2 (P2)**: 7 tasks - deployment capabilities
- **User Story 3 (P3)**: 8 tasks - monitoring and lifecycle
- **Polish**: 8 tasks - documentation and validation
- **Parallel Opportunities**: 20+ tasks can run in parallel with sufficient staffing
- **Independent Test Criteria**: Each user story has clear validation job/test
- **Suggested MVP**: Phase 1 + Phase 2 + User Story 1 (17 tasks total)

**Next Steps**: Begin with Phase 1 (Setup) → Phase 2 (Foundational) → User Story 1 (MVP)
