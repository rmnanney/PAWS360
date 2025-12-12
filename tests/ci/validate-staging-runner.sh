#!/usr/bin/env bash
# Staging Runner Validation Script
# Purpose: Validate staging runner provisioning and monitoring (T042)
# JIRA: INFRA-472, INFRA-473 (US1)
# Exit code: 0 if pass, 1 if fail

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}T042: Staging Runner Validation${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Configuration
PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://192.168.0.200:3000}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-rmnanney/PAWS360}"
STAGING_RUNNER="dell-r640-01-runner"
RUNNER_HOST="192.168.0.51"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to check test result
check_result() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗ FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Verify runner is registered in GitHub
echo -e "${BLUE}Test 1: Verify runner registration in GitHub${NC}"
echo "  Checking GitHub Actions settings..."

if [ -n "${GITHUB_TOKEN:-}" ]; then
  runner_list=$(gh api /repos/$GITHUB_REPOSITORY/actions/runners 2>&1 | jq -r '.runners[] | select(.name=="'$STAGING_RUNNER'") | .name')
  if [ "$runner_list" = "$STAGING_RUNNER" ]; then
    echo "  Runner found: $STAGING_RUNNER"
    runner_status=$(gh api /repos/$GITHUB_REPOSITORY/actions/runners | jq -r '.runners[] | select(.name=="'$STAGING_RUNNER'") | .status')
    echo "  Status: $runner_status"
    [ "$runner_status" = "online" ]
    check_result
  else
    echo -e "${RED}  Runner not found in GitHub${NC}"
    check_result
  fi
else
  echo -e "${YELLOW}  Skipping: GITHUB_TOKEN not set${NC}"
  echo "  Manual verification required"
fi

# Test 2: Verify runner service is active
echo ""
echo -e "${BLUE}Test 2: Verify runner service is active on host${NC}"
echo "  Checking systemd service status..."

service_status=$(ssh ryan@$RUNNER_HOST "systemctl is-active actions.runner.*.service" 2>&1 || echo "inactive")
echo "  Service status: $service_status"
[ "$service_status" = "active" ]
check_result

# Test 3: Verify Prometheus is scraping runner metrics
echo ""
echo -e "${BLUE}Test 3: Verify Prometheus scraping runner metrics${NC}"
echo "  Querying Prometheus for runner_status..."

runner_status_metric=$(curl -s "$PROMETHEUS_URL/api/v1/query" \
  --data-urlencode 'query=runner_status{runner_name="'$STAGING_RUNNER'"}' \
  | jq -r '.data.result[0].value[1]')

echo "  runner_status metric value: $runner_status_metric"
[ "$runner_status_metric" = "1" ]
check_result

# Test 4: Verify all runner metrics are being collected
echo ""
echo -e "${BLUE}Test 4: Verify all runner metrics collection${NC}"
echo "  Checking for required metrics..."

metrics=(
  "runner_status"
  "runner_cpu_usage_percent"
  "runner_memory_usage_percent"
  "runner_disk_usage_percent"
)

all_metrics_ok=true
for metric in "${metrics[@]}"; do
  metric_value=$(curl -s "$PROMETHEUS_URL/api/v1/query" \
    --data-urlencode "query=${metric}{runner_name=\"$STAGING_RUNNER\"}" \
    | jq -r '.data.result[0].value[1]')
  
  if [ -n "$metric_value" ] && [ "$metric_value" != "null" ]; then
    echo -e "  ${GREEN}✓${NC} $metric: $metric_value"
  else
    echo -e "  ${RED}✗${NC} $metric: not found"
    all_metrics_ok=false
  fi
done

[ "$all_metrics_ok" = true ]
check_result

# Test 5: Verify Grafana dashboard is accessible
echo ""
echo -e "${BLUE}Test 5: Verify Grafana dashboard deployment${NC}"
echo "  Checking dashboard accessibility..."

dashboard_check=$(curl -s -u admin:admin "$GRAFANA_URL/api/dashboards/uid/github-runner-health" \
  | jq -r '.dashboard.title')

echo "  Dashboard title: $dashboard_check"
[ "$dashboard_check" = "GitHub Runner Health Dashboard" ]
check_result

# Test 6: Verify Prometheus alert rules are loaded
echo ""
echo -e "${BLUE}Test 6: Verify Prometheus alert rules loaded${NC}"
echo "  Checking for github_runner_health alert group..."

alert_rules=$(curl -s "$PROMETHEUS_URL/api/v1/rules" \
  | jq -r '.data.groups[] | select(.name=="github_runner_health") | .rules | length')

echo "  Alert rules in group: $alert_rules"
[ "$alert_rules" -ge "4" ]
check_result

# Test 7: Verify runner-exporter is accessible
echo ""
echo -e "${BLUE}Test 7: Verify runner-exporter endpoint${NC}"
echo "  Testing runner-exporter metrics endpoint..."

exporter_health=$(ssh ryan@$RUNNER_HOST "curl -s http://localhost:9101/health")
echo "  Health endpoint response: $exporter_health"
[ "$exporter_health" = "OK" ]
check_result

# Test 8: Verify firewall rule allows Prometheus access
echo ""
echo -e "${BLUE}Test 8: Verify firewall configuration${NC}"
echo "  Checking UFW rules for port 9101..."

ufw_rule=$(ssh ryan@$RUNNER_HOST "sudo ufw status | grep '9101.*192.168.0.200'" || echo "")
if [ -n "$ufw_rule" ]; then
  echo "  Firewall rule found: $ufw_rule"
  echo -e "${GREEN}✓ PASS${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}  Firewall rule not found${NC}"
  echo -e "${RED}✗ FAIL${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 9: Simulate alert firing (optional - requires manual cleanup)
echo ""
echo -e "${BLUE}Test 9: Test alert functionality (optional)${NC}"
echo "  This test would stop the runner service and verify alert fires"
echo "  Skipping automated test to avoid disruption"
echo -e "${YELLOW}  Manual verification: Stop runner, wait 5min, check Prometheus alerts${NC}"

# Test 10: Verify runner can execute jobs (optional - requires workflow trigger)
echo ""
echo -e "${BLUE}Test 10: Verify runner can execute jobs (manual)${NC}"
if [ -n "${GITHUB_TOKEN:-}" ]; then
  echo "  To test job execution, trigger a workflow manually:"
  echo "  gh workflow run ci.yml --ref 001-github-runner-deploy"
  echo ""
  echo "  Then verify the job runs on $STAGING_RUNNER"
else
  echo -e "${YELLOW}  Skipping: GITHUB_TOKEN not set${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Tests executed: $((TESTS_PASSED + TESTS_FAILED))"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ Staging runner validation PASSED${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Proceed with T042a: Provision production-runner-01"
  echo "  2. Deploy monitoring to production runners (T042c)"
  echo "  3. Execute production validation (T042d)"
  exit 0
else
  echo -e "${RED}❌ Staging runner validation FAILED${NC}"
  echo ""
  echo "Please fix the failing tests before proceeding to production provisioning"
  exit 1
fi
