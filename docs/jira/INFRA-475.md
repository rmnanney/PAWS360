# INFRA-475: Deployment Safety Guardrails

**Type:** Story  
**Epic:** INFRA-472  
**Priority:** P3 (Medium)  
**Status:** To Do  
**Created:** 2025-01-XX  
**Reporter:** DevOps Team  
**Assignee:** SRE Team  

## User Story

**As a** security-conscious organization  
**I want** deployment safety mechanisms enforced automatically  
**So that** unauthorized or risky deployments are prevented before execution  

## Acceptance Criteria

### AC1: Branch Protection
- [ ] Production deployments restricted to protected branches only
- [ ] Protected branches: `main`, `release/*`
- [ ] Branch protection enforced via GitHub branch rules
- [ ] Workflow validates branch before deployment execution
- [ ] Deployment blocked with clear error message if branch invalid

### AC2: Approval Gates
- [ ] Production deployments require approval from designated team
- [ ] Approval team: SRE leads, DevOps managers
- [ ] GitHub Environments configured with required reviewers
- [ ] Approval timeout: 4 hours (deployment fails if not approved)
- [ ] Approval decisions logged to audit trail

### AC3: Secrets Management
- [ ] All secrets stored in GitHub Secrets (no plaintext in code)
- [ ] Secrets rotation schedule enforced (90-day max age)
- [ ] Secret access audited (who retrieved what, when)
- [ ] Sensitive output masking enabled in workflow logs
- [ ] Zero secret leakage incidents

### AC4: Concurrency Control
- [ ] Only one production deployment active at a time
- [ ] Concurrent deployment attempts queued, not canceled
- [ ] Queue timeout: 30 minutes (fail if not started by then)
- [ ] Concurrency violations logged and alerted
- [ ] No race conditions in deployment execution

### AC5: Rollback Prevention
- [ ] Fix-forward policy enforced (no rollback option in UI)
- [ ] Emergency rollback requires senior approval + incident ticket
- [ ] Rollback events logged with full justification
- [ ] Rollback capability tested quarterly (but not used in production)
- [ ] Rollback procedure documented in runbook

## Technical Requirements

### Branch Protection Configuration
```yaml
Protected Branches:
- main:
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - ci-tests
      - security-scan
- release/*:
    required_reviews: 1
    dismiss_stale_reviews: true
```

### Approval Gate Configuration
```yaml
Environments:
- production:
    required_reviewers:
      - @sre-team
      - @devops-managers
    wait_timer: 0  # Immediate approval required
    deployment_branch_policy:
      protected_branches: true
```

### Secrets Management
- GitHub Secrets for: database passwords, API keys, runner registration tokens
- Secret rotation automation via GitHub Actions scheduled workflow
- Secrets audit log exported to centralized logging
- Masking patterns defined for common secret formats (API keys, tokens)

### Concurrency Control
```yaml
jobs:
  deploy-to-production:
    concurrency:
      group: production-deploy
      cancel-in-progress: false  # Queue instead
```

### Workflow Validation
```bash
# scripts/deployment/validate-deployment.sh
- Check current branch matches protected list
- Verify required approvals obtained
- Validate secrets are present (not expired)
- Confirm no concurrent deployment in progress
- Exit non-zero if any check fails
```

## Test Criteria

### Unit Tests
- [ ] Branch validation script correctly identifies protected branches
- [ ] Approval gate logic enforces reviewer requirements
- [ ] Secret rotation script handles all secret types
- [ ] Concurrency control prevents simultaneous deployments

### Integration Tests
- [ ] Deployment from non-protected branch blocked
- [ ] Deployment without approval times out correctly
- [ ] Secret rotation updates GitHub Secrets successfully
- [ ] Concurrent deployment attempts queued properly

### End-to-End Tests
- [ ] Production deployment succeeds with all guardrails enabled
- [ ] Approval gate requires manual review (test on staging)
- [ ] Secret masking prevents leakage in logs
- [ ] Concurrency control prevents race conditions

### Security Tests
- [ ] Secrets never logged in plaintext
- [ ] Approval bypass attempts fail
- [ ] Branch protection rules enforced at GitHub level
- [ ] Audit trail captures all security-relevant events

## Deployment Verification

### Pre-Deployment
- Branch protection rules configured on GitHub
- GitHub Environment created with required reviewers
- Secrets rotated and stored in GitHub Secrets
- Concurrency group defined in workflow

### During Deployment
- Validation script passes all checks
- Approval obtained within timeout window
- No secrets leaked in logs
- No concurrent deployments detected

### Post-Deployment
- Audit trail complete (branch, approver, timestamp, commit)
- Secret rotation schedule confirmed
- Branch protection rules active
- Concurrency control verified

## Infrastructure Impact

### New Resources
- GitHub Environment: `production` with required reviewers
- Branch protection rules on `main` and `release/*`
- Scheduled workflow: `secret-rotation.yml`
- Validation script: `scripts/deployment/validate-deployment.sh`

### Modified Resources
- `.github/workflows/ci.yml`: Add concurrency group, approval gate
- GitHub Secrets: All production secrets migrated
- Monitoring alerts: Add guardrail violation alerts

### Resource Requirements
- No additional compute resources required
- Storage: Audit logs (included in centralized logging)
- GitHub Actions minutes: <5 min/month for secret rotation

## Dependencies

- INFRA-473: Runner infrastructure operational
- INFRA-474: Audit logging configured
- GitHub organization admin access for branch protection
- SRE team availability for approval reviews

## Risk Mitigation

- **Risk**: Approval gate delays critical security patch  
  **Mitigation**: Expedited approval process for security incidents

- **Risk**: Secret rotation breaks production service  
  **Mitigation**: Rotation tested on staging first, rollback procedure documented

- **Risk**: Concurrency control blocks legitimate deployment  
  **Mitigation**: Queue timeout tunable, manual override with approval

## Documentation

- [ ] Branch protection guide: `docs/security/branch-protection.md`
- [ ] Approval process: `docs/processes/deployment-approvals.md`
- [ ] Secret rotation procedure: `docs/security/secret-rotation.md`
- [ ] Concurrency control: `docs/deployment/concurrency-management.md`
- [ ] Rollback procedure: `docs/runbooks/emergency-rollback.md`

## Constitutional Compliance

- **Article I**: JIRA ticket maintained throughout implementation
- **Article II**: Context files updated with security procedures
- **Article VIIa**: No hardcoded secrets or IPs
- **Article X**: Accurate audit trail for all deployment decisions
- **Article XIII**: Proactive security monitoring and compliance checks

## Links

- Epic: INFRA-472
- Spec: `specs/001-github-runner-deploy/spec.md` (User Story 3)
- Tasks: `specs/001-github-runner-deploy/tasks.md` (Phase 5: T063-T084)

## Notes

Priority 3 implementation begins after INFRA-474 completion. Safety guardrails are essential for production security and compliance. Security team review required before enabling approval gates. Emergency rollback capability tested but never used in production per fix-forward policy.
