#!/usr/bin/env bash
# Push Deployment Metrics to Prometheus Pushgateway
# JIRA: INFRA-474
# Purpose: Emit custom deployment metrics for monitoring and alerting

set -euo pipefail

# Configuration
PUSHGATEWAY_URL="${PROMETHEUS_PUSHGATEWAY_URL:-http://192.168.0.200:9091}"
JOB_NAME="deployment_metrics"
INSTANCE="${HOSTNAME:-$(hostname)}"

# Deployment metadata (passed as environment variables or arguments)
DEPLOYMENT_STATUS="${1:-unknown}"           # success or failed
DEPLOYMENT_DURATION="${2:-0}"               # seconds
DEPLOYMENT_RUNNER="${3:-unknown}"           # primary or secondary
DEPLOYMENT_ENVIRONMENT="${4:-unknown}"      # production, staging, development
DEPLOYMENT_FAILURE_REASON="${5:-none}"      # failure reason if failed
WORKFLOW_NAME="${6:-unknown}"               # GitHub workflow name
RUN_ID="${GITHUB_RUN_ID:-unknown}"
RUN_NUMBER="${GITHUB_RUN_NUMBER:-unknown}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Validate inputs
validate_inputs() {
    if [ "$DEPLOYMENT_STATUS" != "success" ] && [ "$DEPLOYMENT_STATUS" != "failed" ]; then
        error "Invalid deployment status: $DEPLOYMENT_STATUS (must be 'success' or 'failed')"
        exit 1
    fi
    
    if ! [[ "$DEPLOYMENT_DURATION" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        error "Invalid deployment duration: $DEPLOYMENT_DURATION (must be numeric)"
        exit 1
    fi
    
    log "Validated inputs:"
    log "  Status: $DEPLOYMENT_STATUS"
    log "  Duration: ${DEPLOYMENT_DURATION}s"
    log "  Runner: $DEPLOYMENT_RUNNER"
    log "  Environment: $DEPLOYMENT_ENVIRONMENT"
    log "  Failure Reason: $DEPLOYMENT_FAILURE_REASON"
}

# Generate metrics in Prometheus format
generate_metrics() {
    cat <<EOF
# HELP deployment_duration_seconds Time taken for deployment to complete
# TYPE deployment_duration_seconds histogram
deployment_duration_seconds{environment="$DEPLOYMENT_ENVIRONMENT",runner="$DEPLOYMENT_RUNNER",workflow="$WORKFLOW_NAME",status="$DEPLOYMENT_STATUS"} $DEPLOYMENT_DURATION

# HELP deployment_status Total count of deployments by status
# TYPE deployment_status counter
deployment_status{status="$DEPLOYMENT_STATUS",environment="$DEPLOYMENT_ENVIRONMENT",runner="$DEPLOYMENT_RUNNER",workflow="$WORKFLOW_NAME",failure_reason="$DEPLOYMENT_FAILURE_REASON"} 1

# HELP deployment_runner Deployments by runner
# TYPE deployment_runner counter
deployment_runner{runner="$DEPLOYMENT_RUNNER",environment="$DEPLOYMENT_ENVIRONMENT",status="$DEPLOYMENT_STATUS"} 1

# HELP deployment_fail_reason Deployment failures by reason
# TYPE deployment_fail_reason counter
deployment_fail_reason{failure_reason="$DEPLOYMENT_FAILURE_REASON",environment="$DEPLOYMENT_ENVIRONMENT",runner="$DEPLOYMENT_RUNNER"} $([ "$DEPLOYMENT_STATUS" = "failed" ] && echo "1" || echo "0")

# HELP deployment_timestamp_seconds Unix timestamp of deployment completion
# TYPE deployment_timestamp_seconds gauge
deployment_timestamp_seconds{environment="$DEPLOYMENT_ENVIRONMENT",runner="$DEPLOYMENT_RUNNER",status="$DEPLOYMENT_STATUS"} $(date +%s)

# HELP deployment_run_id GitHub Actions run ID
# TYPE deployment_run_id gauge
deployment_run_id{environment="$DEPLOYMENT_ENVIRONMENT",workflow="$WORKFLOW_NAME",run_number="$RUN_NUMBER"} $RUN_ID

# HELP deployment_in_progress Currently active deployments
# TYPE deployment_in_progress gauge
deployment_in_progress{environment="$DEPLOYMENT_ENVIRONMENT",runner="$DEPLOYMENT_RUNNER"} 0
EOF
}

# Push metrics to Pushgateway
push_metrics() {
    local metrics
    metrics=$(generate_metrics)
    
    log "Generated metrics:"
    echo "$metrics" | grep -v "^#" | sed 's/^/  /'
    echo ""
    
    local pushgateway_endpoint="${PUSHGATEWAY_URL}/metrics/job/${JOB_NAME}/instance/${INSTANCE}"
    
    log "Pushing metrics to Pushgateway: $pushgateway_endpoint"
    
    if echo "$metrics" | curl -sf --data-binary @- "$pushgateway_endpoint" >/dev/null 2>&1; then
        log "✓ Metrics pushed successfully to Pushgateway"
        return 0
    else
        error "✗ Failed to push metrics to Pushgateway"
        error "   Pushgateway URL: $pushgateway_endpoint"
        error "   Check if Pushgateway is reachable and accepting metrics"
        return 1
    fi
}

# Verify pushgateway is accessible
check_pushgateway() {
    log "Checking Pushgateway availability: $PUSHGATEWAY_URL"
    
    if curl -sf "${PUSHGATEWAY_URL}/metrics" >/dev/null 2>&1; then
        log "✓ Pushgateway is accessible"
        return 0
    else
        warn "⚠ Pushgateway is not accessible at $PUSHGATEWAY_URL"
        warn "   Metrics will not be pushed. This is not a fatal error."
        warn "   Ensure Pushgateway is running: systemctl status prometheus-pushgateway"
        return 1
    fi
}

# Generate summary for GitHub Actions
generate_github_summary() {
    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
        cat >> "$GITHUB_STEP_SUMMARY" <<EOF

### 📊 Deployment Metrics

| Metric | Value |
|--------|-------|
| **Status** | $([ "$DEPLOYMENT_STATUS" = "success" ] && echo "✅ Success" || echo "❌ Failed") |
| **Duration** | ${DEPLOYMENT_DURATION}s |
| **Runner** | \`$DEPLOYMENT_RUNNER\` |
| **Environment** | \`$DEPLOYMENT_ENVIRONMENT\` |
| **Workflow** | \`$WORKFLOW_NAME\` |
| **Run** | #$RUN_NUMBER |
$([ "$DEPLOYMENT_STATUS" = "failed" ] && echo "| **Failure Reason** | \`$DEPLOYMENT_FAILURE_REASON\` |" || echo "")

**Metrics Pushed to Pushgateway**: $PUSHGATEWAY_URL

EOF
        log "✓ GitHub Step Summary updated"
    fi
}

# Main execution
main() {
    log "=== Deployment Metrics Collection ==="
    
    # Validate inputs
    validate_inputs
    echo ""
    
    # Check pushgateway availability
    if ! check_pushgateway; then
        warn "Continuing without metrics push..."
        exit 0  # Don't fail deployment if metrics can't be pushed
    fi
    echo ""
    
    # Push metrics
    if push_metrics; then
        log "✓ Metrics collection successful"
    else
        error "✗ Metrics collection failed"
        exit 1
    fi
    echo ""
    
    # Generate GitHub summary if running in Actions
    generate_github_summary
    
    log "=== Metrics collection complete ==="
}

# Usage information
usage() {
    cat <<EOF
Usage: $0 <status> <duration> <runner> <environment> [failure_reason] [workflow_name]

Arguments:
  status            Deployment status (success|failed)
  duration          Deployment duration in seconds
  runner            Runner name (primary|secondary|hostname)
  environment       Deployment environment (production|staging|development)
  failure_reason    Failure reason if status=failed (optional, default: none)
  workflow_name     GitHub workflow name (optional, default: unknown)

Environment Variables:
  PROMETHEUS_PUSHGATEWAY_URL  Pushgateway URL (default: http://192.168.0.200:9091)
  GITHUB_RUN_ID               GitHub Actions run ID
  GITHUB_RUN_NUMBER           GitHub Actions run number
  GITHUB_STEP_SUMMARY         Path to GitHub step summary file

Examples:
  # Successful deployment
  $0 success 245 primary production

  # Failed deployment
  $0 failed 180 secondary staging network_connectivity deploy-production

  # With environment variables
  export PROMETHEUS_PUSHGATEWAY_URL="http://monitoring.example.com:9091"
  $0 success 300 primary production none ci-deployment

EOF
    exit 1
}

# Check for help flag
if [ $# -eq 0 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
fi

# Run main function
main "$@"
