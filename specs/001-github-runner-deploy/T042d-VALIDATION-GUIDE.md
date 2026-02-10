# T042d Validation Guide: Production Runner Sign-Off

**Task**: Production runner validation and SRE sign-off  
**Status**: Depends on T042c completion  
**Estimated Time**: 1-2 hours

## Prerequisites

Before starting T042d validation:

✅ **Must be complete**:
- T042c: Monitoring deployed to production runners
- All three runner targets (staging + 2 production) showing "UP" in Prometheus
- Grafana dashboard displaying real metrics from production runners
- Alert rules loaded and tested

## Validation Phases

### Phase 1: Non-Destructive Smoke Tests

Execute smoke tests that verify runner functionality without impacting production:

#### Test 1.1: Runner Registration Status

```bash
# Verify runners are registered with GitHub
gh api /repos/rmnanney/PAWS360/actions/runners | \
  jq '.runners[] | select(.name | test("production|Serotonin")) | {
    name: .name,
    status: .status,
    busy: .busy,
    labels: [.labels[].name]
  }'
```

**Expected**:
- `Serotonin-paws360`: status="online", labels include "production" and "primary"
- `dell-r640-01-runner`: status="online", labels include "production" and "secondary"

#### Test 1.2: Metrics Collection

```bash
# Verify all metrics are being collected
curl -s http://192.168.0.200:9090/api/v1/query \
  --data-urlencode 'query=up{job="github-runner-health"}' | \
  jq '.data.result[] | {
    instance: .metric.instance,
    environment: .metric.environment,
    value: .value[1]
  }'
```

**Expected**: All instances showing value="1" (up)

#### Test 1.3: Runner Health Metrics

```bash
# Query runner status across all environments
curl -s http://192.168.0.200:9090/api/v1/query \
  --data-urlencode 'query=runner_status{job="github-runner-health"}' | \
  jq '.data.result[] | {
    runner: .metric.runner_name,
    environment: .metric.environment,
    status: .value[1],
    host: .metric.instance
  }'
```

**Expected**: All runners showing status="1" (healthy)

#### Test 1.4: Workflow Dry Run

Create a test workflow that targets production runners but doesn't deploy:

```yaml
# .github/workflows/test-production-runners.yml
name: Test Production Runners

on:
  workflow_dispatch:

jobs:
  test-primary:
    runs-on: [self-hosted, Linux, X64, production, primary]
    steps:
      - name: Runner Info
        run: |
          echo "Runner: $RUNNER_NAME"
          echo "Host: $(hostname)"
          echo "User: $(whoami)"
          echo "Network: $(ip addr show | grep inet)"
          
      - name: Check Production Access
        run: |
          # Verify runner can reach production endpoints (non-destructive)
          curl -v -s -o /dev/null -w "%{http_code}" https://paws360.example.com/actuator/health || true
          
      - name: Verify Tools Available
        run: |
          ansible --version
          docker --version || podman --version
          java -version
          
  test-secondary:
    runs-on: [self-hosted, Linux, X64, production, secondary]
    steps:
      - name: Runner Info
        run: |
          echo "Runner: $RUNNER_NAME"
          echo "Host: $(hostname)"
          echo "User: $(whoami)"
```

**Execute**:
```bash
gh workflow run test-production-runners.yml
gh run watch
```

**Expected**: Both jobs complete successfully on appropriate runners

### Phase 2: Network and Connectivity Validation

#### Test 2.1: Production Environment Reachability

From each production runner, verify connectivity to production resources:

```bash
# Test from Serotonin (primary)
ssh ryan@192.168.0.13 "curl -s -o /dev/null -w '%{http_code}' https://paws360.example.com/actuator/health"

# Test from dell-r640-01 (secondary)
ssh ryan@192.168.0.51 "curl -s -o /dev/null -w '%{http_code}' https://paws360.example.com/actuator/health"
```

**Expected**: HTTP 200 or 401 (reachable, auth required)

#### Test 2.2: Ansible Control Node Access

Verify runners can execute Ansible playbooks:

```bash
# From Serotonin
ssh ryan@192.168.0.13 "ansible --version && ansible -i /etc/ansible/hosts all --list-hosts"

# From dell-r640-01
ssh ryan@192.168.0.51 "ansible --version && ansible -i /etc/ansible/hosts all --list-hosts"
```

**Expected**: Ansible installed, inventory accessible

#### Test 2.3: Container Runtime

Verify Docker/Podman available for CI job isolation:

```bash
# From Serotonin
ssh ryan@192.168.0.13 "docker ps || podman ps"

# From dell-r640-01
ssh ryan@192.168.0.51 "docker ps || podman ps"
```

