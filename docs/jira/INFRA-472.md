# INFRA-472: GitHub Actions Runner Deployment Stabilization

**Type:** Epic  
**Priority:** Critical  
**Status:** In Progress  
**Created:** 2025-01-XX  
**Reporter:** DevOps Team  
**Assignee:** SRE Team  

## Epic Summary

Stabilize production deployments through GitHub Actions self-hosted runners. Current issue: deployments are not reaching the production stack as expected; runners appear to be failing during CI/CD deployment phases.

## Problem Statement

Production deployments via GitHub Actions CI/CD are experiencing inconsistent delivery to target infrastructure. Runner failures during deployment execution result in incomplete or failed production rollouts, impacting service availability and deployment reliability.

## Success Criteria

- ≥95% production deployment success rate
- ≤10 minute p95 deployment duration
- Zero secret leakage incidents
- Diagnostic capabilities operational within 5 minutes of incident detection
- Full constitutional compliance (JIRA-first, monitoring discovery, context management)

## Constitutional Compliance

- **Article I**: JIRA-first approach maintained throughout feature lifecycle
- **Article II**: Context files created and maintained in `contexts/infrastructure/`
- **Article VIIa**: Monitoring discovery enabled via Ansible inventory variables (no hardcoded IPs)
- **Article X**: Truth & partnership - accurate status reporting and proactive communication
- **Article XIII**: Proactive compliance embedded in all implementation phases

## Technical Context

### Current State
- GitHub Actions self-hosted runners on Linux/x64
- Production deployment job in `.github/workflows/ci.yml` (lines 960-1092)
- Ansible-based infrastructure management
- Monitoring stack at 192.168.0.200 (Prometheus/Grafana)

### Target State
- Dual runner groups (primary + secondary with production labels)
- Failover mechanism: fail-fast on primary, automatic failover to pre-approved secondary
- Comprehensive preflight checks before deployment execution
- Health gates for critical service validation
- Enhanced diagnostics and logging
- Deployment safeguards (branch protection, approval gates, audit logging)

### Constraints
- **No rollback policy**: Fix-forward only approach mandated
- **IaC mandate**: All infrastructure addresses must use Ansible inventory variables (no hardcoded IPs)
- Production environment currently points to localhost (requires authoritative source update)

## Related User Stories

- INFRA-473: Reliable Production Deployments with Failover (Priority 1)
- INFRA-474: Fast Incident Diagnostics and Troubleshooting (Priority 2)
- INFRA-475: Deployment Safety Guardrails (Priority 3)

## Dependencies

- Ansible inventory structure (`infrastructure/ansible/inventories/production/hosts`)
- GitHub Actions workflow configuration (`.github/workflows/ci.yml`)
- Monitoring stack integration (Prometheus/Grafana at 192.168.0.200)
- Runner registration secrets management

## Risk Assessment

- **High**: Incomplete production inventory may delay deployment
- **Medium**: Secret rotation during implementation requires coordination
- **Low**: Monitoring integration should leverage existing stack

## Testing Requirements

- Unit tests for preflight check scripts
- Integration tests for failover mechanism
- End-to-end deployment validation on staging environment
- Load testing for concurrent deployment handling
- Security validation for secrets management

## Deployment Verification

- Pre-deployment: Preflight checks pass, health gates green
- During deployment: Real-time logs available, failover triggers tested
- Post-deployment: Service health validated, metrics collected, audit logs confirmed

## Infrastructure Impact

- New runner groups created in GitHub organization
- Secondary runner host provisioned and configured
- Ansible playbooks updated for runner lifecycle management
- Monitoring dashboards extended with runner metrics

## Documentation

- Context files: `contexts/infrastructure/github-runners.md`, `contexts/infrastructure/deployment-pipeline.md`
- Infrastructure analysis: `docs/infrastructure/runner-deployment-impact.md`
- Ansible guide: `docs/infrastructure/ansible-runner-inventory.md`
- Session tracking: `contexts/sessions/001-github-runner-deploy.yml`

## Links

- Spec: `specs/001-github-runner-deploy/spec.md`
- Plan: `specs/001-github-runner-deploy/plan.md`
- Research: `specs/001-github-runner-deploy/research.md`
- Tasks: `specs/001-github-runner-deploy/tasks.md`

## Notes

This epic follows the speckit workflow and constitutional framework. All implementation phases include comprehensive testing, JIRA maintenance, and infrastructure impact analysis. Time constraints explicitly removed - no shortcuts permitted.
