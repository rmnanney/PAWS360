# Deployment Safeguard Architecture

**Document Version**: 1.0  
**Last Updated**: 2025-12-11  
**JIRA**: INFRA-475 (User Story 3 - Protect production during deploy anomalies)  
**Status**: Implemented

## Executive Summary

This document describes the comprehensive safeguard system that protects production during deployment anomalies. The system prevents partial deployments, automatically rolls back failed deployments, and ensures production stability through transaction safety, health validation, and automated recovery.

**Key Capabilities:**
- **Transaction Safety**: Atomic deployments with automatic rollback on failure
- **Health Validation**: Comprehensive post-deployment checks across all components
- **Automatic Recovery**: Failed deployments trigger rollback without manual intervention
- **Incident Tracking**: All rollbacks create incident issues requiring post-mortem
- **State Preservation**: Pre-deployment state captured for forensics and recovery

## Constitutional Compliance

- **Article X (Truth & Partnership)**: All state transitions are validated and logged
- **Article XIII (Constitutional Retrospective)**: Post-mortem required for all rollback incidents
- **Article VIIa (Monitoring Discovery)**: Comprehensive metrics and alerts for all safeguards

## Safeguard Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Production Deployment                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │  Pre-Deployment State Capture │
              │  (capture-production-state.sh)│
              └───────────────┬───────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │   Transaction Safety Block    │
              │  (Ansible block/rescue)       │
              └───────────────┬───────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
        ┌──────────────┐          ┌──────────────┐
        │  Deployment  │          │   Rescue     │
        │   Execution  │─────────►│   Block      │
        │  (3 steps)   │  Failure │  (Rollback)  │
        └──────┬───────┘          └──────┬───────┘
               │                         │
               │ Success                 │ Rollback
               ▼                         ▼
        ┌─────────────────────────────────────┐
        │  Comprehensive Health Checks        │
        │  (8 categories, 20+ checks)         │
        └──────┬──────────────────────┬───────┘
               │                      │
               │ Pass                 │ Fail
               ▼                      ▼
        ┌─────────────┐      ┌───────────────────┐
        │  Success    │      │  Automatic        │
        │  Completion │      │  Rollback         │
        └─────────────┘      └─────────┬─────────┘
                                       │
                                       ▼
                          ┌────────────────────────┐
                          │  Incident Tracking     │
                          │  (GitHub issue, Slack, │
                          │   PagerDuty, metrics)  │
                          └────────────────────────┘
```

## Safeguard Mechanisms

### 1. Pre-Deployment State Capture

**Purpose**: Capture current production state before deployment for rollback reference and forensics.

**Implementation**: `scripts/deployment/capture-production-state.sh`

**Captured Data**:
- Backend version (from `/opt/paws360/backend/version.txt`)
- Frontend version (from `/var/www/paws360/version.txt`)
- Database schema version (from Flyway migration history)
- Service status (systemd `is-active` for all services)
- System metrics (uptime, load average, disk usage)
- Deployment history (last 3 deployments)

**Output Format**: Structured JSON with timestamp and metadata

**Storage**: 
- Artifact uploaded to GitHub Actions for workflow access
- Local backup on production server: `/var/backups/deployment-state/`

**Example Output**:
```json
{
  "timestamp": "2025-12-11T10:30:00Z",
  "host": "production-web-01",
  "versions": {
    "backend": "v1.2.3",
    "frontend": "v1.2.3",
    "database": "V20250101__schema_update"
  },
  "services": {
    "backend": "active",
    "frontend": "active",
    "database": "active"
  },
  "system": {
    "uptime_since": "2025-12-01T08:00:00Z",
    "load_average": {"1min": "0.45", "5min": "0.52", "15min": "0.48"},
    "disk_usage": "45%"
  }
}
```

### 2. Transaction Safety (Ansible Block/Rescue)

**Purpose**: Wrap deployment in atomic transaction with automatic rollback on failure.

**Implementation**: `infrastructure/ansible/playbooks/production-deploy-transactional.yml`

**Architecture Pattern**: Ansible `block/rescue/always`

```yaml
- name: Deployment Transaction
  block:
    # Pre-deployment
    - Create state backup
    - Create deployment lock
    
    # Deployment steps (3-phase)
    - Deploy backend (stop, backup, extract, start)
    - Deploy frontend (stop, backup, extract, start)
    - Run database migrations
    
    # Post-deployment
    - Run health checks
    - Update production state file
  
  rescue:
    # Automatic rollback on any failure
    - Log failure details
    - Stop all services
    - Restore from state backup
    - Restart all services
    - Verify rollback health
    - Create incident issue
  
  always:
    # Cleanup (always runs)
    - Remove deployment lock
    - Clean temporary files
