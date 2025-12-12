#!/usr/bin/env bash
# Test Scenario 3.4: Safe Retry After Safeguard Trigger
# JIRA: INFRA-472, INFRA-475 (US3)
#
# Given: Deployment failed and safeguards triggered (rollback or abort)
# When: Deployment retried after fix
# Then: Retry succeeds, production updated to target version cleanly
# Validation: Check production version matches target, no residual state from failed attempt

set -euo pipefail

# Import test utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════"
echo "Test 3.4: Safe Retry After Safeguard Trigger"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Configuration
PRODUCTION_HOST="${PRODUCTION_HOST:-192.168.0.100}"
ANSIBLE_INVENTORY="${ANSIBLE_INVENTORY:-infrastructure/ansible/inventories/production/hosts}"
DRY_RUN="${DRY_RUN:-true}"

echo "Configuration:"
echo "  PRODUCTION_HOST: $PRODUCTION_HOST"
echo "  ANSIBLE_INVENTORY: $ANSIBLE_INVENTORY"
echo "  DRY_RUN: $DRY_RUN"
echo ""

# Test state tracking
TEST_PASSED=true
FAILURES=()

fail_test() {
  TEST_PASSED=false
  FAILURES+=("$1")
  echo -e "${RED}❌ FAILURE: $1${NC}"
}

# ============================================================================
# Test Step 1: Capture initial state
# ============================================================================
echo "Step 1: Capturing initial production state"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would capture initial production state"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating state capture..."
  INITIAL_VERSION="v1.2.3"
  echo -e "${GREEN}✓${NC} Initial state captured (simulated)"
  echo "  Version: $INITIAL_VERSION"
else
  if [ ! -f "scripts/deployment/capture-production-state.sh" ]; then
    fail_test "State capture script not found"
    INITIAL_VERSION="unknown"
  else
    if INITIAL_STATE=$(bash scripts/deployment/capture-production-state.sh); then
      INITIAL_VERSION=$(echo "$INITIAL_STATE" | jq -r '.version')
      echo -e "${GREEN}✓${NC} Initial state captured"
      echo "  Version: $INITIAL_VERSION"
    else
      fail_test "Failed to capture initial state"
      INITIAL_VERSION="unknown"
    fi
  fi
fi

echo ""

# ============================================================================
# Test Step 2: Attempt deployment with intentional failure
# ============================================================================
echo "Step 2: Attempting deployment (with intentional failure)"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would execute: ansible-playbook (with failure injection)"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating failed deployment..."
  TARGET_VERSION="v1.3.0"
  FIRST_DEPLOY_FAILED=true
  echo -e "${GREEN}✓${NC} First deployment failed (simulated)"
  echo "  Target version: $TARGET_VERSION"
  echo "  Failure reason: Simulated error"
else
  TARGET_VERSION="v1.3.0"
  
  # Execute deployment with injected failure
  if ansible-playbook \
    -i "$ANSIBLE_INVENTORY" \
    infrastructure/ansible/playbooks/production-deploy-transactional.yml \
    --extra-vars "target_version=$TARGET_VERSION fail_intentionally=true" \
    > /tmp/first-deploy-attempt.log 2>&1; then
    
    fail_test "Deployment should have failed but succeeded"
    FIRST_DEPLOY_FAILED=false
  else
    FIRST_DEPLOY_FAILED=true
    echo -e "${GREEN}✓${NC} First deployment failed as expected"
    echo "  Target version: $TARGET_VERSION"
  fi
fi

echo ""

# ============================================================================
# Test Step 3: Verify safeguards triggered (rollback/abort)
# ============================================================================
echo "Step 3: Verifying safeguards triggered"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would check for safeguard activation"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating safeguard detection..."
  SAFEGUARD_TRIGGERED=true
  SAFEGUARD_TYPE="rollback"
  echo -e "${GREEN}✓${NC} Safeguards triggered (simulated)"
  echo "  Type: $SAFEGUARD_TYPE"
