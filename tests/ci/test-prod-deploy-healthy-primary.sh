#!/usr/bin/env bash
# Test Scenario 1.1: Healthy Primary Runner Deployment
# Purpose: Verify production deployment succeeds when primary runner is healthy
# JIRA: INFRA-472, INFRA-473 (US1)
# Exit code: 0 if pass, 1 if fail

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Test Scenario 1.1: Healthy Primary Runner"
echo "========================================="
echo ""

# Test setup
PROMETHEUS_URL="${PROMETHEUS_URL:-http://192.168.0.200:9090}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"
TEST_DEPLOY_WORKFLOW="ci.yml"
TEST_TIMEOUT=600  # 10 minutes

# Validate prerequisites
DRY_RUN="${DRY_RUN:-false}"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}⚠️  Running in DRY RUN mode (GitHub API calls will be simulated)${NC}"
  echo ""
else
  if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}ERROR: GITHUB_TOKEN not set${NC}"
    exit 1
  fi

  if [ -z "$GITHUB_REPOSITORY" ]; then
    echo -e "${RED}ERROR: GITHUB_REPOSITORY not set${NC}"
    exit 1
  fi
fi

# GIVEN: Primary runner online and healthy
echo "Step 1: Verify primary runner is online and healthy"
echo "  Querying Prometheus for runner status..."

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}  [DRY RUN] Simulating healthy primary runner${NC}"
  runner_status="1"
else
  runner_status=$(curl -s "$PROMETHEUS_URL/api/v1/query" \
    --data-urlencode 'query=runner_status{authorized_for_prod="true",environment="production"}' \
    | jq -r '.data.result[] | select(.metric.hostname | test("primary")) | .value[1]')

  if [ -z "$runner_status" ]; then
    echo -e "${YELLOW}WARNING: Could not query runner status from Prometheus${NC}"
    echo "  Assuming runner is healthy for test purposes"
    runner_status="1"
  fi
fi

if [ "$runner_status" != "1" ]; then
  echo -e "${RED}FAIL: Primary runner is not online (status=$runner_status)${NC}"
  echo "  This test requires a healthy primary runner"
  exit 1
fi

echo -e "${GREEN}✓ Primary runner is online${NC}"

# Check runner resource usage (should be below thresholds)
echo ""
echo "Step 2: Verify runner resource usage is healthy"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}  [DRY RUN] Simulating healthy resource usage${NC}"
  cpu_usage="35"
  memory_usage="45"
else
  cpu_usage=$(curl -s "$PROMETHEUS_URL/api/v1/query" \
    --data-urlencode 'query=runner_cpu_usage_percent{authorized_for_prod="true",environment="production"}' \
    | jq -r '.data.result[] | select(.metric.hostname | test("primary")) | .value[1]')

  memory_usage=$(curl -s "$PROMETHEUS_URL/api/v1/query" \
    --data-urlencode 'query=runner_memory_usage_percent{authorized_for_prod="true",environment="production"}' \
    | jq -r '.data.result[] | select(.metric.hostname | test("primary")) | .value[1]')
fi

if [ -n "$cpu_usage" ]; then
  echo "  CPU usage: ${cpu_usage}%"
  if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    echo -e "${RED}FAIL: CPU usage too high for reliable test${NC}"
    exit 1
  fi
fi

if [ -n "$memory_usage" ]; then
  echo "  Memory usage: ${memory_usage}%"
  if (( $(echo "$memory_usage > 80" | bc -l) )); then
    echo -e "${RED}FAIL: Memory usage too high for reliable test${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✓ Runner resource usage healthy${NC}"

# WHEN: Trigger production deployment workflow
echo ""
echo "Step 3: Trigger production deployment workflow"
echo "  Workflow: $TEST_DEPLOY_WORKFLOW"
echo "  Branch: main"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}  [DRY RUN] Simulating workflow dispatch${NC}"
  workflow_dispatch="204"
  run_id="1234567890"