```

**Failure Triggers**:
- Any task failure in deployment block
- Health check failure
- Service start failure
- Database migration failure

**Rollback Process**:
1. Load state backup from pre-deployment capture
2. Stop all services (prevent partial state)
3. Restore backend from backup artifact
4. Restore frontend from backup artifact
5. Restore database (if migrations were applied)
6. Restart all services
7. Run health checks to verify rollback success
8. Trigger incident tracking

### 3. Comprehensive Health Checks

**Purpose**: Validate deployment success across all components before finalizing.

**Implementation**: `infrastructure/ansible/roles/deployment/tasks/comprehensive-health-checks.yml`

**Check Categories** (8 categories, 20+ individual checks):

**Backend Checks** (4 checks):
- Health endpoint (`/actuator/health`) returns `UP`
- API responsiveness (`/api/health`) returns 200
- Version verification (deployed version matches target)
- Info endpoint validation

**Frontend Checks** (5 checks):
- Homepage loads (status 200)
- Login page loads (status 200)
- Critical pages load (courses, enrollment-date, finances, academics)
- Version verification (matches backend)

**Database Checks** (3 checks):
- Connectivity (postgresql_ping)
- Schema version (Flyway history query)
- Table count validation (at least 10 tables)

**Redis/Cache Checks** (3 checks, conditional):
- Connectivity (PING → PONG)
- Memory usage (INFO memory)
- Cache statistics (hits/misses)

**External Integrations** (1 check, optional, non-blocking):
- External API health endpoint
- Warning only (doesn't fail deployment)

**System Resource Checks** (3 checks):
- Disk space (<90% usage)
- Memory usage (warning if >80%)
- CPU load average (warning if >2.0)

**Retry Logic**:
- Critical checks: 3 attempts with 5-second delay
- Page loads: 2 attempts with 5-second delay
- Timeout: 30 seconds per check (configurable)

**Failure Handling**:
- Any critical check failure triggers rescue block (rollback)
- Warnings logged but don't fail deployment
- Diagnostics captured on failure (logs, service status)

### 4. Enhanced Rollback Playbook

**Purpose**: Safely roll back production deployment with comprehensive validation.

**Implementation**: `infrastructure/ansible/playbooks/rollback-production-safe.yml`

**Safety Features**:

**Pre-Rollback Validation**:
- Verify target version artifacts exist
- Validate required variables (target_version, failed_version, rollback_reason)
- Check artifact integrity

**Forensics Capture** (optional, enabled by default):
- Capture failed backend state
- Capture failed frontend state
- Capture service logs (last 5 minutes)
- Create metadata file with incident details
- Storage: `/var/backups/deployment-forensics/[failed_version]-[timestamp]/`

**Rollback Execution**:
- Stop all services (prevent partial state)
- Backup current (failed) deployment
- Remove current deployment
- Extract target version artifacts
- Update version files
- Start all services
- Wait for stabilization (10 seconds)

**Post-Rollback Validation**:
- Run comprehensive health checks (same as deployment)
- Verify services running
- Assert versions match target
- Update production state file

**Failure Recovery**:
- If rollback fails: create critical incident marker
- Capture diagnostic logs
- Fail with clear error message requiring manual intervention

### 5. Automatic Rollback Trigger

**Purpose**: Automatically invoke rollback on health check failure without manual intervention.

**Implementation**: Integrated into `production-deploy-transactional.yml` rescue block

**Trigger Conditions**:
- Any health check failure (critical checks only)
- Service start failure
- Database migration failure
- Version verification mismatch

**Rollback Flow**:
```
Health Check Fails
      │
      ▼
Rescue Block Triggered
      │
      ▼
Load State Backup
      │
      ▼
Execute Rollback (3-step)
      │
      ▼
Post-Rollback Health Checks
      │
      ├──► Success: Log rollback completion
      │
      └──► Failure: Create CRITICAL incident marker
```

**Notification**:
- Rollback completion logged in Ansible output
- Incident issue created via `notify-rollback.sh`
- Metrics emitted to Prometheus
- Alerts fired via Prometheus alert rules

### 6. Deployment Coordination Lock

**Purpose**: Prevent concurrent deployments that could cause race conditions or partial state.

**Implementation**: GitHub Environment protection + concurrency control

**Mechanism**:
```yaml
# .github/workflows/ci.yml
jobs:
  deploy-to-production:
    environment: production  # Environment protection
    concurrency:
      group: production-deployment
      cancel-in-progress: false  # Queue, don't cancel
