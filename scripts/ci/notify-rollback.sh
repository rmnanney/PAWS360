#!/usr/bin/env bash
#
# Rollback Notification and Incident Tracking
# Creates GitHub issue and sends notifications when production rollback occurs
#
# Usage:
#   ./notify-rollback.sh \
#     --failed-version v1.2.4 \
#     --rollback-version v1.2.3 \
#     --reason "Health checks failed" \
#     --jira-ticket INFRA-123
#
# Required Environment Variables:
#   GITHUB_TOKEN: GitHub personal access token with repo scope
#   GITHUB_REPOSITORY: Repository in format owner/repo (e.g., rmnanney/PAWS360)
#
# Optional Environment Variables:
#   SLACK_WEBHOOK_URL: Slack webhook for notifications
#   PAGERDUTY_API_KEY: PagerDuty API key for incident creation
#
# Constitutional Compliance:
#   - Article VIIa: Monitoring Discovery - emits rollback events
#   - Article X: Truth & Partnership - accurate incident reporting
#   - Article XIII: Post-mortem requirement for all rollback incidents
#
# JIRA: INFRA-475 (User Story 3 - Protect production during deploy anomalies)
# Task: T075 - Add rollback notification and incident tracking

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FAILED_VERSION=""
ROLLBACK_VERSION=""
REASON=""
JIRA_TICKET=""
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
PAGERDUTY_API_KEY="${PAGERDUTY_API_KEY:-}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --failed-version)
            FAILED_VERSION="$2"
            shift 2
            ;;
        --rollback-version)
            ROLLBACK_VERSION="$2"
            shift 2
            ;;
        --reason)
            REASON="$2"
            shift 2
            ;;
        --jira-ticket)
            JIRA_TICKET="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --failed-version VERSION --rollback-version VERSION --reason REASON [--jira-ticket TICKET]"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$FAILED_VERSION" || -z "$ROLLBACK_VERSION" || -z "$REASON" ]]; then
    echo -e "${RED}Error: Missing required parameters${NC}"
    echo "Usage: $0 --failed-version VERSION --rollback-version VERSION --reason REASON [--jira-ticket TICKET]"
    exit 1
fi

if [[ -z "$GITHUB_TOKEN" || -z "$GITHUB_REPOSITORY" ]]; then
    echo -e "${RED}Error: GITHUB_TOKEN and GITHUB_REPOSITORY environment variables required${NC}"
    exit 1
fi

# Helper functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