**Expected**: Container runtime operational

### Phase 3: Security Configuration Review

#### Security 3.1: Runner Isolation

**Checklist**:
- [ ] Runners execute in dedicated user account (not root)
- [ ] Runner work directory has restrictive permissions (700 or 750)
- [ ] Runners cannot access other runners' work directories
- [ ] Host firewall configured (if applicable)
- [ ] No production secrets stored on runner filesystem

**Verification**:
```bash
# Check runner user and permissions
ssh ryan@192.168.0.13 "ps aux | grep actions.runner && ls -ld /home/*/actions-runner/_work"
ssh ryan@192.168.0.51 "ps aux | grep actions.runner && ls -ld /home/*/actions-runner/_work"
```

#### Security 3.2: GitHub Actions Security

**Checklist**:
- [ ] Repository requires approval for workflow runs from forks
- [ ] Production deployment jobs use `environment` protection with required reviewers
- [ ] Secrets scoped to production environment (not repository-wide)
- [ ] Runner groups configured with appropriate repository access
- [ ] Workflow permissions follow least-privilege principle

**Verification**:
```bash
# Check repository settings
gh api /repos/rmnanney/PAWS360 | jq '{
  fork_pr_approval: .allow_forking,
  default_branch: .default_branch,
  private: .private
}'

# Check environments
gh api /repos/rmnanney/PAWS360/environments | jq '.environments[] | {
  name: .name,
  protection_rules: .protection_rules[].type
}'
```

#### Security 3.3: Access Control Audit

**Checklist**:
- [ ] Only authorized personnel can modify runner configuration
- [ ] SSH access to runner hosts restricted (key-based auth, no passwords)
- [ ] Sudo privileges documented and minimal
- [ ] Runner registration tokens rotated regularly
- [ ] Monitoring credentials secured (not in runner config)

**Verification**:
```bash
# Check SSH config
ssh ryan@192.168.0.13 "sudo sshd -T | grep -E '(PasswordAuthentication|PubkeyAuthentication|PermitRootLogin)'"
ssh ryan@192.168.0.51 "sudo sshd -T | grep -E '(PasswordAuthentication|PubkeyAuthentication|PermitRootLogin)'"
```

### Phase 4: Monitoring Operational Validation

#### Monitoring 4.1: Dashboard Functionality

**Access Grafana**: http://192.168.0.200:3000

**Verify**:
- [ ] "GitHub Runner Health" dashboard loads without errors
- [ ] Production runners visible in environment filter dropdown
- [ ] Panels display real-time data (not "No Data")
- [ ] Time series graphs show historical trends (last 24 hours)
- [ ] Status panels show current state correctly

#### Monitoring 4.2: Alert Rules

**Access Prometheus**: http://192.168.0.200:9090/alerts

**Verify**:
- [ ] `RunnerOffline` rule present for both environments
- [ ] `RunnerDegraded` rule present with resource thresholds
- [ ] `DeploymentDurationHigh` rule present (if applicable)
- [ ] `DeploymentFailureRate` rule present (if applicable)
- [ ] All rules in "OK" state (not firing)

#### Monitoring 4.3: Alert Test (Controlled)

**Test RunnerOffline alert**:

```bash
# Stop exporter on Serotonin temporarily
ssh ryan@192.168.0.13 "sudo systemctl stop runner-exporter-production"

# Wait 5 minutes
sleep 300

# Check alert fired
curl -s http://192.168.0.200:9090/api/v1/alerts | \
  jq '.data.alerts[] | select(.labels.alertname=="RunnerOffline" and .labels.environment=="production")'

# Expected: Alert in FIRING state

# Restore exporter
ssh ryan@192.168.0.13 "sudo systemctl start runner-exporter-production"

# Wait 2 minutes for alert to resolve
sleep 120

# Verify alert resolved
curl -s http://192.168.0.200:9090/api/v1/alerts | \
  jq '.data.alerts[] | select(.labels.alertname=="RunnerOffline" and .labels.environment=="production")'

# Expected: No results (alert resolved)
```

### Phase 5: Operational Readiness

#### Readiness 5.1: Documentation Review

**Verify complete and accurate**:
- [ ] `contexts/infrastructure/github-runners.md` - Runner inventory with connection details
- [ ] `contexts/infrastructure/production-deployment-pipeline.md` - Deployment workflow documentation
- [ ] `contexts/infrastructure/monitoring-stack.md` - Monitoring setup and query templates
- [ ] `docs/runbooks/production-deployment-failures.md` - Failure mode remediation
- [ ] `specs/001-github-runner-deploy/FINAL-IMPLEMENTATION-REPORT.md` - Implementation summary