```

**Behavior**:
- Only one deployment to production at a time
- Subsequent deployments queued (not canceled)
- Lock released on completion or failure
- Timeout: GitHub Actions workflow timeout (default: 6 hours)

**Lock Release Conditions**:
1. **Success**: Deployment completes, health checks pass
2. **Failure**: Deployment fails, rollback completes
3. **Cancellation**: Workflow manually canceled
4. **Timeout**: Workflow exceeds timeout (rare)

**Documentation**: `docs/deployment/github-environment-protection.md`

### 7. Incident Tracking and Notification

**Purpose**: Track all rollback incidents and require post-mortem analysis.

**Implementation**: `scripts/ci/notify-rollback.sh`

**Incident Workflow**:

**GitHub Issue Creation**:
- Title: `[Production Rollback] [failed_version] → [rollback_version]`
- Labels: `production-rollback`, `incident`, `high-priority`
- Body includes:
  - Timestamp
  - Failed version
  - Rollback version
  - Failure reason
  - JIRA ticket link
  - Required actions checklist
  - Forensics location
  - Post-mortem requirement (Article XIII)

**Notifications**:
- **Slack**: Webhook notification with structured attachment
- **PagerDuty**: High-urgency incident creation
- **Prometheus**: Metrics emitted to pushgateway

**JIRA Linking**:
- Comment added to GitHub issue with JIRA ticket
- JIRA ticket linked in issue body

**Post-Mortem Requirement**:
- All rollback incidents require post-mortem within 48 hours
- Template: `.specify/templates/deployment-rollback-postmortem.md`
- Storage: `contexts/retrospectives/deployment-rollbacks/`
- Constitutional Article XIII compliance

## Deployment Flow Diagram

### Successful Deployment

```
┌─────────────┐
│  CI Trigger │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ Capture State    │ (T069)
│ (pre-deployment) │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Lock Acquired    │ (T071)
│ (concurrency)    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Deploy Backend   │ (T068)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Deploy Frontend  │ (T068)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Database Migrate │ (T068)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Health Checks    │ (T072)
└──────┬───────────┘
       │ All Pass
       ▼
┌──────────────────┐
│ Update State     │
│ Release Lock     │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ ✅ Success       │
└──────────────────┘
```

### Failed Deployment with Rollback

```
┌─────────────┐
│  CI Trigger │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ Capture State    │ (T069)
│ State: v1.2.3    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Lock Acquired    │ (T071)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Deploy Backend   │ (T068)
│ Target: v1.2.4   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Deploy Frontend  │ (T068)
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Health Checks    │ (T072)
│ ❌ FAILED        │
└──────┬───────────┘
       │ Rescue Block
       ▼
┌──────────────────┐
│ Capture          │ (T074)
│ Forensics        │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Load State       │ (T070)
│ Backup: v1.2.3   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Rollback         │ (T074)
│ To: v1.2.3       │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Post-Rollback    │ (T074)
│ Health Checks    │
└──────┬───────────┘
       │ Pass
       ▼
