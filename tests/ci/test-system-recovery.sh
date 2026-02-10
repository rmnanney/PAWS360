#!/usr/bin/env bash
# Test Scenario 2.4: System Recovery Verification
# JIRA: INFRA-474
# Purpose: Verify system automatically recovers to normal state after degradation

set -euo pipefail

# Test configuration
PRIMARY_RUNNER="${PRIMARY_RUNNER:-dell-r640-01-runner}"
SECONDARY_RUNNER="${SECONDARY_RUNNER:-Serotonin-paws360}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
RECOVERY_TIMEOUT=900  # 15 minutes
CHECK_INTERVAL=30     # 30 seconds

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

# Function to check runner health
check_runner_health() {
    local runner=$1
    local query="runner_health{runner=\"$runner\"}"
    
    curl -s "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode "query=${query}" \
        | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0"
}

# Function to check system metrics
get_system_metrics() {
    local runner=$1
    
    # Get CPU usage
    local cpu_query="100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\",instance=~\"${runner}.*\"}[5m])) * 100)"
    local cpu=$(curl -s "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode "query=${cpu_query}" \
        | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    
    # Get memory usage
    local mem_query="(1 - (node_memory_MemAvailable_bytes{instance=~\"${runner}.*\"} / node_memory_MemTotal_bytes{instance=~\"${runner}.*\"})) * 100"
    local mem=$(curl -s "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode "query=${mem_query}" \
        | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    
    echo "${cpu}|${mem}"
}

# Function to check if metrics are in normal range
metrics_in_normal_range() {
    local metrics=$1
    local cpu=$(echo "${metrics}" | cut -d'|' -f1)
    local mem=$(echo "${metrics}" | cut -d'|' -f2)
    
    # Normal ranges: CPU < 70%, Memory < 80%
    local cpu_ok=$(echo "${cpu} < 70" | bc -l || echo "0")
    local mem_ok=$(echo "${mem} < 80" | bc -l || echo "0")
    
    if [[ "${cpu_ok}" == "1" ]] && [[ "${mem_ok}" == "1" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to simulate degradation
simulate_degradation() {
    local runner=$1
    log_info "Simulating degradation on ${runner}..."
    
    # Simulate high load
    ssh "${runner}" 'nohup stress-ng --cpu 4 --vm 2 --vm-bytes 50% --timeout 180s > /dev/null 2>&1 &' || {
        log_warn "Could not simulate degradation via SSH"
        return 1
    }
    
    log_info "Degradation simulation started"
    return 0
}

# Function to stop degradation simulation
stop_degradation() {
    local runner=$1
    log_info "Stopping degradation on ${runner}..."
    ssh "${runner}" 'pkill -f stress-ng' 2>/dev/null || true
}

# Test recovery for a single runner
test_runner_recovery() {
    local runner=$1
    
    log_info "--- Testing recovery for: ${runner} ---"
    
    # Step 1: Check initial state
    log_info "Step 1: Checking initial state..."
    local initial_health=$(check_runner_health "${runner}")
    local initial_metrics=$(get_system_metrics "${runner}")
    log_info "  Initial health: ${initial_health}"
    log_info "  Initial metrics: ${initial_metrics}"
    
    # Step 2: Simulate degradation
    log_info "Step 2: Simulating degradation..."
    if ! simulate_degradation "${runner}"; then
        log_warn "Degradation simulation failed for ${runner}"
        return 1
    fi
    
    # Wait for degradation to be detected
    sleep 60
    
    # Step 3: Verify degradation detected
    log_info "Step 3: Verifying degradation detected..."
    local degraded_health=$(check_runner_health "${runner}")
    local degraded_metrics=$(get_system_metrics "${runner}")
    log_info "  Degraded health: ${degraded_health}"
    log_info "  Degraded metrics: ${degraded_metrics}"
    
    if [[ "${degraded_health}" == "${initial_health}" ]]; then
        log_warn "Degradation may not have been detected"
    fi
    
    # Step 4: Stop degradation and monitor recovery
    log_info "Step 4: Stopping degradation and monitoring recovery..."
    stop_degradation "${runner}"
    
    elapsed=0
    recovered=false
    
    while [[ ${elapsed} -lt ${RECOVERY_TIMEOUT} ]]; do
        sleep ${CHECK_INTERVAL}
        elapsed=$((elapsed + CHECK_INTERVAL))
        
        # Check health and metrics
        local current_health=$(check_runner_health "${runner}")
        local current_metrics=$(get_system_metrics "${runner}")
        
        log_info "  ${elapsed}s: health=${current_health}, metrics=${current_metrics}"
        
        # Check if recovered
        if [[ "${current_health}" == "1" ]] && metrics_in_normal_range "${current_metrics}"; then
            recovered=true
            log_info "✓ Recovery detected after ${elapsed}s"
            break
        fi
    done
    
    if ${recovered}; then
        log_info "✓ Runner ${runner} recovery test PASSED"
        return 0
    else
        log_error "✗ Runner ${runner} recovery test FAILED (timeout)"
        return 1
    fi
}

# Main test execution
main() {
    log_info "=== Test 2.4: System Recovery Verification ==="
    log_info "Primary: ${PRIMARY_RUNNER}"
    log_info "Secondary: ${SECONDARY_RUNNER}"
    log_info "Prometheus: ${PROMETHEUS_URL}"
    log_info "Recovery timeout: ${RECOVERY_TIMEOUT}s"
    
    # Track test results
    passed=0
    failed=0
    
    # Test primary runner recovery
    if test_runner_recovery "${PRIMARY_RUNNER}"; then
        ((passed++))
    else
        ((failed++))
    fi
    
    # Wait between tests
    log_info "Waiting 60s between tests..."
    sleep 60
    
    # Test secondary runner recovery
    if test_runner_recovery "${SECONDARY_RUNNER}"; then
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
trap 'stop_degradation "${PRIMARY_RUNNER}"; stop_degradation "${SECONDARY_RUNNER}"' EXIT INT TERM

main "$@"