#### Readiness 5.2: Runbook Validation

**Test each runbook procedure**:
- [ ] "Runner offline - restore service" - Follow steps, verify resolution
- [ ] Health check commands execute successfully
- [ ] Log inspection commands return useful output
- [ ] Remediation steps are clear and actionable

#### Readiness 5.3: Team Knowledge Transfer

**Prepare SRE handoff**:
- [ ] Schedule walkthrough session with on-call SRE
- [ ] Demonstrate Grafana dashboard navigation
- [ ] Show Prometheus query examples
- [ ] Review alert notification flow
- [ ] Provide access to all documentation

### Phase 6: SRE Sign-Off

#### Sign-Off Criteria

**All of the following must be TRUE**:
- ✅ All smoke tests passed (Phase 1)
- ✅ Network connectivity validated (Phase 2)
- ✅ Security review complete with no critical findings (Phase 3)
- ✅ Monitoring operational and alert tested (Phase 4)
- ✅ Documentation complete and accurate (Phase 5)
- ✅ On-call SRE trained and confident

#### Sign-Off Document

Create `specs/001-github-runner-deploy/production-runner-signoff.md`:

```markdown
# Production Runner Sign-Off

**Date**: YYYY-MM-DD  
**JIRA Story**: INFRA-473  
**Signed By**: [SRE Name]  
**Title**: [SRE Title]

## Validation Summary

**Runners Validated**:
- Serotonin-paws360 (192.168.0.13) - Production Primary
- dell-r640-01-runner (192.168.0.51) - Production Secondary + Staging Primary

**Test Results**:
- Phase 1 (Smoke Tests): ✅ PASS
- Phase 2 (Network/Connectivity): ✅ PASS
- Phase 3 (Security Review): ✅ PASS
- Phase 4 (Monitoring Validation): ✅ PASS
- Phase 5 (Operational Readiness): ✅ PASS

**Security Findings**: None / [List any findings]

**Outstanding Issues**: None / [List any issues]

## Approval

I have reviewed the production runner implementation and verified:
- Runners are operational and properly configured
- Monitoring is comprehensive and alerts are functional
- Security controls are adequate for production use
- Documentation is complete and accurate
- Team is trained and prepared for operations

**Status**: ✅ APPROVED FOR PRODUCTION USE

**Signature**: [SRE Name]  
**Date**: [Signature Date]

**Conditions/Restrictions** (if any):
- [None / List conditions]

## Post-Deployment Actions

- [ ] Enable production deployments via runners in CI workflow
- [ ] Schedule follow-up review in 2 weeks
- [ ] Update on-call runbooks with any lessons learned
```

## Completion Steps

After obtaining SRE sign-off:

1. **Mark task complete** in `specs/001-github-runner-deploy/tasks.md`:
   ```markdown
   - [x] T042d [US1] Production runner validation and SRE sign-off
   ```

2. **Update JIRA story INFRA-473**:
   - Transition to "Done"
   - Add comment: "Production runners validated and approved for use. Sign-off document: specs/001-github-runner-deploy/production-runner-signoff.md"
   - Close story

3. **Update session file**: `contexts/sessions/ryan/001-github-runner-deploy-session.md`
   - Add completion retrospective for US1
   - Document lessons learned
   - Note any deferred items for US2/US3

4. **Update implementation report**: `FINAL-IMPLEMENTATION-REPORT.md`
   - Mark Phase 3 (US1) as 100% complete
   - Update executive summary with sign-off confirmation

5. **Celebrate** 🎉 - User Story 1 (MVP) is complete!

## Rollback Plan

If critical issues discovered during validation:

1. **Do NOT approve production use**
2. Document specific issues in sign-off doc with "NOT APPROVED" status
3. Create JIRA tickets for remediation
4. Revert any partial configuration changes
5. Schedule re-validation after fixes

## Next Steps After T042d

With US1 complete, consider:

- **Immediate**: Begin using production runners for actual deployments
- **Short-term** (1-2 weeks): Monitor performance, collect operational data
- **Medium-term** (Sprint planning): Evaluate priority of US2 (Diagnostics) vs US3 (Safeguards)
- **Long-term**: Implement remaining user stories based on operational needs

## References

- **Implementation Report**: `specs/001-github-runner-deploy/FINAL-IMPLEMENTATION-REPORT.md`
- **Tasks File**: `specs/001-github-runner-deploy/tasks.md`
- **JIRA Story**: INFRA-473
- **Monitoring Deployment**: `specs/001-github-runner-deploy/T042c-DEPLOYMENT-GUIDE.md`
- **Grafana Dashboard**: http://192.168.0.200:3000
- **Prometheus UI**: http://192.168.0.200:9090
