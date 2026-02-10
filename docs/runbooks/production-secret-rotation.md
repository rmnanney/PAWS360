# Production Secret Rotation Runbook

**JIRA**: INFRA-472, INFRA-475  
**Audience**: SRE, Platform Engineering  
**Frequency**: Quarterly (production SSH keys), Annual (staging keys, webhooks)  
**Last Updated**: 2025-01-XX

## Purpose

This runbook defines the procedure for rotating production deployment secrets with zero downtime. It uses a blue-green rotation strategy to update credentials without interrupting deployments.

## Prerequisites

- [ ] Access to GitHub repository settings (Secrets management)
- [ ] SSH access to production and staging environments
- [ ] JIRA ticket created for rotation (linked to INFRA-472)
- [ ] Backup of current secrets stored securely (password manager, vault)
- [ ] Communication: Notify team in Slack #infrastructure channel before rotation

## Secrets Rotation Schedule

| Secret | Rotation Frequency | Last Rotated | Next Rotation Due |
|--------|-------------------|--------------|-------------------|
| `PRODUCTION_SSH_PRIVATE_KEY` | Quarterly (90 days) | TBD | Q1 2025 |
| `STAGING_SSH_PRIVATE_KEY` | Annual (12 months) | TBD | 2025-12-XX |
| `GHCR_PAT` | 90 days | TBD | TBD + 90d |
| `SLACK_WEBHOOK` | Annual (12 months) | TBD | 2025-12-XX |

## Rotation Procedures

### 1. SSH Key Rotation (Production)

**Risk Level**: HIGH (production deployments blocked if misconfigured)  
**Downtime**: Zero (blue-green strategy)

#### Steps

