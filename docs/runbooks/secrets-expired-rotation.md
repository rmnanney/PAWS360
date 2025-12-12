---
title: "Secrets Expired - Rotation Procedure"
severity: "Critical"
category: "Authentication & Security"
last_updated: "2025-01-11"
owner: "SRE Team / Security Team"
jira_tickets: ["INFRA-474"]
related_runbooks:
  - "runner-offline-restore.md"
  - "network-unreachable-troubleshooting.md"
estimated_time: "20-30 minutes"
---

# Secrets Expired - Rotation Procedure

## Overview

Step-by-step procedures to rotate expired secrets and restore deployment authentication for GitHub Actions runners and production infrastructure.

**Severity**: Critical  
**Impact**: Deployments blocked, authentication failures  
**Response Time**: < 15 minutes

---

## Symptoms

- ❌ Deployment fails with "401 Unauthorized" or "403 Forbidden"
- ❌ SSH authentication failures: "Permission denied (publickey)"
- ❌ API token validation errors
- ❌ Ansible playbook fails with "Authentication or permission failure"
- ❌ Git operations fail with authentication errors
- ❌ Runner logs show: "Invalid credentials", "Token expired", "Authentication failed"

---

## Secret Inventory

### GitHub Secrets (Repository Level)

Navigate to: `Settings → Secrets and variables → Actions`

| Secret Name | Type | Usage | Rotation Frequency | Expiry Alert |
|-------------|------|-------|-------------------|--------------|
| `PRODUCTION_SSH_PRIVATE_KEY` | SSH Key | Production deployment | 90 days | 7 days before |
| `PRODUCTION_SSH_USER` | Username | Production access | N/A | N/A |
| `STAGING_SSH_PRIVATE_KEY` | SSH Key | Staging deployment | 90 days | 7 days before |
| `SLACK_WEBHOOK` | Webhook URL | Notifications | Annual | 30 days before |
| `DOCKER_HUB_TOKEN` | PAT | Image push/pull | 90 days | 7 days before |
| `SONAR_TOKEN` | API Token | Code quality | Annual | 30 days before |

### Runner Registration Tokens

| Token Type | Scope | Validity | Location |
|------------|-------|----------|----------|
| Registration Token | Repository | 1 hour | GitHub API |
| Runner Token | Runner | Permanent | `~/.runner` on runner host |
| PAT (Admin) | Repository Admin | 90 days | GitHub Settings → Developer |

---

## Diagnosis

### Step 1: Identify Failing Secret

Check deployment workflow logs:

```bash
# Via GitHub CLI
gh run view <run_id> --log-failed

# Look for patterns:
# - "Permission denied (publickey)" → SSH key issue
# - "401 Unauthorized" → API token expired
# - "403 Forbidden" → Insufficient permissions
```

### Step 2: Verify Secret Expiration

```bash
# Check SSH key expiration (if supported)
ssh-keygen -lf ~/.ssh/id_rsa

# Check GitHub PAT expiration (via API)
curl -sH "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user \
  | jq '.message'

# Check Docker Hub token
docker login --username <username> --password <token> 2>&1 | grep -i "unauthorized\|expired"
```

### Step 3: Test Secret Manually

```bash
# Test SSH key
ssh -i /path/to/key -o StrictHostKeyChecking=no \
  admin@<production_host> "echo 'SSH test successful'"

# Test GitHub API token
curl -sH "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user | jq '.login'

# Test Docker Hub token
echo "$DOCKER_HUB_TOKEN" | docker login --username <username> --password-stdin
```

---

## Remediation

### Rotate SSH Keys (Production/Staging)

**Step 1: Generate New SSH Key Pair**

```bash
# Generate new key (on your local machine, not runner)
ssh-keygen -t ed25519 -C "github-actions-$(date +%Y%m%d)" -f ~/.ssh/github-actions-new

# Set restrictive permissions
chmod 600 ~/.ssh/github-actions-new
chmod 644 ~/.ssh/github-actions-new.pub
```

**Step 2: Deploy Public Key to Production Hosts**

