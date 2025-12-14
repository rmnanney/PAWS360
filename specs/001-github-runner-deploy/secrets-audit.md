# Production Deployment Secrets Audit

**JIRA**: INFRA-472, INFRA-475 (Safety Guardrails)  
**Status**: Phase 2 Foundation  
**Last Audited**: 2025-01-XX (initial creation)  
**Next Audit Due**: Quarterly rotation schedule

## Purpose

This document audits all GitHub Secrets used in production deployments for `.github/workflows/ci.yml`. It identifies secret purposes, expiry status, rotation requirements, and migration opportunities (e.g., OIDC for cloud providers).

## Secrets Inventory

### Core Authentication

| Secret Name | Purpose | Expiry | Rotation Frequency | Notes |
|-------------|---------|--------|-------------------|-------|
| `GITHUB_TOKEN` | GitHub API access (auto-provided) | Never | N/A (GitHub-managed) | Automatically scoped to workflow; no rotation needed |
| `GHCR_PAT` | GitHub Container Registry push (optional) | Manual expiry | 90 days | Used for GHCR docker push; fallback to GITHUB_TOKEN if not set |

### Deployment Authentication

| Secret Name | Purpose | Expiry | Rotation Frequency | Notes |
|-------------|---------|--------|-------------------|-------|
| `STAGING_SSH_PRIVATE_KEY` | SSH access to staging environment | Never (SSH key) | Annual | RSA 4096-bit key; fingerprint verification in validation script |
| `STAGING_SSH_USER` | SSH username for staging deployment | N/A | N/A | Plaintext username (e.g., `deploy` or `ansible`) |
| `PRODUCTION_SSH_PRIVATE_KEY` | SSH access to production environment | Never (SSH key) | Quarterly | **CRITICAL**: RSA 4096-bit key; fingerprint verification required |
| `PRODUCTION_SSH_USER` | SSH username for production deployment | N/A | N/A | Plaintext username (e.g., `deploy` or `ansible`) |

### Optional Integration Secrets

| Secret Name | Purpose | Expiry | Rotation Frequency | Notes |
|-------------|---------|--------|-------------------|-------|
| `SLACK_WEBHOOK` | Slack notifications for deploy success/failure | Manual webhook expiry | Annual | Optional; workflow continues if not set |

### Feature Flags

| Secret Name | Purpose | Expiry | Rotation Frequency | Notes |
|-------------|---------|--------|-------------------|-------|
| `AUTO_DEPLOY_TO_STAGE` | Enable automatic staging deployment | N/A | N/A | Boolean flag (`true`/`false`); not a credential |
| `AUTO_DEPLOY_TO_PRODUCTION` | Enable automatic production deployment | N/A | N/A | Boolean flag (`true`/`false`); **production safeguard** |

## Secrets Requiring Rotation

### High Priority (Quarterly)
1. **PRODUCTION_SSH_PRIVATE_KEY**
   - Last rotated: (TBD - establish baseline)
   - Next rotation: Q1 2025 (within 90 days)
   - Rotation procedure: See `docs/runbooks/production-secret-rotation.md`
   - Validation: Fingerprint verification via `validate-secrets.sh`

2. **GHCR_PAT** (if in use)
   - Last rotated: (TBD)
   - Next rotation: 90 days from last rotation
   - Rotation procedure: Regenerate PAT in GitHub settings, update secret, test docker push

### Medium Priority (Annual)
1. **STAGING_SSH_PRIVATE_KEY**
   - Last rotated: (TBD)
   - Next rotation: Annual (12 months)
   - Rotation procedure: Same as production, lower urgency

2. **SLACK_WEBHOOK**
   - Last rotated: (TBD)
   - Next rotation: Annual (12 months)
   - Rotation procedure: Regenerate webhook in Slack, update secret, test notification

## Secrets Migration Opportunities

### OIDC/Workload Identity (Future Enhancement)
- **Current State**: SSH key authentication for Ansible deployments
- **Migration Target**: OIDC federation for cloud provider deployments (if applicable)
- **Benefits**: No long-lived credentials, automatic rotation, federated trust
- **Blockers**: Ansible SSH-based deployment model; OIDC primarily for cloud provider APIs
- **Timeline**: Post-MVP (Phase 6 or future sprint)

### SSH Certificate Authority (Future Enhancement)
- **Current State**: Static SSH private keys with no expiry
- **Migration Target**: SSH certificates issued by CA with TTL (e.g., 24-hour validity)
- **Benefits**: Automatic expiry, auditability, centralized revocation
- **Blockers**: Requires SSH CA infrastructure setup (e.g., HashiCorp Vault, GitHub SSH CA)
- **Timeline**: Post-MVP (infrastructure modernization)

## Validation Requirements

All secrets must pass validation via `scripts/ci/validate-secrets.sh` before production deployment:

1. **Presence Check**: Secret exists in GitHub Secrets API
2. **Format Check**: SSH keys are valid PEM format, PATs match GitHub token format
3. **Expiry Check**: Tokens with expiry metadata are not expired
4. **Fingerprint Check**: SSH keys match expected fingerprint (stored in validation script)

## Audit History

| Date | Auditor | Changes | Next Review |
|------|---------|---------|-------------|
| 2025-01-XX | AI Agent (speckit.implement) | Initial audit creation | Q2 2025 |

## References

- Rotation Procedure: `docs/runbooks/production-secret-rotation.md`
- Validation Script: `scripts/ci/validate-secrets.sh`
- Workflow: `.github/workflows/ci.yml`
- JIRA Epic: INFRA-472
- User Story: INFRA-475 (Safety Guardrails)