1. **Generate new SSH key pair**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions-production-$(date +%Y%m%d)" -f ~/.ssh/github_production_new
   chmod 600 ~/.ssh/github_production_new
   chmod 644 ~/.ssh/github_production_new.pub
   ```

2. **Add new public key to production servers (blue-green overlap)**
   ```bash
   # SSH to production server as privileged user
   ssh admin@production-server

   # Add new public key to deploy user's authorized_keys
   sudo su - deploy
   echo "NEW_PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
   
   # Verify both old and new keys work (blue-green overlap)
   exit
   exit
   
   # Test new key from local machine
   ssh -i ~/.ssh/github_production_new deploy@production-server "echo 'New key works'"
   ```

3. **Update GitHub Secret with new private key**
   ```bash
   # In GitHub UI: Settings → Secrets → Actions → Edit PRODUCTION_SSH_PRIVATE_KEY
   # Paste contents of: cat ~/.ssh/github_production_new
   ```

4. **Trigger test deployment to validate new key**
   ```bash
   # Manually trigger a staging deployment first (safer)
   gh workflow run ci.yml --ref main

   # Monitor deployment logs for SSH authentication success
   gh run watch
   ```

5. **Remove old public key from production servers (complete rotation)**
   ```bash
   # SSH to production server
   ssh admin@production-server
   sudo su - deploy
   
   # Edit authorized_keys to remove OLD public key (keep only new key)
   vi ~/.ssh/authorized_keys  # Or use sed/awk to remove old key line
   
   # Verify old key no longer works
   exit
   exit
   ssh -i ~/.ssh/github_production_old deploy@production-server "echo 'Should fail'"
   ```

6. **Update secrets audit document**
   - File: `specs/001-github-runner-deploy/secrets-audit.md`
   - Update "Last Rotated" date for `PRODUCTION_SSH_PRIVATE_KEY`
   - Calculate and record new SSH key fingerprint:
     ```bash
     ssh-keygen -lf ~/.ssh/github_production_new.pub -E sha256
     # Update fingerprint in scripts/ci/validate-secrets.sh
     ```

7. **Archive old key securely**
   ```bash
   # Store old key in secure vault for 30-day grace period (rollback window)
   # After 30 days, delete old key permanently
   ```

#### Rollback Procedure (if rotation fails)

1. Re-add old public key to production servers' `authorized_keys`
2. Revert GitHub Secret to old private key
3. Trigger test deployment to validate rollback
4. Investigate failure root cause before re-attempting rotation

---

### 2. GitHub Container Registry PAT Rotation

**Risk Level**: MEDIUM (fallback to GITHUB_TOKEN available)  
**Downtime**: Zero

#### Steps

1. **Generate new GitHub Personal Access Token**
   - Navigate to: GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Create token with permissions: `write:packages`, `read:packages`
   - Expiry: 90 days from creation
   - Copy token immediately (shown only once)

2. **Update GitHub Secret**
   ```bash
   # In GitHub UI: Settings → Secrets → Actions → Edit GHCR_PAT
   # Paste new token value
   ```

3. **Test docker push with new PAT**
   ```bash
   # Trigger workflow that uses GHCR_PAT for docker login
   gh workflow run ci.yml --ref main
   
   # Verify docker push succeeds in logs
   gh run watch | grep "docker push"
   ```

4. **Revoke old PAT**
   - GitHub Settings → Developer settings → Personal access tokens
   - Find old token, click "Revoke"

5. **Update secrets audit**
   - File: `specs/001-github-runner-deploy/secrets-audit.md`
   - Record new expiry date (90 days from creation)

---

### 3. Slack Webhook Rotation

**Risk Level**: LOW (optional integration, no deployment impact)  
**Downtime**: Zero

#### Steps

1. **Generate new Slack webhook URL**
   - Slack Workspace Settings → Apps → Incoming Webhooks
   - Create new webhook for #deployments channel
   - Copy new webhook URL

2. **Update GitHub Secret**
   ```bash
   # In GitHub UI: Settings → Secrets → Actions → Edit SLACK_WEBHOOK
   # Paste new webhook URL
   ```

3. **Test Slack notification**
   ```bash
   # Trigger deployment that sends Slack notification
   gh workflow run ci.yml --ref main
   
   # Verify message received in #deployments channel
   ```

4. **Revoke old webhook**
   - Slack Workspace Settings → Apps → Incoming Webhooks
   - Find old webhook, click "Revoke"

---

### 4. Staging SSH Key Rotation

**Risk Level**: LOW (staging environment, non-production)  
**Downtime**: Acceptable (staging can tolerate brief deployment outage)

#### Steps

Follow same procedure as production SSH key rotation (Section 1), but:
- Target staging servers instead of production
- Update `STAGING_SSH_PRIVATE_KEY` secret
- Less critical testing (can use staging environment for validation)

---

## Validation Checklist

After ANY secret rotation, run validation script:

```bash
./scripts/ci/validate-secrets.sh --github-token "$GITHUB_TOKEN" --repo "YOUR_ORG/PAWS360"
```

Expected output: `VALIDATION PASSED: All required secrets present`

## Post-Rotation Actions

1. **Update JIRA ticket** (linked to INFRA-472)
   - Mark rotation task complete
   - Record any issues encountered
   - Attach rotation timestamp and next rotation due date

2. **Update secrets audit document**
   - File: `specs/001-github-runner-deploy/secrets-audit.md`
   - Update "Last Rotated" column for rotated secret
   - Calculate next rotation due date

3. **Schedule next rotation**
   - Add calendar reminder for next rotation date
   - Create JIRA task 2 weeks before due date

4. **Announce completion**
   - Slack #infrastructure: "Production SSH keys rotated successfully. Next rotation due: Q2 2025."

## Emergency Rotation (Compromise Suspected)

If a secret is suspected to be compromised:

1. **IMMEDIATE**: Rotate secret using procedures above (skip blue-green overlap for SSH keys)
2. **Revoke old credential** immediately (do not wait 30 days)
3. **Audit deployment logs** for unauthorized access (check runner logs, SSH auth logs)
4. **Create incident ticket** (JIRA) and notify security team
5. **Review access controls** for GitHub Secrets (who can view/edit)

## References

- Secrets Audit: `specs/001-github-runner-deploy/secrets-audit.md`
- Validation Script: `scripts/ci/validate-secrets.sh`
- JIRA Epic: INFRA-472
- User Story: INFRA-475 (Safety Guardrails)
- GitHub Docs: [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
