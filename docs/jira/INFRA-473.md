# INFRA-473: Reliable Production Deployments with Failover

**Type:** Story  
**Epic:** INFRA-472  
**Priority:** P1 (Critical)  
**Status:** In Progress  
**Created:** 2025-01-XX  
**Reporter:** DevOps Team  
**Assignee:** SRE Team  

## User Story

**As a** DevOps engineer  
**I want** production deployments to succeed consistently with automatic failover  
**So that** service updates reach production reliably without manual intervention  

## Acceptance Criteria

### AC1: Runner Group Configuration
- [ ] Primary runner group created with "production" label
- [ ] Secondary runner group created with "production" label
- [ ] Both runner groups registered and healthy
- [ ] Runner configuration validated via GitHub API
- [ ] Ansible playbooks created for runner lifecycle management

### AC2: Failover Mechanism
- [ ] Workflow configured to attempt primary runner first
- [ ] Automatic failover to secondary runner on primary failure
- [ ] Failover triggers within 30 seconds of primary failure detection
- [ ] Failover events logged to monitoring system
- [ ] No duplicate deployments during failover transition

### AC3: Preflight Checks
- [ ] Script validates runner health before deployment
- [ ] Docker daemon availability verified
- [ ] Disk space threshold checked (≥10GB required)
- [ ] Network connectivity to deployment targets confirmed
- [ ] Required secrets validated for presence
- [ ] Preflight failures block deployment execution

### AC4: Health Gates
- [ ] Critical services validated post-deployment (API, DB, Redis)
- [ ] Health gate timeouts configured (5min max per service)
- [ ] Failed health gates trigger rollback alert
- [ ] Health status published to monitoring dashboard
- [ ] Deployment marked failed if any health gate fails

### AC5: Success Metrics
- [ ] Deployment success rate ≥95% measured over 30-day window
- [ ] p95 deployment duration ≤10 minutes
- [ ] Failover success rate ≥90%
- [ ] Zero secret leakage incidents
- [ ] Metrics collected and published to Prometheus

## Technical Requirements

### Runner Infrastructure
- Linux/x64 hosts (primary: production-runner-01, secondary: production-runner-02)
- GitHub Actions runner binary 2.x
- Docker Engine 20.10+ for containerized deployments
- Ephemeral/JIT runner configuration preferred
- Runner registration via GitHub API (no manual registration)

### Workflow Configuration
```yaml
jobs:
  deploy-to-production:
    runs-on: [self-hosted, linux, x64, production]
    concurrency:
      group: production-deploy
      cancel-in-progress: false
    steps:
      - name: Preflight checks
        run: ./scripts/deployment/preflight-checks.sh
      - name: Deploy with failover
        run: ./scripts/deployment/deploy-with-failover.sh
      - name: Health gates
        run: ./scripts/deployment/health-gates.sh
```

### Preflight Check Script
- Runner health validation (CPU, memory, disk)
- Docker daemon status
- Network connectivity (ping deployment targets)
- Secrets validation (no content inspection, presence only)
- Exit code 0 for success, non-zero for failure

### Health Gate Script
- API health endpoint check (`/health`)
- Database connectivity test (`pg_isready`)
- Redis connectivity test (`redis-cli ping`)
- Service-specific smoke tests
- Timeout handling (5min per service)

### Failover Logic
- Primary runner attempts deployment first
- On failure (exit code ≠ 0 or timeout), trigger secondary runner job
- Secondary runner executes identical deployment steps
- Log failover event with timestamp and reason
- Alert on-call if both primary and secondary fail

## Test Criteria

### Unit Tests
- [ ] Preflight check script validates all conditions correctly
- [ ] Health gate script handles timeouts appropriately
- [ ] Failover logic triggers on correct failure conditions
- [ ] Ansible playbooks execute without errors in check mode

### Integration Tests
- [ ] Staging deployment succeeds with primary runner
- [ ] Failover triggers correctly when primary runner disabled
- [ ] Preflight checks block deployment when conditions not met
- [ ] Health gates correctly identify service failures
- [ ] Metrics published to Prometheus staging instance

### End-to-End Tests
- [ ] Production deployment completes successfully via primary runner
- [ ] Failover tested by simulating primary runner failure
- [ ] All services healthy post-deployment (API, DB, Redis)
- [ ] Deployment duration within p95 target (≤10min)
- [ ] Audit logs confirm deployment attribution

## Deployment Verification

### Pre-Deployment
- Ansible inventory updated with production runner hosts
- Runner registration tokens generated and stored securely
- Workflow configuration validated via GitHub Actions linter
- Preflight checks pass on both primary and secondary runners

### During Deployment
- Real-time logs available via GitHub Actions UI
- Failover trigger tested (if applicable)
- No manual intervention required
- Monitoring dashboard shows runner activity

### Post-Deployment
- All services respond to health checks
- Deployment success logged to Prometheus
- Audit trail confirms deployment user and timestamp
- No alerts triggered in monitoring system

## Infrastructure Impact

### New Resources
- 2 Linux/x64 hosts for runners (primary + secondary)
- Runner registration in GitHub organization
- Ansible playbooks: `runner-provision.yml`, `runner-configure.yml`, `runner-decommission.yml`

### Modified Resources
- `.github/workflows/ci.yml`: Add concurrency control, failover logic
- `infrastructure/ansible/inventories/production/hosts`: Add runner hosts
- Monitoring stack: Add runner health dashboards

### Resource Requirements
- CPU: 4 cores per runner
- Memory: 8GB per runner
- Disk: 50GB per runner (deployments + Docker images)
- Network: 1Gbps connection to production infrastructure

## Dependencies

- INFRA-472 (Epic): Overall stabilization initiative
- Ansible inventory structure must be finalized
- GitHub organization admin access for runner registration
- Production infrastructure addresses (from authoritative source)
- Monitoring stack operational (Prometheus/Grafana)

## Risk Mitigation

- **Risk**: Primary runner failure during critical deployment  
  **Mitigation**: Secondary runner pre-provisioned and tested

- **Risk**: Preflight checks too strict, block legitimate deployments  
  **Mitigation**: Thresholds configurable, manual override available

- **Risk**: Health gates timeout during slow service startup  
  **Mitigation**: Timeout values tunable per service, retries configurable

## Documentation

- [ ] Context file created: `contexts/infrastructure/github-runners.md`
- [ ] Deployment pipeline context updated: `contexts/infrastructure/deployment-pipeline.md`
- [ ] Ansible inventory guide: `docs/infrastructure/ansible-runner-inventory.md`
- [ ] Runbook created: `docs/runbooks/runner-failover.md`

## Constitutional Compliance

- **Article I**: JIRA ticket created before implementation starts ✓
- **Article II**: Context files maintained throughout implementation
- **Article VIIa**: Monitoring uses Ansible inventory variables (no hardcoded IPs)
- **Article X**: Accurate status reporting via JIRA updates and monitoring metrics
- **Article XIII**: Proactive compliance checks embedded in preflight script

## Links

- Epic: INFRA-472
- Spec: `specs/001-github-runner-deploy/spec.md` (User Story 1)
- Tasks: `specs/001-github-runner-deploy/tasks.md` (Phase 3: T021-T041)

## Notes

This is the MVP user story (Priority 1). Implementation must be complete and validated before proceeding to INFRA-474 and INFRA-475. No time constraints - comprehensive testing required at every phase.