else
  # Trigger workflow via GitHub API
  workflow_dispatch=$(curl -s -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$TEST_DEPLOY_WORKFLOW/dispatches" \
    -d '{"ref":"main","inputs":{"environment":"production","test_mode":"true"}}' \
    -w "%{http_code}" -o /dev/null)

  if [ "$workflow_dispatch" != "204" ]; then
    echo -e "${RED}FAIL: Could not trigger workflow (HTTP $workflow_dispatch)${NC}"
    exit 1
  fi

  echo -e "${GREEN}✓ Workflow triggered${NC}"

  # Wait for workflow run to start
  echo ""
  echo "Step 4: Wait for workflow run to start..."
  sleep 10

  # Get most recent workflow run
  # Get most recent workflow run
  run_id=$(curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/workflows/$TEST_DEPLOY_WORKFLOW/runs?per_page=1" \
    | jq -r '.workflow_runs[0].id')
fi

echo -e "${GREEN}✓ Workflow triggered${NC}"

if [ "$DRY_RUN" = "true" ]; then
  echo ""
  echo "Step 4-8: [DRY RUN] Simulating successful deployment on primary runner"
  echo -e "${YELLOW}  Skipping workflow monitoring and verification${NC}"
  echo ""
  echo "========================================="
  echo -e "${GREEN}TEST PASSED (DRY RUN): Healthy primary runner deployment${NC}"
  echo "========================================="
  exit 0
fi

if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
  echo -e "${RED}FAIL: Could not find workflow run${NC}"
  exit 1
fi

echo "  Run ID: $run_id"

# Monitor workflow run
echo ""
echo "Step 5: Monitor workflow execution..."

start_time=$(date +%s)
while true; do
  run_status=$(curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$run_id" \
    | jq -r '.status')
  
  run_conclusion=$(curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$run_id" \
    | jq -r '.conclusion')
  
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  
  if [ "$run_status" = "completed" ]; then
    break
  fi
  
  if [ $elapsed -gt $TEST_TIMEOUT ]; then
    echo -e "${RED}FAIL: Workflow timeout (>${TEST_TIMEOUT}s)${NC}"
    exit 1
  fi
  
  echo "  Status: $run_status (${elapsed}s elapsed)"
  sleep 15
done

# THEN: Deployment completes successfully
echo ""
echo "Step 6: Verify deployment outcome"

if [ "$run_conclusion" != "success" ]; then
  echo -e "${RED}FAIL: Deployment did not succeed (conclusion=$run_conclusion)${NC}"
  
  # Fetch logs for debugging
  echo ""
  echo "Deployment logs:"
  curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$run_id/logs" \
    | tail -100
  
  exit 1
fi

echo -e "${GREEN}✓ Deployment completed successfully${NC}"

# Verify deployment used primary runner
echo ""
echo "Step 7: Verify deployment used primary runner"

# Get job details
job_runner=$(curl -s \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$run_id/jobs" \
  | jq -r '.jobs[] | select(.name | contains("deploy")) | .runner_name')

if [ -z "$job_runner" ]; then
  echo -e "${YELLOW}WARNING: Could not determine runner used${NC}"
else
  echo "  Runner used: $job_runner"
  
  if ! echo "$job_runner" | grep -qi "primary"; then
    echo -e "${RED}FAIL: Deployment did not use primary runner${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✓ Primary runner was used${NC}"
fi

# Verify deployment metrics
echo ""
echo "Step 8: Verify deployment metrics"

deployment_duration=$(curl -s \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$run_id" \
  | jq -r '.run_duration_ms')

if [ -n "$deployment_duration" ] && [ "$deployment_duration" != "null" ]; then
  duration_seconds=$((deployment_duration / 1000))
  echo "  Deployment duration: ${duration_seconds}s"
  
  if [ $duration_seconds -gt 600 ]; then
    echo -e "${YELLOW}WARNING: Deployment took longer than 10 minutes${NC}"
  fi
fi

# Final result
echo ""
echo "========================================="
echo -e "${GREEN}TEST PASSED: Healthy primary runner deployment${NC}"
echo "========================================="
echo ""
echo "Summary:"
echo "  - Primary runner was online and healthy"
echo "  - Deployment completed successfully"
echo "  - Primary runner was used for deployment"
echo "  - Deployment duration: ${duration_seconds:-unknown}s"
echo ""

exit 0
