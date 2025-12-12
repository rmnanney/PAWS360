# Task T042: Production Deployment Verification in Staging

**JIRA**: INFRA-473 (User Story 1)  
**Status**: BLOCKED - Requires live infrastructure  
**Priority**: P1  
**Dependencies**: T041 complete ✅

## Overview

Perform comprehensive validation of User Story 1 implementation in a staging environment that mirrors production. This is the final gate before marking US1 complete and deploying to production.

## Prerequisites

### Infrastructure Requirements
- [ ] Staging environment provisioned and configured
- [ ] Primary GitHub Actions runner (production-runner-01) installed and registered
- [ ] Secondary GitHub Actions runner (production-runner-02) installed and registered  
- [ ] Both runners authorized for the repository with appropriate labels:
  - Primary: `[self-hosted, production, primary]`
  - Secondary: `[self-hosted, production, secondary]`
- [ ] Prometheus server accessible at configured URL
- [ ] Grafana dashboard accessible
- [ ] runner-exporter deployed to both runners
- [ ] Ansible inventory configured with staging hosts

### Access Requirements
- [ ] GitHub repository admin access (for workflow_dispatch trigger)
- [ ] SSH access to both runners (for failover testing)
- [ ] Prometheus/Grafana dashboard access (for metrics validation)
- [ ] SRE team availability for sign-off

### Configuration Requirements
- [ ] GitHub Secrets configured for staging deployment:
  - `ANSIBLE_VAULT_PASSWORD`
  - `DEPLOY_SSH_KEY`
  - `PRODUCTION_DATABASE_PASSWORD`
  - Any other deployment secrets
- [ ] Staging environment variables configured
- [ ] Monitoring endpoints accessible from CI runners

## Test Execution Plan

### Test 1: Normal Deployment on Primary Runner
**Objective**: Verify standard deployment flow works correctly

1. Trigger staging deployment via `workflow_dispatch`
   ```bash
   gh workflow run ci.yml \
     --ref 001-github-runner-deploy \
     --field environment=staging \
     --field test_mode=true
   ```

2. Monitor workflow execution in GitHub Actions UI
3. Verify deployment completes successfully
4. Confirm primary runner was used:
   - Check workflow run logs for runner name
   - Verify "Runner: production-runner-01" in logs
5. Verify health checks passed:
   - Backend /actuator/health returns 200
   - Frontend homepage loads
   - Database connection successful
   - Redis connection successful

**Success Criteria**:
- ✅ Deployment completes in <10 minutes
- ✅ All health checks pass
- ✅ Primary runner used for deployment
- ✅ No errors in deployment logs

### Test 2: Concurrency Control Verification
**Objective**: Verify only one deployment runs at a time

1. Trigger first deployment:
   ```bash
   gh workflow run ci.yml \
     --ref 001-github-runner-deploy \
     --field environment=staging \
     --field test_id=concurrent-1
   ```

2. Immediately trigger second deployment:
   ```bash
   gh workflow run ci.yml \
     --ref 001-github-runner-deploy \
     --field environment=staging \
     --field test_id=concurrent-2
   ```

3. Monitor both workflows in GitHub Actions UI
4. Verify second deployment is queued (not running)
5. Wait for first deployment to complete
6. Verify second deployment starts automatically after first completes

**Success Criteria**:
- ✅ First deployment runs to completion
- ✅ Second deployment queued, not running
- ✅ Second deployment starts after first completes
- ✅ No concurrent execution of deploy-to-production job

### Test 3: Failover to Secondary Runner
**Objective**: Verify automatic failover when primary is unavailable

1. Stop primary runner service via SSH:
   ```bash
   ssh production-runner-01 'sudo systemctl stop actions.runner.*.service'
   ```

2. Verify primary runner offline in GitHub UI (Settings > Actions > Runners)

3. Trigger deployment:
   ```bash
   gh workflow run ci.yml \
     --ref 001-github-runner-deploy \
     --field environment=staging \
     --field test_mode=true
   ```

4. Monitor workflow execution
5. Verify deployment uses secondary runner
6. Measure failover time (from workflow start to runner assignment)
7. Restart primary runner after test:
   ```bash
   ssh production-runner-01 'sudo systemctl start actions.runner.*.service'
   ```

**Success Criteria**:
- ✅ Primary runner detected as offline
- ✅ Deployment automatically uses secondary runner
- ✅ Failover completes in <30 seconds
- ✅ Deployment completes successfully on secondary
- ✅ No manual intervention required

### Test 4: Health Check Failure and Rollback
**Objective**: Verify automatic rollback when health checks fail

1. Intentionally break staging environment (e.g., stop backend service):
   ```bash
   ssh staging-backend-host 'sudo systemctl stop paws360-backend'
   ```

2. Trigger deployment:
   ```bash
   gh workflow run ci.yml \
     --ref 001-github-runner-deploy \
     --field environment=staging \
     --field test_mode=true
   ```