```bash
# Copy public key to all production hosts
for host in $(awk '/\[webservers\]/{flag=1;next}/^\[/{flag=0}flag && NF{print $1}' \
  infrastructure/ansible/inventories/production/hosts); do
  
  echo "Deploying to $host..."
  ssh-copy-id -i ~/.ssh/github-actions-new.pub admin@$host
done

# Or manually:
cat ~/.ssh/github-actions-new.pub | ssh admin@<host> \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Step 3: Update GitHub Secret**

```bash
# Get private key content
PRIVATE_KEY=$(cat ~/.ssh/github-actions-new)

# Update via GitHub CLI
gh secret set PRODUCTION_SSH_PRIVATE_KEY --body "$PRIVATE_KEY"

# Verify update
gh secret list | grep PRODUCTION_SSH_PRIVATE_KEY
```

**Step 4: Test New Key**

```bash
# Trigger test deployment
gh workflow run test-ssh-connectivity.yml --ref main

# Monitor run
gh run watch
```

**Step 5: Remove Old Key**

Once validated:

```bash
# Remove old public key from production hosts
for host in <production_hosts>; do
  ssh admin@$host "sed -i '/<old_key_fingerprint>/d' ~/.ssh/authorized_keys"
done

# Remove old key locally
rm ~/.ssh/github-actions-old*
```

### Rotate GitHub PAT (Personal Access Token)

**Step 1: Generate New Token**

Via GitHub UI:
1. Go to: `Settings → Developer settings → Personal access tokens → Tokens (classic)`
2. Click: "Generate new token"
3. Scopes needed:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
   - `admin:org` (if using organization runners)
4. Expiration: 90 days
5. Click: "Generate token"
6. **Copy token immediately** (shown only once)

Or via GitHub CLI:

```bash
# Create token with required scopes
gh auth refresh -h github.com -s admin:public_key,repo,workflow

# Get token
gh auth token
```

**Step 2: Update GitHub Secret**

```bash
# Set new token
gh secret set GITHUB_TOKEN --body "<new_token>"

# Or for runner registration token (updated automatically)
# No action needed - registration tokens are short-lived (1 hour)
```

**Step 3: Update Runner Token (if using PAT for runner)**

```bash
# SSH to runner
ssh admin@<runner_host>

# Stop service
sudo systemctl stop actions.runner.rmnanney-PAWS360.<runner-name>.service

# Remove old runner
cd ~/actions-runner
./config.sh remove --token <old_token>

# Re-register with new PAT
./config.sh --url https://github.com/rmnanney/PAWS360 \
  --token <new_registration_token> \
  --name <runner-name> \
  --labels self-hosted,Linux,X64,production

# Start service
sudo systemctl start actions.runner.rmnanney-PAWS360.<runner-name>.service
```

### Rotate Docker Hub Token

**Step 1: Generate New Access Token**

Via Docker Hub UI:
1. Go to: `Account Settings → Security → Access Tokens`
2. Click: "New Access Token"
3. Description: `github-actions-paws360-$(date +%Y%m%d)`
4. Access: Read, Write, Delete
5. Click: "Generate"
6. **Copy token immediately**

**Step 2: Update GitHub Secret**

```bash
# Update Docker Hub token
gh secret set DOCKER_HUB_TOKEN --body "<new_token>"

# Also update username if changed
gh secret set DOCKER_HUB_USERNAME --body "<username>"
```

**Step 3: Test Token**

```bash
# Test login locally
echo "$NEW_DOCKER_HUB_TOKEN" | docker login --username <username> --password-stdin

# Trigger test build
gh workflow run build-test-image.yml --ref main
```

**Step 4: Revoke Old Token**

Via Docker Hub UI:
1. Go to: `Account Settings → Security → Access Tokens`
2. Find old token
3. Click: "Delete"

### Rotate Slack Webhook URL

**Step 1: Generate New Webhook**

Via Slack UI:
1. Go to: `https://api.slack.com/apps`
2. Select your app → "Incoming Webhooks"
3. Click: "Add New Webhook to Workspace"
4. Select channel: `#deployments` or `#sre-alerts`
5. Click: "Allow"
6. Copy new webhook URL

**Step 2: Update GitHub Secret**

```bash
gh secret set SLACK_WEBHOOK --body "<new_webhook_url>"
```

**Step 3: Test Webhook**

