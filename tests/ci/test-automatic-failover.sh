#!/usr/bin/env bash
# Test Scenario 2.2: Automatic Failover Execution
# JIRA: INFRA-474
# Purpose: Verify that automatic failover executes within 10 minutes

set -euo pipefail

# Test configuration
PRIMARY_RUNNER="${PRIMARY_RUNNER:-dell-r640-01-runner}"
SECONDARY_RUNNER="${SECONDARY_RUNNER:-Serotonin-paws360}"
GITHUB_ORG="${GITHUB_ORG:-rmnanney}"
GITHUB_REPO="${GITHUB_REPO:-PAWS360}"
FAILOVER_TIMEOUT=600  # 10 minutes
CHECK_INTERVAL=20     # 20 seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Function to check which runner is handling jobs
get_active_runner() {
    gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners" \
        --jq '.runners[] | select(.status=="online" and .busy==true) | .name' \
        2>/dev/null || echo "none"
}

# Function to count runners by status
count_runners_by_status() {
    local status=$1
    gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners" \
        --jq ".runners[] | select(.status==\"${status}\") | .name" \
        2>/dev/null | wc -l
}

# Function to trigger a test workflow
trigger_test_workflow() {
    log_info "Triggering test workflow..."
    
    gh workflow run "ci-quick.yml" \
        --repo "${GITHUB_ORG}/${GITHUB_REPO}" \
        --ref main \
        2>/dev/null || {
        log_warn "Could not trigger workflow via gh CLI"
        return 1
    }
    
    sleep 5  # Wait for workflow to queue
    return 0
}

# Function to simulate primary runner failure
simulate_primary_failure() {
    log_info "Simulating primary runner failure: ${PRIMARY_RUNNER}..."
    
    # Stop runner service
    ssh "${PRIMARY_RUNNER}" 'sudo systemctl stop actions.runner.*' || {
        log_warn "Could not stop runner service via SSH"
        return 1
    }
    
    log_info "Primary runner stopped"
    return 0
}

# Function to restore primary runner
restore_primary_runner() {
    log_info "Restoring primary runner: ${PRIMARY_RUNNER}..."
    ssh "${PRIMARY_RUNNER}" 'sudo systemctl start actions.runner.*' 2>/dev/null || true
}

# Main test execution
main() {
    log_info "=== Test 2.2: Automatic Failover Execution ==="
    log_info "Primary: ${PRIMARY_RUNNER}"
    log_info "Secondary: ${SECONDARY_RUNNER}"
    log_info "Repository: ${GITHUB_ORG}/${GITHUB_REPO}"
    log_info "Failover timeout: ${FAILOVER_TIMEOUT}s"
    
    # Step 1: Verify both runners are initially online
    log_info "Step 1: Verifying initial runner status..."
    online_count=$(count_runners_by_status "online")
    if [[ ${online_count} -lt 2 ]]; then
        log_error "Expected 2 online runners, found ${online_count}"
        exit 1
    fi
    log_info "✓ Both runners online"
    
    # Step 2: Trigger test workflow
    log_info "Step 2: Triggering test workflow..."
    if ! trigger_test_workflow; then
        log_error "Failed to trigger test workflow"
        exit 1
    fi
    log_info "✓ Workflow triggered"
    
    # Step 3: Verify workflow starts on primary
    log_info "Step 3: Verifying workflow starts on primary runner..."
    sleep 10  # Wait for job to start
    active_runner=$(get_active_runner)
    if [[ "${active_runner}" != "${PRIMARY_RUNNER}" ]]; then
        log_warn "Workflow not on primary runner (on: ${active_runner})"
        log_info "Continuing with failover test..."
    else
        log_info "✓ Workflow running on primary: ${active_runner}"
    fi
    
    # Step 4: Simulate primary failure
    log_info "Step 4: Simulating primary runner failure..."
    if ! simulate_primary_failure; then
        log_warn "Primary failure simulation incomplete - test may not be accurate"
    fi
    
    # Step 5: Monitor for automatic failover
    log_info "Step 5: Monitoring for automatic failover to secondary..."
    elapsed=0
    failover_detected=false
    
    while [[ ${elapsed} -lt ${FAILOVER_TIMEOUT} ]]; do
        sleep ${CHECK_INTERVAL}
        elapsed=$((elapsed + CHECK_INTERVAL))
        
        # Check if workflow moved to secondary
        active_runner=$(get_active_runner)
        
        if [[ "${active_runner}" == "${SECONDARY_RUNNER}" ]]; then
            failover_detected=true
            log_info "✓ Failover detected after ${elapsed}s"
            log_info "  Workflow now running on: ${active_runner}"
            break
        fi
        
        log_info "  Checking... ${elapsed}s elapsed (active: ${active_runner})"
    done
    
    # Step 6: Cleanup
    restore_primary_runner
    
    # Step 7: Evaluate results
    if ${failover_detected}; then
        log_info "=== TEST PASSED ==="
        log_info "Automatic failover executed within ${FAILOVER_TIMEOUT}s"
        exit 0
    else
        log_error "=== TEST FAILED ==="
        log_error "Automatic failover did NOT execute within ${FAILOVER_TIMEOUT}s"
        exit 1
    fi
}

# Trap cleanup on exit
trap restore_primary_runner EXIT INT TERM

main "$@"