failure() {
    echo -e "${RED}✗${NC} $*"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Create GitHub issue for rollback incident
create_github_issue() {
    log "Creating GitHub issue for rollback incident..."
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    local issue_title="[Production Rollback] ${FAILED_VERSION} → ${ROLLBACK_VERSION}"
    
    local issue_body
    issue_body=$(cat <<EOF
## Production Rollback Incident

**Timestamp**: ${timestamp}
**Failed Version**: ${FAILED_VERSION}
**Rolled Back To**: ${ROLLBACK_VERSION}
**Reason**: ${REASON}
${JIRA_TICKET:+**JIRA Ticket**: ${JIRA_TICKET}}

---

### Incident Details

A production deployment to version \`${FAILED_VERSION}\` failed and was automatically rolled back to \`${ROLLBACK_VERSION}\`.

**Rollback Reason**: ${REASON}

### Required Actions

- [ ] Investigate root cause of deployment failure
- [ ] Review deployment logs and forensics
- [ ] Identify preventive measures
- [ ] Schedule post-mortem meeting (required per Article XIII)
- [ ] Document findings in \`contexts/retrospectives/deployment-rollbacks/\`
- [ ] Update deployment procedures if needed

### Forensics Location

Check production server for forensics:
\`\`\`
/var/backups/deployment-forensics/${FAILED_VERSION}-*/
\`\`\`

### Related Resources

- **Deployment Logs**: Check GitHub Actions workflow run
- **Monitoring**: Check Grafana deployment dashboard
- **Alerts**: Review Prometheus alerts during deployment window
${JIRA_TICKET:+- **JIRA**: ${JIRA_TICKET}}

---

**Note**: This incident requires a post-mortem per Constitutional Article XIII. Schedule within 48 hours.
EOF
)
    
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues"
    
    local response
    response=$(curl -s -X POST "$api_url" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -d @- <<EOF
{
  "title": "${issue_title}",
  "body": $(echo "$issue_body" | jq -Rs .),
  "labels": ["production-rollback", "incident", "high-priority"]
}
EOF
)
    
    local issue_number
    issue_number=$(echo "$response" | jq -r '.number')
    
    if [[ "$issue_number" != "null" && -n "$issue_number" ]]; then
        local issue_url
        issue_url=$(echo "$response" | jq -r '.html_url')
        success "GitHub issue created: $issue_url"
        echo "$issue_url" > /tmp/rollback-incident-issue.txt
        return 0
    else
        failure "Failed to create GitHub issue"
        echo "$response" >&2
        return 1
    fi
}

# Link GitHub issue to JIRA ticket
link_to_jira() {
    if [[ -z "$JIRA_TICKET" ]]; then
        warning "No JIRA ticket provided, skipping JIRA linking"
        return 0
    fi
    
    log "Linking incident to JIRA ticket ${JIRA_TICKET}..."
    
    local issue_url
    if [[ -f /tmp/rollback-incident-issue.txt ]]; then
        issue_url=$(cat /tmp/rollback-incident-issue.txt)
        
        # Add comment to GitHub issue with JIRA link
        local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/$(basename "$issue_url")/comments"
        
        curl -s -X POST "$api_url" \
            -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            -d "{\"body\": \"Linked to JIRA: ${JIRA_TICKET}\"}" \
            >/dev/null
        
        success "Linked to JIRA: ${JIRA_TICKET}"
    else
        warning "Could not link to JIRA (issue URL not found)"
    fi
}

# Send Slack notification
send_slack_notification() {
    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        warning "SLACK_WEBHOOK_URL not set, skipping Slack notification"
        return 0
    fi
    
    log "Sending Slack notification..."
    
    local issue_url=""
    if [[ -f /tmp/rollback-incident-issue.txt ]]; then
        issue_url=$(cat /tmp/rollback-incident-issue.txt)
    fi
    
    local slack_payload
    slack_payload=$(cat <<EOF
{
  "attachments": [
    {
      "color": "danger",
      "title": "🚨 Production Rollback",
      "text": "Production deployment rolled back",
      "fields": [
        {
          "title": "Failed Version",
          "value": "${FAILED_VERSION}",
          "short": true
        },
        {
          "title": "Rolled Back To",
          "value": "${ROLLBACK_VERSION}",
          "short": true
        },
        {
          "title": "Reason",
          "value": "${REASON}",
          "short": false
        }
        ${JIRA_TICKET:+,{
          "title": "JIRA Ticket",
          "value": "${JIRA_TICKET}",
          "short": true
        }}
        ${issue_url:+,{
          "title": "Incident Issue",
          "value": "<${issue_url}|View Issue>",
          "short": true
        }}
      ],
      "footer": "PAWS360 Deployment Monitor",
      "ts": $(date +%s)
    }
  ]
}
EOF
)
    
    if curl -s -X POST "$SLACK_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$slack_payload" \
        >/dev/null; then
        success "Slack notification sent"
    else
        failure "Failed to send Slack notification"
    fi
}

# Create PagerDuty incident
create_pagerduty_incident() {
    if [[ -z "$PAGERDUTY_API_KEY" ]]; then
        warning "PAGERDUTY_API_KEY not set, skipping PagerDuty incident"
        return 0
    fi
    
    log "Creating PagerDuty incident..."
    
    local issue_url=""
    if [[ -f /tmp/rollback-incident-issue.txt ]]; then
        issue_url=$(cat /tmp/rollback-incident-issue.txt)
    fi
    
    local pd_payload
    pd_payload=$(cat <<EOF
{
  "incident": {
    "type": "incident",
    "title": "Production Rollback: ${FAILED_VERSION} → ${ROLLBACK_VERSION}",
    "service": {
      "id": "PAWS360_PRODUCTION",
      "type": "service_reference"
    },
    "urgency": "high",
    "body": {
      "type": "incident_body",
      "details": "Production deployment to ${FAILED_VERSION} failed and was rolled back to ${ROLLBACK_VERSION}. Reason: ${REASON}. ${issue_url:+Incident: ${issue_url}}"
    }
  }
}
EOF
)
    
    if curl -s -X POST "https://api.pagerduty.com/incidents" \
        -H "Authorization: Token token=${PAGERDUTY_API_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        -d "$pd_payload" \
        >/dev/null; then
        success "PagerDuty incident created"
    else
        failure "Failed to create PagerDuty incident"
    fi
}

# Emit metrics to monitoring system
emit_rollback_metrics() {
    log "Emitting rollback metrics..."
    
    # Emit to Prometheus pushgateway (if available)
    local pushgateway_url="${PROMETHEUS_PUSHGATEWAY_URL:-http://localhost:9091}"
    
    local metrics
    metrics=$(cat <<EOF
# HELP deployment_rollback_total Total number of production deployment rollbacks
# TYPE deployment_rollback_total counter
deployment_rollback_total{failed_version="${FAILED_VERSION}",rollback_version="${ROLLBACK_VERSION}",reason="${REASON//\"/\\\"}"} 1
EOF
)
    
    if curl -s --data-binary "$metrics" "${pushgateway_url}/metrics/job/deployment_rollback" >/dev/null 2>&1; then
        success "Rollback metrics emitted"
    else
        warning "Could not emit metrics to Prometheus pushgateway (not available)"
    fi
}

# Main execution
main() {
    log "========================================="
    log "Production Rollback Notification"
    log "========================================="
    log "Failed Version: $FAILED_VERSION"
    log "Rollback Version: $ROLLBACK_VERSION"
    log "Reason: $REASON"
    log "JIRA Ticket: ${JIRA_TICKET:-N/A}"
    log "========================================="
    echo
    
    # Create incident tracking
    create_github_issue || failure "GitHub issue creation failed"
    link_to_jira
    
    # Send notifications
    send_slack_notification
    create_pagerduty_incident
    
    # Emit metrics
    emit_rollback_metrics
    
    echo
    log "========================================="
    log "Notification Complete"
    log "========================================="
    
    if [[ -f /tmp/rollback-incident-issue.txt ]]; then
        local issue_url
        issue_url=$(cat /tmp/rollback-incident-issue.txt)
        log "Incident Issue: $issue_url"
        log ""
        log "${YELLOW}REQUIRED: Schedule post-mortem within 48 hours (Article XIII)${NC}"
    fi
    
    log "========================================="
}

# Run
main
