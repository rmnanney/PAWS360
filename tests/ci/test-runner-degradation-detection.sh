#!/usr/bin/env bash
# Test Scenario 2.1: Runner Degradation Detection
# JIRA: INFRA-474
# Purpose: Verify that runner degradation is detected within 5 minutes

set -euo pipefail

# Test configuration
RUNNER_NAME="${RUNNER_NAME:-dell-r640-01-runner}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
DETECTION_TIMEOUT=300  # 5 minutes
CHECK_INTERVAL=15      # 15 seconds

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

# Function to check runner health from Prometheus
check_runner_health() {
    local runner=$1
    local query="runner_health{runner=\"$runner\"}"
    
    curl -s "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode "query=${query}" \
        | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0"
}

# Function to simulate runner degradation
simulate_degradation() {
    log_info "Simulating runner degradation on ${RUNNER_NAME}..."
    
    # Simulate high CPU load (backgrounded, will be killed later)
    ssh "${RUNNER_NAME}" 'nohup stress-ng --cpu 4 --timeout 600s > /dev/null 2>&1 &' || {
        log_warn "Could not simulate CPU load via SSH"
        return 1
    }
    
    log_info "Degradation simulation started"
    return 0
}

# Function to cleanup simulation
cleanup_simulation() {
    log_info "Cleaning up degradation simulation..."
    ssh "${RUNNER_NAME}" 'pkill -f stress-ng' 2>/dev/null || true
}

# Main test execution
main() {
    log_info "=== Test 2.1: Runner Degradation Detection ==="
    log_info "Runner: ${RUNNER_NAME}"
    log_info "Prometheus: ${PROMETHEUS_URL}"
    log_info "Detection timeout: ${DETECTION_TIMEOUT}s"
    
    # Step 1: Verify runner is initially healthy
    log_info "Step 1: Verifying initial runner health..."
    initial_health=$(check_runner_health "${RUNNER_NAME}")
    if [[ "${initial_health}" != "1" ]]; then
        log_error "Runner ${RUNNER_NAME} is not healthy initially (health=${initial_health})"
        exit 1
    fi
    log_info "✓ Runner is healthy"
    
    # Step 2: Simulate degradation
    log_info "Step 2: Simulating runner degradation..."
    if ! simulate_degradation; then
        log_warn "Degradation simulation failed - test may not be accurate"
        log_info "Proceeding with manual degradation check..."
    fi
    
    # Step 3: Monitor for degradation detection
    log_info "Step 3: Monitoring for degradation detection..."
    elapsed=0
    detected=false
    
    while [[ ${elapsed} -lt ${DETECTION_TIMEOUT} ]]; do
        sleep ${CHECK_INTERVAL}
        elapsed=$((elapsed + CHECK_INTERVAL))
        
        # Check if degradation was detected
        current_health=$(check_runner_health "${RUNNER_NAME}")
        
        if [[ "${current_health}" != "1" ]]; then
            detected=true
            log_info "✓ Degradation detected after ${elapsed}s (health=${current_health})"
            break
        fi
        
        log_info "  Checking... ${elapsed}s elapsed (health=${current_health})"
    done
    
    # Step 4: Cleanup
    cleanup_simulation
    
    # Step 5: Evaluate results
    if ${detected}; then
        log_info "=== TEST PASSED ==="
        log_info "Runner degradation was detected within ${DETECTION_TIMEOUT}s"
        exit 0
    else
        log_error "=== TEST FAILED ==="
        log_error "Runner degradation was NOT detected within ${DETECTION_TIMEOUT}s"
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup_simulation EXIT INT TERM

main "$@"