┌──────────────────┐
│ Create Incident  │ (T075)
│ Issue #123       │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Release Lock     │
│ ✅ Rolled Back   │
└──────────────────┘
```

## Monitoring and Alerting

### Prometheus Alerts

**Implementation**: `infrastructure/ansible/roles/cloudalchemy.prometheus/files/deployment-safeguard-alerts.yml`

**Critical Alerts**:
- `DeploymentRollbackTriggered`: Any automatic rollback (requires post-mortem)
- `MultipleRollbacksInWindow`: >1 rollback per hour (escalate to senior SRE)
- `DeploymentHealthCheckFailed`: Health checks failed after deployment
- `DeploymentPartialState`: Inconsistent state detected (safeguard failure)

**Warning Alerts**:
- `DeploymentTakingTooLong`: Deployment >10 minutes
- `DeploymentSuccessRateLow`: Success rate <95% (SC-001 violation)
- `SafeguardMetricsMissing`: Monitoring infrastructure broken

**Info Alerts**:
- `DeploymentQueueBacklog`: >2 deployments queued
- `DeploymentConcurrencyLockStale`: Lock held >15 minutes

### Grafana Dashboard

**Implementation**: `monitoring/grafana/dashboards/deployment-pipeline.json`

**Safeguard Panels** (6 new panels):
1. **Rollback Count by Reason**: Graph showing rollback frequency by failure reason
2. **Health Check Failure Rate**: Graph showing health check failures over time
3. **Deployment Success vs Rollback Ratio**: Gauge showing success percentage (target: 95%)
4. **Time to Detect and Rollback Failures**: Heatmap showing rollback duration distribution
5. **Deployment Safeguard Status**: Stat panel showing transaction safety enabled, rollback count, health check failures
6. **Rollback Incidents Table**: Table listing recent rollback incidents with details

## Testing and Validation

### Test Scenarios

**Test Suite**: `tests/ci/test-deploy-*.sh` (4 scenarios)

1. **T064**: Mid-deployment interruption rollback
2. **T065**: Health check failure rollback
3. **T066**: Partial deployment prevention
4. **T067**: Safe retry after safeguard trigger

**Smoke Tests**: `tests/smoke/post-deployment-smoke-tests.sh` (14 tests)
- Core infrastructure (homepage, login, API health)
- Critical functionality (courses, enrollment, finances, academics)
- Data integrity (database connectivity, version consistency)
- Error handling (404 page)

**Idempotency Tests**: `tests/deployment/test-idempotency.sh` (5 tests)
- Deploy same version twice (no-op on second)
- Deploy, rollback, re-deploy (success)
- Interrupted deployment re-run (convergence)
- Partial state cleanup (no residual artifacts)
- Check mode (no changes)

### Validation Checklist

Before marking User Story 3 complete:
- [ ] All test scenarios pass in staging (T084)
- [ ] Chaos engineering drill successful (T085)
- [ ] Monitoring alerts firing correctly
- [ ] Grafana dashboard displaying all panels
- [ ] Incident tracking workflow tested
- [ ] Post-mortem template created
- [ ] Documentation complete
- [ ] JIRA story updated

## Operational Procedures

### Runbooks

1. **Production Deployment Failures**: `docs/runbooks/production-deployment-failures.md`
2. **Runner Offline - Restore Service**: `docs/runbooks/runner-offline-restore.md`
3. **Network Unreachable Troubleshooting**: `docs/runbooks/network-unreachable-troubleshooting.md`

### Post-Mortem Template

**Location**: `.specify/templates/deployment-rollback-postmortem.md`

**Required Sections**:
- Incident timeline
- Root cause analysis
- Contributing factors
- Remediation steps taken
- Preventive measures
- Action items
- Lessons learned

**Storage**: `contexts/retrospectives/deployment-rollbacks/[date]-[failed_version].md`

## Success Criteria

**SC-001**: Deployment success rate ≥95%
- **Measurement**: `(sum(deployment_completed_total{status="success"}) / sum(deployment_completed_total)) * 100`
- **Target**: ≥95%
- **Alert**: `DeploymentSuccessRateLow` (warning if <95%)

**SC-002**: Deployment duration p95 ≤10 minutes
- **Measurement**: `histogram_quantile(0.95, deployment_duration_seconds_bucket)`
- **Target**: ≤600 seconds
- **Alert**: `DeploymentTakingTooLong` (warning if >600s)

**SC-003**: No partial deployments in production
- **Measurement**: `deployment_state_inconsistency_detected`
- **Target**: 0
- **Alert**: `DeploymentPartialState` (critical if >0)

**SC-004**: All rollbacks tracked and resolved
- **Measurement**: Open GitHub issues with `production-rollback` label
- **Target**: All closed with post-mortem within 48 hours
- **Validation**: Manual review of incident issues

## Future Enhancements

**Potential Improvements**:
- Blue-green deployment strategy (zero-downtime)
- Canary deployments (gradual rollout with health monitoring)
- Automated rollback decision (ML-based anomaly detection)
- Database rollback automation (schema versioning)
- Multi-region deployment coordination

**Monitoring Enhancements**:
- Deployment success prediction (ML-based)
- Anomaly detection in health checks
- Performance regression detection
- User-facing impact metrics

## References

- **JIRA Epic**: INFRA-472 (Stabilize Production Deployments via CI Runners)
- **User Story**: INFRA-475 (Protect production during deploy anomalies)
- **Tasks**: T064-T085 (22 tasks)
- **Success Criteria**: `specs/001-github-runner-deploy/spec.md` (SC-001, SC-002, SC-003, SC-004)
- **Test Scenarios**: `tests/ci/test-deploy-*.sh`, `tests/smoke/post-deployment-smoke-tests.sh`
- **Playbooks**: `infrastructure/ansible/playbooks/production-deploy-transactional.yml`, `rollback-production-safe.yml`

## Change Log

- **2025-12-11**: Initial version (INFRA-475, T080)
  - Documented all safeguard mechanisms
  - Added deployment flow diagrams
  - Included monitoring and alerting details
  - Defined success criteria
