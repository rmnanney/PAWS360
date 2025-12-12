#!/usr/bin/env bash
# Deployment Failure Notification Script
# JIRA: INFRA-474
# Purpose: Send notifications and create GitHub issues for deployment failures

set -euo pipefail

# Configuration
GITHUB_ORG="${GITHUB_REPOSITORY_OWNER:-rmnanney}"
GITHUB_REPO="${GITHUB_REPOSITORY#*/}"
GITHUB_REPO="${GITHUB_REPO:-PAWS360}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
ONCALL_SRE="${ONCALL_SRE:-oncall-sre}"

# Required arguments
RUNNER_NAME="${1:-unknown}"
FAILURE_REASON="${2:-unknown}"
AFFECTED_JOB="${3:-unknown}"
REMEDIATION_LINK="${4:-docs/runbooks/production-deployment-failures.md}"
RUN_ID="${GITHUB_RUN_ID:-unknown}"
RUN_NUMBER="${GITHUB_RUN_NUMBER:-unknown}"
RUNNER_CPU="${5:-unavailable}"
RUNNER_MEMORY="${6:-unavailable}"
RUNNER_DISK="${7:-unavailable}"
SEVERITY="${8:-high}"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*"
}

# Function to send Slack notification
send_slack_notification() {
    if [ -z "$SLACK_WEBHOOK" ]; then
        warn "SLACK_WEBHOOK not configured, skipping Slack notification"
        return 0
    fi
    
    log "Sending Slack notification to oncall-sre..."
    
    local severity_emoji="🔴"
    if [ "$SEVERITY" = "critical" ]; then
        severity_emoji="🚨"
    elif [ "$SEVERITY" = "high" ]; then
        severity_emoji="🔴"
    elif [ "$SEVERITY" = "medium" ]; then
        severity_emoji="🟡"
    fi
    
    local payload=$(cat <<EOF
{
  "text": "${severity_emoji} Production Deployment Failed",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "${severity_emoji} Production Deployment Failed - Run #${RUN_NUMBER}"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Repository:*\n\`${GITHUB_ORG}/${GITHUB_REPO}\`"
        },
        {
          "type": "mrkdwn",
          "text": "*Severity:*\n\`${SEVERITY}\`"
        },
        {
          "type": "mrkdwn",
          "text": "*Runner:*\n\`${RUNNER_NAME}\`"
        },
        {
          "type": "mrkdwn",
          "text": "*Failure Reason:*\n\`${FAILURE_REASON}\`"
        },
        {
          "type": "mrkdwn",
          "text": "*Affected Job:*\n\`${AFFECTED_JOB}\`"
        },
        {
          "type": "mrkdwn",
          "text": "*Run ID:*\n\`${RUN_ID}\`"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Runner Health at Failure:*\n• CPU: ${RUNNER_CPU}%\n• Memory: ${RUNNER_MEMORY}%\n• Disk: ${RUNNER_DISK}%"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Remediation Guide:*\n<https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/blob/main/${REMEDIATION_LINK}|View Runbook>"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View Workflow Run"
          },
          "url": "https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/actions/runs/${RUN_ID}",
          "style": "danger"
        }
      ]
    }
  ]
}
EOF
)
    
    if curl -sf -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK" >/dev/null 2>&1; then
        log "Slack notification sent successfully"
    else
        error "Failed to send Slack notification"
        return 1
    fi
}

# Function to create GitHub issue
create_github_issue() {
    if [ -z "$GITHUB_TOKEN" ]; then
        warn "GITHUB_TOKEN not configured, skipping GitHub issue creation"
        return 0
    fi
    
    log "Creating GitHub issue for deployment failure..."
    
    local title="🚨 Production Deployment Failed - Run #${RUN_NUMBER} - ${FAILURE_REASON}"
    
    local body=$(cat <<EOF
## Production Deployment Failure

**Workflow Run**: [#${RUN_NUMBER}](https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/actions/runs/${RUN_ID})
**Severity**: ${SEVERITY^^}
**Runner**: \`${RUNNER_NAME}\`
**Affected Job**: \`${AFFECTED_JOB}\`
**Failure Reason**: \`${FAILURE_REASON}\`

### Runner Health at Failure

- **CPU Usage**: ${RUNNER_CPU}%
- **Memory Usage**: ${RUNNER_MEMORY}%
- **Disk Usage**: ${RUNNER_DISK}%

### Next Steps

1. Review workflow logs: [View Run](https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/actions/runs/${RUN_ID})
2. Follow remediation guide: [${REMEDIATION_LINK}](https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/blob/main/${REMEDIATION_LINK})
3. Check production health: \`infrastructure/ansible/playbooks/validate-production-deploy.yml\`
4. Verify rollback success: Check production state file
5. Investigate root cause using diagnostics above
6. Create post-mortem if necessary

**Assignee**: @${ONCALL_SRE}
**JIRA**: INFRA-474

---
*This issue was automatically created by the deployment failure notification system.*
EOF
)
    
    local issue_data=$(jq -n \
        --arg title "$title" \
        --arg body "$body" \
        --argjson labels '["deployment-failure", "production-incident", "'$FAILURE_REASON'", "'$SEVERITY'", "requires-investigation"]' \
        --argjson assignees '["'$ONCALL_SRE'"]' \
        '{title: $title, body: $body, labels: $labels, assignees: $assignees}')
    
    local response=$(curl -sf -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "$issue_data" \
        "https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/issues" 2>&1)
    
    if [ $? -eq 0 ]; then
        local issue_number=$(echo "$response" | jq -r '.number')
        local issue_url=$(echo "$response" | jq -r '.html_url')
        log "GitHub issue created successfully: #${issue_number}"
        log "Issue URL: ${issue_url}"
    else
        error "Failed to create GitHub issue"
        error "Response: $response"
        return 1
    fi
}

# Main execution
main() {
    log "=== Deployment Failure Notification ==="
    log "Runner: ${RUNNER_NAME}"
    log "Failure Reason: ${FAILURE_REASON}"
    log "Severity: ${SEVERITY}"
    log "Affected Job: ${AFFECTED_JOB}"
    log "Remediation Link: ${REMEDIATION_LINK}"
    echo ""
    
    # Send Slack notification
    if send_slack_notification; then
        log "✓ Slack notification sent"
    else
        warn "✗ Slack notification failed"
    fi
    
    echo ""
    
    # Create GitHub issue
    if create_github_issue; then
        log "✓ GitHub issue created"
    else
        warn "✗ GitHub issue creation failed"
    fi
    
    echo ""
    log "=== Notification process complete ==="
}

# Run main function
main