```bash
# Send test message
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message from secret rotation"}' \
  "<new_webhook_url>"
```

**Step 4: Remove Old Webhook**

Via Slack UI:
1. Find old webhook in app settings
2. Click: "Remove"

---

## Validation

### 1. Verify Secret Updated in GitHub

```bash
# List secrets (values hidden)
gh secret list

# Verify last updated timestamp
gh api /repos/rmnanney/PAWS360/actions/secrets/PRODUCTION_SSH_PRIVATE_KEY \
  | jq '.updated_at'
```

### 2. Test Authentication

```bash
# Test SSH
ssh -o StrictHostKeyChecking=no admin@<production_host> "echo 'Success'"

# Test GitHub API
gh api user | jq '.login'

# Test Docker Hub
docker pull nginx:latest
```

### 3. Run End-to-End Test

```bash
# Trigger full deployment test
gh workflow run test-production-deploy.yml --ref main

# Monitor for success
gh run watch

# Expected: All steps pass, no authentication errors
```

### 4. Check Monitoring

```bash
# Verify no secret validation alerts
curl -sf "http://192.168.0.200:9090/api/v1/alerts" \
  | jq '.data.alerts[] | select(.labels.alertname | contains("Secret"))'

# Expected: No active alerts
```

---

## Post-Rotation Checklist

- [ ] Old secret revoked/deleted
- [ ] New secret tested in production
- [ ] Documentation updated with rotation date
- [ ] Calendar reminder set for next rotation (90 days)
- [ ] Team notified of rotation
- [ ] Incident ticket updated (if applicable)
- [ ] Post-mortem created (if outage occurred)

---

## Preventive Measures

### 1. Automate Expiry Alerts

Create GitHub Actions workflow to check secret expiry:

```yaml
# .github/workflows/check-secret-expiry.yml
name: Check Secret Expiry
on:
  schedule:
    - cron: '0 9 * * 1'  # Monday 9 AM
jobs:
  check-expiry:
    runs-on: ubuntu-latest
    steps:
      - name: Check SSH key age
        run: |
          # Calculate days since last rotation
          # Alert if > 80 days
      - name: Create issue if expiring soon
        if: expiring_soon
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.create({
              title: '⚠️ Secrets expiring in 7 days',
              labels: ['security', 'secrets-rotation']
            })
```

### 2. Use Short-Lived Tokens

Prefer short-lived tokens where possible:
- GitHub App installation tokens (1 hour)
- OIDC tokens (temporary credentials)
- AWS STS temporary credentials

### 3. Secret Rotation Schedule

Create calendar reminders:

| Secret | Rotation Frequency | Next Due | Owner |
|--------|-------------------|----------|-------|
| SSH Keys | 90 days | 2025-04-11 | SRE Team |
| GitHub PAT | 90 days | 2025-04-11 | SRE Team |
| Docker Hub Token | 90 days | 2025-04-11 | Dev Team |
| Slack Webhooks | Annual | 2026-01-11 | SRE Team |

### 4. Secret Management Tool

Consider using:
- **HashiCorp Vault**: Centralized secret management
- **AWS Secrets Manager**: Automatic rotation
- **Azure Key Vault**: Integration with GitHub Actions
- **Google Secret Manager**: GCP integration

---

## Emergency Contacts

| Issue | Contact | Slack | Email |
|-------|---------|-------|-------|
| SSH Key Issues | SRE On-Call | `@oncall-sre` in `#sre-incidents` | sre@example.com |
| GitHub PAT Issues | Platform Team | `@platform-team` in `#platform` | platform@example.com |
| Docker Hub Issues | Dev Team Lead | `@dev-lead` in `#development` | dev@example.com |

---

## Quick Reference

| Error Message | Likely Cause | Quick Fix |
|---------------|--------------|-----------|
| "Permission denied (publickey)" | SSH key expired/invalid | Rotate SSH key |
| "401 Unauthorized" | API token expired | Rotate PAT |
| "403 Forbidden" | Insufficient permissions | Check token scopes |
| "Token has expired" | Explicit expiry | Generate new token |

---

**Last Updated**: 2025-01-11  
**JIRA**: INFRA-474  
**Owner**: SRE Team / Security Team