3. Verify deployment proceeds normally
4. Verify health check detects backend failure
5. Verify automatic rollback triggered
6. Verify staging environment returned to previous state
7. Restore backend service:
   ```bash
   ssh staging-backend-host 'sudo systemctl start paws360-backend'
   ```

**Success Criteria**:
- ✅ Health check detects backend failure
- ✅ Rollback playbook triggered automatically
- ✅ Staging environment restored to previous version
- ✅ Incident issue created in GitHub
- ✅ No partial deployment artifacts left behind

### Test 5: Monitoring and Alerts Validation
**Objective**: Verify monitoring dashboards and alerts work correctly

1. Access Grafana dashboard for runner health
2. Verify all panels display data:
   - Runner status (online/offline)
   - Deployment success/failure rate
   - Deployment duration
   - Resource usage (CPU, memory, disk)
3. Access Prometheus alerts UI
4. Verify alert rules configured correctly:
   - RunnerOffline
   - DeploymentFailed
   - DeploymentDurationHigh
5. Trigger alert by stopping primary runner for >5 minutes
6. Verify alert fires and notification sent to oncall-sre

**Success Criteria**:
- ✅ All dashboard panels show live data
- ✅ Alert rules visible in Prometheus
- ✅ Test alert fires within expected timeframe
- ✅ Notification delivered to correct channel

## Validation Checklist

### Functional Requirements
- [ ] Deployment completes successfully on primary runner
- [ ] Concurrent deployments are serialized (no overlap)
- [ ] Automatic failover to secondary runner (<30s)
- [ ] Health checks detect failures and trigger rollback
- [ ] Monitoring dashboards show live deployment metrics
- [ ] Alerts fire correctly on simulated failures

### Performance Requirements
- [ ] Deployment duration <10 minutes (normal case)
- [ ] Failover latency <30 seconds
- [ ] Health check execution <2 minutes
- [ ] Rollback completion <5 minutes

### Documentation Requirements
- [ ] All test results documented with screenshots
- [ ] Any issues encountered documented with resolution
- [ ] SRE team has reviewed runbooks and procedures
- [ ] Incident response procedures validated

## SRE Sign-Off

### Sign-Off Criteria
1. All 5 test scenarios passed successfully
2. Monitoring and alerting operational
3. Runbooks reviewed and approved
4. No critical issues identified
5. Team confident in production rollout

### Sign-Off Form
```
Date: ___________
SRE Engineer: ___________
Signature: ___________

Test Results:
[ ] Test 1: Normal Deployment - PASS
[ ] Test 2: Concurrency Control - PASS
[ ] Test 3: Failover to Secondary - PASS
[ ] Test 4: Health Check Rollback - PASS
[ ] Test 5: Monitoring & Alerts - PASS

Comments:
_________________________________
_________________________________

Approval Status: [ ] APPROVED  [ ] REJECTED  [ ] NEEDS REVISION

If rejected, reason:
_________________________________
```

## Completion Criteria

Task T042 can be marked complete when:
1. ✅ All 5 test scenarios executed successfully in staging
2. ✅ Test results documented and attached to JIRA INFRA-473
3. ✅ SRE sign-off form completed and approved
4. ✅ Any issues identified have been resolved or documented as known limitations
5. ✅ Production deployment plan created and reviewed

## Troubleshooting

### Issue: Runner Not Picking Up Jobs
**Symptoms**: Workflow queued indefinitely, runner shows offline
**Diagnostics**:
```bash
ssh production-runner-01 'sudo systemctl status actions.runner.*.service'
ssh production-runner-01 'sudo journalctl -u actions.runner.*.service -n 100'
```
**Resolution**: Restart runner service, verify network connectivity

### Issue: Health Checks Timeout
**Symptoms**: Deployment hangs at health check step
**Diagnostics**:
```bash
curl http://staging-backend/actuator/health
ssh staging-backend-host 'sudo systemctl status paws360-backend'
```
**Resolution**: Check service status, verify firewall rules

### Issue: Secrets Not Available
**Symptoms**: Deployment fails with authentication error
**Diagnostics**: Check GitHub Secrets configuration in repository settings
**Resolution**: Add missing secrets, verify secret names match workflow

## Next Steps After Completion

1. Update task list: Mark T042 as [x] complete
2. Update JIRA INFRA-473: Transition to "Done" status
3. Update session file with T042 results
4. Create production deployment plan (if not already exists)
5. Schedule production deployment with SRE team
6. Begin User Story 2 (INFRA-474) implementation

## References

- **Test Scenarios**: `tests/ci/test-prod-deploy-*.sh`
- **Test Execution Report**: `tests/ci/TEST-EXECUTION-REPORT-US1.md`
- **Runbook**: `docs/runbooks/production-deployment-failures.md`
- **Context Files**: 
  - `contexts/infrastructure/github-runners.md`
  - `contexts/infrastructure/production-deployment-pipeline.md`
- **JIRA Story**: INFRA-473
