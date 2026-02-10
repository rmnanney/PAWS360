#!/usr/bin/env bash
# CI/CD Runner Deployment Health Check Script
# JIRA: INFRA-474
# Purpose: Comprehensive health validation for CI/CD runner infrastructure

set -euo pipefail

# Configuration
PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://192.168.0.200:3000}"
LOKI_URL="${LOKI_URL:-http://192.168.0.200:3100}"
GITHUB_ORG="${GITHUB_ORG:-rpalermodrums}"
GITHUB_REPO="${GITHUB_REPO:-PAWS360}"

# Thresholds
CPU_THRESHOLD=70
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
MIN_RUNNERS=2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Flags
COMPREHENSIVE=false
VERBOSE=false
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --comprehensive|-c)
            COMPREHENSIVE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --json|-j)
            JSON_OUTPUT=true
            shift
            ;;
        --help|-h)
            cat <<EOF
CI/CD Runner Deployment Health Check

Usage: $0 [OPTIONS]

Options:
  -c, --comprehensive    Run comprehensive checks (includes stress tests)
  -v, --verbose         Verbose output with detailed metrics
  -j, --json            Output results in JSON format
  -h, --help            Show this help message

Examples:
  $0                    # Quick health check
  $0 --comprehensive    # Full health validation
  $0 --json             # JSON output for automation

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    if ! $JSON_OUTPUT; then
        echo -e "${BLUE}[INFO]${NC} $*"
    fi
}

log_pass() {
    ((CHECKS_PASSED++))
    if ! $JSON_OUTPUT; then
        echo -e "${GREEN}[PASS]${NC} $*"
    fi
}

log_fail() {
    ((CHECKS_FAILED++))
    if ! $JSON_OUTPUT; then
        echo -e "${RED}[FAIL]${NC} $*"
    fi
}

log_warn() {
    ((CHECKS_WARNING++))
    if ! $JSON_OUTPUT; then
        echo -e "${YELLOW}[WARN]${NC} $*"
    fi
}

# JSON result storage
declare -A check_results

add_result() {
    local category=$1
    local check=$2
    local status=$3
    local message=$4
    check_results["${category}.${check}"]="${status}|${message}"
}

# Check Prometheus availability
check_prometheus() {
    log_info "Checking Prometheus availability..."
    
    if curl -sf "${PROMETHEUS_URL}/-/healthy" > /dev/null 2>&1; then
        log_pass "Prometheus is healthy"
        add_result "monitoring" "prometheus" "pass" "Healthy"
        return 0
    else
        log_fail "Prometheus is not responding"
        add_result "monitoring" "prometheus" "fail" "Not responding"
        return 1
    fi
}

# Check Grafana availability
check_grafana() {
    log_info "Checking Grafana availability..."
    
    local response
    response=$(curl -sf "${GRAFANA_URL}/api/health" 2>/dev/null || echo "")
    
    if [[ -n "${response}" ]]; then
        local status
        status=$(echo "${response}" | jq -r '.database' 2>/dev/null || echo "unknown")
        if [[ "${status}" == "ok" ]]; then
            log_pass "Grafana is healthy"
            add_result "monitoring" "grafana" "pass" "Healthy"
            return 0
        else
            log_warn "Grafana database status: ${status}"
            add_result "monitoring" "grafana" "warn" "Database status: ${status}"
            return 1
        fi
    else
        log_fail "Grafana is not responding"
        add_result "monitoring" "grafana" "fail" "Not responding"
        return 1
    fi
}

# Check Loki availability
check_loki() {
    log_info "Checking Loki availability..."
    
    if curl -sf "${LOKI_URL}/ready" > /dev/null 2>&1; then
        log_pass "Loki is ready"
        add_result "monitoring" "loki" "pass" "Ready"
        return 0
    else
        log_warn "Loki is not responding (optional service)"
        add_result "monitoring" "loki" "warn" "Not responding"
        return 1
    fi
}