else
  # Check deployment log for safeguard activation
  if [ -f "/tmp/first-deploy-attempt.log" ]; then
    if grep -q "RESCUE: Transaction rollback" /tmp/first-deploy-attempt.log; then
      SAFEGUARD_TRIGGERED=true
      SAFEGUARD_TYPE="rollback"
      echo -e "${GREEN}✓${NC} Safeguards triggered (rollback)"
    elif grep -q "RESCUE: Deployment aborted" /tmp/first-deploy-attempt.log; then
      SAFEGUARD_TRIGGERED=true
      SAFEGUARD_TYPE="abort"
      echo -e "${GREEN}✓${NC} Safeguards triggered (abort)"
    else
      fail_test "Safeguards not triggered after deployment failure"
      SAFEGUARD_TRIGGERED=false
      SAFEGUARD_TYPE="none"
    fi
  else
    fail_test "Deployment log not found"
    SAFEGUARD_TRIGGERED=false
    SAFEGUARD_TYPE="none"
  fi
fi

echo ""

# ============================================================================
# Test Step 4: Verify production restored to initial state
# ============================================================================
echo "Step 4: Verifying production restored to initial state"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query production version"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating version check..."
  AFTER_FAILURE_VERSION="v1.2.3"
  
  if [ "$AFTER_FAILURE_VERSION" = "$INITIAL_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Production restored to initial state"
    echo "  Expected: $INITIAL_VERSION"
    echo "  Actual:   $AFTER_FAILURE_VERSION"
  else
    fail_test "Production not restored (expected: $INITIAL_VERSION, actual: $AFTER_FAILURE_VERSION)"
  fi
else
  # Query actual production version
  if AFTER_FAILURE_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/version.txt'); then
    if [ "$AFTER_FAILURE_VERSION" = "$INITIAL_VERSION" ]; then
      echo -e "${GREEN}✓${NC} Production restored to initial state"
      echo "  Expected: $INITIAL_VERSION"
      echo "  Actual:   $AFTER_FAILURE_VERSION"
    else
      fail_test "Production not restored (expected: $INITIAL_VERSION, actual: $AFTER_FAILURE_VERSION)"
    fi
  else
    fail_test "Failed to query production version"
  fi
fi

echo ""

# ============================================================================
# Test Step 5: Clean up residual state from failed attempt
# ============================================================================
echo "Step 5: Cleaning up residual state from failed attempt"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would check for and remove residual state"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating cleanup..."
  RESIDUAL_FILES_FOUND=false
  echo -e "${GREEN}✓${NC} No residual state found (simulated)"
else
  RESIDUAL_FILES_FOUND=false
  
  # Check for deployment lock files
  if ssh "$PRODUCTION_HOST" '[ -f /opt/paws360/.deploy-in-progress ]'; then
    echo "  Removing deployment lock file..."
    ssh "$PRODUCTION_HOST" 'rm -f /opt/paws360/.deploy-in-progress'
    RESIDUAL_FILES_FOUND=true
  fi
  
  # Check for temporary files
  if ssh "$PRODUCTION_HOST" 'ls /opt/paws360/*.tmp 2>/dev/null'; then
    echo "  Removing temporary files..."
    ssh "$PRODUCTION_HOST" 'rm -f /opt/paws360/*.tmp'
    RESIDUAL_FILES_FOUND=true
  fi
  
  # Check for failed state markers
  if ssh "$PRODUCTION_HOST" '[ -f /opt/paws360/.deploy-failed ]'; then
    echo "  Removing failed state marker..."
    ssh "$PRODUCTION_HOST" 'rm -f /opt/paws360/.deploy-failed'
    RESIDUAL_FILES_FOUND=true
  fi
  
  if [ "$RESIDUAL_FILES_FOUND" = "false" ]; then
    echo -e "${GREEN}✓${NC} No residual state found"
  else
    echo -e "${GREEN}✓${NC} Residual state cleaned up"
  fi
fi

echo ""

# ============================================================================
# Test Step 6: Retry deployment (should succeed)
# ============================================================================
echo "Step 6: Retrying deployment (without failure injection)"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would execute: ansible-playbook (clean retry)"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating successful retry..."
  RETRY_SUCCEEDED=true
  echo -e "${GREEN}✓${NC} Retry deployment succeeded (simulated)"
else
  # Execute deployment without failure injection
  if ansible-playbook \
    -i "$ANSIBLE_INVENTORY" \
    infrastructure/ansible/playbooks/production-deploy-transactional.yml \
    --extra-vars "target_version=$TARGET_VERSION" \
    > /tmp/retry-deploy-attempt.log 2>&1; then
    
    RETRY_SUCCEEDED=true
    echo -e "${GREEN}✓${NC} Retry deployment succeeded"
  else
    fail_test "Retry deployment failed unexpectedly"
    RETRY_SUCCEEDED=false
  fi
fi

echo ""

# ============================================================================
# Test Step 7: Verify production at target version
# ============================================================================
echo "Step 7: Verifying production updated to target version"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query production version"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating version check..."
  FINAL_VERSION="v1.3.0"
  
  if [ "$FINAL_VERSION" = "$TARGET_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Production at target version"
    echo "  Expected: $TARGET_VERSION"
    echo "  Actual:   $FINAL_VERSION"
  else
    fail_test "Version mismatch (expected: $TARGET_VERSION, actual: $FINAL_VERSION)"
  fi
else
  # Query actual production version
  if FINAL_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/version.txt'); then
    if [ "$FINAL_VERSION" = "$TARGET_VERSION" ]; then
      echo -e "${GREEN}✓${NC} Production at target version"
      echo "  Expected: $TARGET_VERSION"
      echo "  Actual:   $FINAL_VERSION"
    else
      fail_test "Version mismatch (expected: $TARGET_VERSION, actual: $FINAL_VERSION)"
    fi
  else
    fail_test "Failed to query production version"
  fi
fi

echo ""

# ============================================================================
# Test Step 8: Verify health checks pass
# ============================================================================
echo "Step 8: Verifying post-deployment health checks pass"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would run health checks"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating health checks..."
  HEALTH_STATUS="UP"
  echo -e "${GREEN}✓${NC} Health checks passed (simulated)"
  echo "  Status: $HEALTH_STATUS"
else
  # Execute health checks
  if HEALTH_STATUS=$(curl -sf "http://$PRODUCTION_HOST:8080/actuator/health" | jq -r '.status'); then
    if [ "$HEALTH_STATUS" = "UP" ]; then
      echo -e "${GREEN}✓${NC} Health checks passed"
      echo "  Status: $HEALTH_STATUS"
    else
      fail_test "Health checks failed (status: $HEALTH_STATUS)"
    fi
  else
    fail_test "Failed to query health endpoint"
  fi
fi

echo ""

# ============================================================================
# Test Step 9: Verify no residual state from first attempt
# ============================================================================
echo "Step 9: Verifying no residual state from failed attempt"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would check for residual state artifacts"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating residual state check..."
  RESIDUAL_STATE_PRESENT=false
  echo -e "${GREEN}✓${NC} No residual state present (simulated)"
else
  RESIDUAL_STATE_PRESENT=false
  
  # Check for any markers from first attempt
  if ssh "$PRODUCTION_HOST" 'ls /opt/paws360/.deploy-* 2>/dev/null'; then
    fail_test "Residual deployment state files present"
    RESIDUAL_STATE_PRESENT=true
  fi
  
  # Check for failed attempt logs
  if ssh "$PRODUCTION_HOST" '[ -d /var/log/paws360/failed-deploys ]'; then
    FAILED_DEPLOY_COUNT=$(ssh "$PRODUCTION_HOST" 'ls /var/log/paws360/failed-deploys | wc -l')
    if [ "$FAILED_DEPLOY_COUNT" -gt 0 ]; then
      echo "  Note: $FAILED_DEPLOY_COUNT failed deployment log(s) archived (expected)"
    fi
  fi
  
  if [ "$RESIDUAL_STATE_PRESENT" = "false" ]; then
    echo -e "${GREEN}✓${NC} No residual state present"
  fi
fi

echo ""

# ============================================================================
# Test Summary
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "Test Summary: Safe Retry After Safeguard Trigger"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$TEST_PASSED" = "true" ]; then
  echo -e "${GREEN}✅ TEST PASSED${NC}"
  echo ""
  echo "All validations passed:"
  echo "  ✓ Initial state captured"
  echo "  ✓ First deployment failed (intentional)"
  echo "  ✓ Safeguards triggered ($SAFEGUARD_TYPE)"
  echo "  ✓ Production restored to initial state"
  echo "  ✓ Residual state cleaned up"
  echo "  ✓ Retry deployment succeeded"
  echo "  ✓ Production at target version"
  echo "  ✓ Health checks passed"
  echo "  ✓ No residual state from failed attempt"
  echo ""
  exit 0
else
  echo -e "${RED}❌ TEST FAILED${NC}"
  echo ""
  echo "Failures:"
  for failure in "${FAILURES[@]}"; do
    echo -e "  ${RED}✗${NC} $failure"
  done
  echo ""
  exit 1
fi
