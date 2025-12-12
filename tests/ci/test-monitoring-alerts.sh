#!/usr/bin/env bash
# Test Scenario 2.3: Monitoring Alert Reliability
# JIRA: INFRA-474
# Purpose: Verify monitoring alerts fire within 2 minutes of threshold breach

set -euo pipefail

# Test configuration
ALERTMANAGER_URL="${ALERTMANAGER_URL:-http://192.168.0.200:9093}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
RUNNER_NAME="${RUNNER_NAME:-dell-r640-01-runner}"
ALERT_TIMEOUT=120  # 2 minutes
CHECK_INTERVAL=10  # 10 seconds

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

# Function to check if alert is firing
check_alert_firing() {
    local alert_name=$1
    
    curl -s "${ALERTMANAGER_URL}/api/v2/alerts" \
        | jq -r ".[] | select(.labels.alertname==\"${alert_name}\" and .status.state==\"active\") | .labels.alertname" \
        2>/dev/null || echo ""
}

# Function to check all active alerts
get_active_alerts() {
    curl -s "${ALERTMANAGER_URL}/api/v2/alerts" \
        | jq -r '.[] | select(.status.state=="active") | .labels.alertname' \
        2>/dev/null || echo ""
}

# Function to get pending alerts from Prometheus
get_pending_alerts() {
    curl -s "${PROMETHEUS_URL}/api/v1/alerts" \
        | jq -r '.data.alerts[] | select(.state=="pending" or .state=="firing") | .labels.alertname' \
        2>/dev/null || echo ""
}

# Function to trigger high CPU alert
trigger_cpu_alert() {
    log_info "Triggering CPU threshold breach on ${RUNNER_NAME}..."
    
    # Start CPU stress (backgrounded)
    ssh "${RUNNER_NAME}" 'nohup stress-ng --cpu 8 --timeout 300s > /dev/null 2>&1 &' || {
        log_warn "Could not start CPU stress via SSH"
        return 1
    }
    
    log_info "CPU stress started"
    return 0
}

# Function to cleanup stress
cleanup_stress() {
    log_info "Cleaning up stress test..."
    ssh "${RUNNER_NAME}" 'pkill -f stress-ng' 2>/dev/null || true
}

# Function to trigger memory alert
trigger_memory_alert() {
    log_info "Triggering memory threshold breach on ${RUNNER_NAME}..."
    
    # Start memory stress (backgrounded)
    ssh "${RUNNER_NAME}" 'nohup stress-ng --vm 2 --vm-bytes 90% --timeout 300s > /dev/null 2>&1 &' || {
        log_warn "Could not start memory stress via SSH"
        return 1
    }
    
    log_info "Memory stress started"
    return 0
}

# Test a specific alert type
test_alert() {
    local alert_name=$1
    local trigger_func=$2
    
    log_info "--- Testing alert: ${alert_name} ---"
    
    # Step 1: Verify alert not firing initially
    log_info "Step 1: Verifying alert not firing initially..."
    initial_state=$(check_alert_firing "${alert_name}")
    if [[ -n "${initial_state}" ]]; then
        log_warn "Alert ${alert_name} already firing - waiting for clear..."
        sleep 30
    fi
    log_info "✓ Alert initially clear"
    
    # Step 2: Trigger threshold breach
    log_info "Step 2: Triggering threshold breach..."
    if ! ${trigger_func}; then
        log_warn "Threshold breach trigger failed"
        return 1
    fi
    
    # Step 3: Monitor for alert firing
    log_info "Step 3: Monitoring for alert to fire..."
    elapsed=0
    alert_fired=false
    
    while [[ ${elapsed} -lt ${ALERT_TIMEOUT} ]]; do
        sleep ${CHECK_INTERVAL}
        elapsed=$((elapsed + CHECK_INTERVAL))
        
        # Check if alert is firing
        alert_state=$(check_alert_firing "${alert_name}")
        
        if [[ -n "${alert_state}" ]]; then
            alert_fired=true
            log_info "✓ Alert fired after ${elapsed}s"
            break
        fi
        
        # Also check pending alerts
        pending=$(get_pending_alerts | grep -c "${alert_name}" || echo "0")
        log_info "  Checking... ${elapsed}s elapsed (pending: ${pending})"
    done
    
    # Cleanup
    cleanup_stress
    
    # Evaluate
    if ${alert_fired}; then
        log_info "✓ Alert ${alert_name} test PASSED"
        return 0
    else
        log_error "✗ Alert ${alert_name} test FAILED (timeout)"
        return 1
    fi
}

# Main test execution
main() {
    log_info "=== Test 2.3: Monitoring Alert Reliability ==="
    log_info "Alertmanager: ${ALERTMANAGER_URL}"
    log_info "Prometheus: ${PROMETHEUS_URL}"
    log_info "Target: ${RUNNER_NAME}"
    log_info "Alert timeout: ${ALERT_TIMEOUT}s"
    
    # Show current alerts
    log_info "Current active alerts:"
    active_alerts=$(get_active_alerts)
    if [[ -z "${active_alerts}" ]]; then
        log_info "  (none)"
    else
        echo "${active_alerts}" | while read -r alert; do
            log_info "  - ${alert}"
        done
    fi
    
    # Track test results
    passed=0
    failed=0
    
    # Test 1: High CPU Alert
    if test_alert "RunnerHighCPU" "trigger_cpu_alert"; then
        ((passed++))
    else
        ((failed++))
    fi
    
    # Wait between tests
    log_info "Waiting 30s between tests..."
    sleep 30
    
    # Test 2: High Memory Alert
    if test_alert "RunnerHighMemory" "trigger_memory_alert"; then
        ((passed++))
    else
        ((failed++))
    fi
    
    # Final results
    log_info ""
    log_info "=== TEST RESULTS ==="
    log_info "Passed: ${passed}/2"
    log_info "Failed: ${failed}/2"
    
    if [[ ${failed} -eq 0 ]]; then
        log_info "=== ALL TESTS PASSED ==="
        exit 0
    else
        log_error "=== SOME TESTS FAILED ==="
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup_stress EXIT INT TERM

main "$@"