# Check GitHub runner status
check_runners() {
    log_info "Checking GitHub runner status..."
    
    local runners_json
    runners_json=$(gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners" 2>/dev/null || echo "")
    
    if [[ -z "${runners_json}" ]]; then
        log_fail "Cannot query GitHub runners (check gh authentication)"
        add_result "runners" "availability" "fail" "Cannot query runners"
        return 1
    fi
    
    local online_count
    online_count=$(echo "${runners_json}" | jq '[.runners[] | select(.status=="online")] | length' 2>/dev/null || echo "0")
    
    if [[ ${online_count} -ge ${MIN_RUNNERS} ]]; then
        log_pass "${online_count} runners online (minimum: ${MIN_RUNNERS})"
        add_result "runners" "availability" "pass" "${online_count} online"
        
        # List runner details if verbose
        if $VERBOSE; then
            echo "${runners_json}" | jq -r '.runners[] | "  - \(.name): \(.status) (busy: \(.busy))"'
        fi
        return 0
    elif [[ ${online_count} -gt 0 ]]; then
        log_warn "${online_count} runners online (minimum: ${MIN_RUNNERS})"
        add_result "runners" "availability" "warn" "Only ${online_count} online"
        return 1
    else
        log_fail "No runners online"
        add_result "runners" "availability" "fail" "No runners online"
        return 1
    fi
}

# Check runner metrics
check_runner_metrics() {
    log_info "Checking runner resource metrics..."
    
    local runners_json
    runners_json=$(gh api "/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners" 2>/dev/null || echo "")
    
    if [[ -z "${runners_json}" ]]; then
        log_warn "Cannot check runner metrics (runners unavailable)"
        return 1
    fi
    
    local all_healthy=true
    
    echo "${runners_json}" | jq -r '.runners[] | select(.status=="online") | .name' | while read -r runner; do
        log_info "  Checking ${runner}..."
        
        # CPU usage
        local cpu_usage
        cpu_usage=$(curl -s "${PROMETHEUS_URL}/api/v1/query" \
            --data-urlencode "query=100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\",instance=~\"${runner}.*\"}[5m])) * 100)" \
            | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        cpu_usage=$(printf "%.0f" "${cpu_usage}" 2>/dev/null || echo "0")
        
        # Memory usage
        local mem_usage
        mem_usage=$(curl -s "${PROMETHEUS_URL}/api/v1/query" \
            --data-urlencode "query=(1 - (node_memory_MemAvailable_bytes{instance=~\"${runner}.*\"} / node_memory_MemTotal_bytes{instance=~\"${runner}.*\"})) * 100" \
            | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        mem_usage=$(printf "%.0f" "${mem_usage}" 2>/dev/null || echo "0")
        
        # Disk usage
        local disk_usage
        disk_usage=$(curl -s "${PROMETHEUS_URL}/api/v1/query" \
            --data-urlencode "query=(1 - (node_filesystem_avail_bytes{instance=~\"${runner}.*\",mountpoint=\"/\"} / node_filesystem_size_bytes{instance=~\"${runner}.*\",mountpoint=\"/\"})) * 100" \
            | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        disk_usage=$(printf "%.0f" "${disk_usage}" 2>/dev/null || echo "0")
        
        # Evaluate thresholds
        local status="healthy"
        if [[ ${cpu_usage} -gt ${CPU_THRESHOLD} ]] || [[ ${mem_usage} -gt ${MEMORY_THRESHOLD} ]] || [[ ${disk_usage} -gt ${DISK_THRESHOLD} ]]; then
            status="degraded"
            all_healthy=false
        fi
        
        if $VERBOSE || [[ "${status}" != "healthy" ]]; then
            echo "    CPU: ${cpu_usage}% | Memory: ${mem_usage}% | Disk: ${disk_usage}% [${status}]"
        fi
        
        add_result "runners" "${runner}" "${status}" "CPU:${cpu_usage}% MEM:${mem_usage}% DISK:${disk_usage}%"
    done
    
    if $all_healthy; then
        log_pass "All runner metrics within thresholds"
        return 0
    else
        log_warn "Some runners have metrics above thresholds"
        return 1
    fi
}

# Check for active alerts
check_alerts() {
    log_info "Checking for active alerts..."
    
    local alerts_json
    alerts_json=$(curl -s "${PROMETHEUS_URL}/api/v1/alerts" 2>/dev/null || echo "")
    
    if [[ -z "${alerts_json}" ]]; then
        log_warn "Cannot query alerts"
        add_result "monitoring" "alerts" "warn" "Cannot query"
        return 1
    fi
    
    local firing_count
    firing_count=$(echo "${alerts_json}" | jq '[.data.alerts[] | select(.state=="firing")] | length' 2>/dev/null || echo "0")
    
    if [[ ${firing_count} -eq 0 ]]; then
        log_pass "No active alerts"
        add_result "monitoring" "alerts" "pass" "No active alerts"
        return 0
    else
        log_warn "${firing_count} active alert(s)"
        
        # List alerts if verbose
        if $VERBOSE; then
            echo "${alerts_json}" | jq -r '.data.alerts[] | select(.state=="firing") | "  - [\(.labels.severity)] \(.labels.alertname): \(.annotations.summary // "No summary")"'
        fi
        
        add_result "monitoring" "alerts" "warn" "${firing_count} firing"
        return 1
    fi
}

# Check recent workflow success rate
check_workflow_success_rate() {
    log_info "Checking recent workflow success rate..."
    
    local runs_json
    runs_json=$(gh run list --limit 50 --json status,conclusion 2>/dev/null || echo "")
    
    if [[ -z "${runs_json}" ]]; then
        log_warn "Cannot query workflow runs"
        add_result "workflows" "success_rate" "warn" "Cannot query"
        return 1
    fi
    
    local total
    total=$(echo "${runs_json}" | jq 'length' 2>/dev/null || echo "0")
    
    if [[ ${total} -eq 0 ]]; then
        log_warn "No recent workflow runs found"
        add_result "workflows" "success_rate" "warn" "No runs"
        return 1
    fi
    
    local success
    success=$(echo "${runs_json}" | jq '[.[] | select(.conclusion=="success")] | length' 2>/dev/null || echo "0")
    
    local rate=0
    if [[ ${total} -gt 0 ]]; then
        rate=$((success * 100 / total))
    fi
    
    if [[ ${rate} -ge 90 ]]; then
        log_pass "Workflow success rate: ${rate}% (${success}/${total})"
        add_result "workflows" "success_rate" "pass" "${rate}%"
        return 0
    elif [[ ${rate} -ge 70 ]]; then
        log_warn "Workflow success rate: ${rate}% (${success}/${total})"
        add_result "workflows" "success_rate" "warn" "${rate}%"
        return 1
    else
        log_fail "Workflow success rate: ${rate}% (${success}/${total})"
        add_result "workflows" "success_rate" "fail" "${rate}%"
        return 1
    fi
}

# Comprehensive checks (optional)
check_network_latency() {
    log_info "Checking network latency to GitHub..."
    
    local latency
    latency=$(curl -o /dev/null -s -w '%{time_total}' https://api.github.com 2>/dev/null || echo "0")
    latency_ms=$(echo "${latency} * 1000" | bc -l | cut -d'.' -f1)
    
    if [[ ${latency_ms} -lt 500 ]]; then
        log_pass "GitHub API latency: ${latency_ms}ms"
        add_result "network" "github_latency" "pass" "${latency_ms}ms"
        return 0
    elif [[ ${latency_ms} -lt 1000 ]]; then
        log_warn "GitHub API latency: ${latency_ms}ms (acceptable)"
        add_result "network" "github_latency" "warn" "${latency_ms}ms"
        return 1
    else
        log_fail "GitHub API latency: ${latency_ms}ms (high)"
        add_result "network" "github_latency" "fail" "${latency_ms}ms"
        return 1
    fi
}

# Output results
output_results() {
    if $JSON_OUTPUT; then
        echo "{"
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"summary\": {"
        echo "    \"passed\": ${CHECKS_PASSED},"
        echo "    \"failed\": ${CHECKS_FAILED},"
        echo "    \"warnings\": ${CHECKS_WARNING},"
        echo "    \"total\": $((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))"
        echo "  },"
        echo "  \"checks\": {"
        
        local first=true
        for key in "${!check_results[@]}"; do
            if ! $first; then echo ","; fi
            first=false
            
            local status=$(echo "${check_results[$key]}" | cut -d'|' -f1)
            local message=$(echo "${check_results[$key]}" | cut -d'|' -f2)
            echo -n "    \"${key}\": {\"status\": \"${status}\", \"message\": \"${message}\"}"
        done
        
        echo ""
        echo "  }"
        echo "}"
    else
        echo ""
        echo "=========================================="
        echo "Health Check Summary"
        echo "=========================================="
        echo "Passed:   ${CHECKS_PASSED}"
        echo "Failed:   ${CHECKS_FAILED}"
        echo "Warnings: ${CHECKS_WARNING}"
        echo "Total:    $((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))"
        echo "=========================================="
        
        if [[ ${CHECKS_FAILED} -eq 0 ]] && [[ ${CHECKS_WARNING} -eq 0 ]]; then
            echo -e "${GREEN}✓ All checks passed${NC}"
            exit 0
        elif [[ ${CHECKS_FAILED} -eq 0 ]]; then
            echo -e "${YELLOW}⚠ Checks passed with warnings${NC}"
            exit 0
        else
            echo -e "${RED}✗ Some checks failed${NC}"
            exit 1
        fi
    fi
}

# Main execution
main() {
    if ! $JSON_OUTPUT; then
        echo "=========================================="
        echo "CI/CD Runner Deployment Health Check"
        echo "=========================================="
        echo "Mode: $(if $COMPREHENSIVE; then echo "Comprehensive"; else echo "Standard"; fi)"
        echo "Started: $(date)"
        echo "=========================================="
        echo ""
    fi
    
    # Core checks (always run)
    check_prometheus || true
    check_grafana || true
    check_loki || true
    check_runners || true
    check_runner_metrics || true
    check_alerts || true
    check_workflow_success_rate || true
    
    # Comprehensive checks (optional)
    if $COMPREHENSIVE; then
        check_network_latency || true
    fi
    
    # Output results
    output_results
}

main
