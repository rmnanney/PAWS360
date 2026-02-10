#!/usr/bin/env bash
# Test Scenario 3.1: Mid-Deployment Interruption Rollback
# JIRA: INFRA-472, INFRA-475 (US3)
#
# Given: Deployment in progress
# When: Simulate interruption (kill runner process, network loss)
# Then: Production automatically rolled back to prior version, no partial state
# Validation: Check production version matches pre-deploy, health checks pass

set -euo pipefail

# Import test utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════"
echo "Test 3.1: Mid-Deployment Interruption Rollback"
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
# Test Step 1: Capture pre-deployment state
# ============================================================================
echo "Step 1: Capturing pre-deployment production state"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would execute: scripts/deployment/capture-production-state.sh"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating pre-deployment state capture..."
  PRE_DEPLOY_VERSION="v1.2.3"
  PRE_DEPLOY_STATE='{"version":"v1.2.3","services":["backend","frontend","database"],"health":"healthy"}'
  echo -e "${GREEN}✓${NC} Pre-deployment state captured (simulated)"
  echo "  Version: $PRE_DEPLOY_VERSION"
else
  # Execute actual state capture
  if [ ! -f "scripts/deployment/capture-production-state.sh" ]; then
    fail_test "State capture script not found: scripts/deployment/capture-production-state.sh"
  else
    if PRE_DEPLOY_STATE=$(bash scripts/deployment/capture-production-state.sh); then
      PRE_DEPLOY_VERSION=$(echo "$PRE_DEPLOY_STATE" | jq -r '.version')
      echo -e "${GREEN}✓${NC} Pre-deployment state captured"
      echo "  Version: $PRE_DEPLOY_VERSION"
    else
      fail_test "Failed to capture pre-deployment state"
    fi
  fi
fi

echo ""

# ============================================================================
# Test Step 2: Start deployment in background
# ============================================================================
echo "Step 2: Starting deployment in background"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would execute: ansible-playbook infrastructure/ansible/playbooks/production-deploy-transactional.yml"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating deployment start..."
  DEPLOY_PID=$$
  echo -e "${GREEN}✓${NC} Deployment started (simulated) - PID: $DEPLOY_PID"
else
  # Execute actual deployment in background
  if [ ! -f "infrastructure/ansible/playbooks/production-deploy-transactional.yml" ]; then
    fail_test "Deployment playbook not found: production-deploy-transactional.yml"
  else
    # Start deployment in background
    ansible-playbook \
      -i "$ANSIBLE_INVENTORY" \
      infrastructure/ansible/playbooks/production-deploy-transactional.yml \
      --extra-vars "target_version=v1.3.0" \
      > /tmp/deploy-test-output.log 2>&1 &
    
    DEPLOY_PID=$!
    echo -e "${GREEN}✓${NC} Deployment started - PID: $DEPLOY_PID"
    
    # Wait for deployment to reach mid-point (5 seconds)
    sleep 5
  fi
fi

echo ""

# ============================================================================
# Test Step 3: Simulate deployment interruption
# ============================================================================
echo "Step 3: Simulating deployment interruption"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would kill deployment process: kill -9 $DEPLOY_PID"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating process kill..."
  echo -e "${GREEN}✓${NC} Deployment interrupted (simulated)"
else
  # Kill deployment process
  if kill -9 "$DEPLOY_PID" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Deployment process killed"
  else
    fail_test "Failed to kill deployment process (PID: $DEPLOY_PID)"
  fi
  
  # Wait for Ansible to detect failure
  sleep 3
fi

echo ""

# ============================================================================
# Test Step 4: Verify automatic rollback triggered
# ============================================================================
echo "Step 4: Verifying automatic rollback triggered"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would check for rollback playbook execution"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating rollback detection..."
  ROLLBACK_TRIGGERED=true
  echo -e "${GREEN}✓${NC} Rollback triggered (simulated)"
else
  # Check deployment log for rollback execution
  if [ -f "/tmp/deploy-test-output.log" ]; then
    if grep -q "RESCUE: Rollback triggered" /tmp/deploy-test-output.log; then
      ROLLBACK_TRIGGERED=true
      echo -e "${GREEN}✓${NC} Rollback triggered by Ansible rescue block"
    else
      fail_test "Rollback not triggered after deployment interruption"
      ROLLBACK_TRIGGERED=false
    fi
  else
    fail_test "Deployment log not found"
    ROLLBACK_TRIGGERED=false
  fi
fi

echo ""

# ============================================================================
# Test Step 5: Verify production version matches pre-deployment
# ============================================================================
echo "Step 5: Verifying production version restored"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query production version from $PRODUCTION_HOST"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating version check..."
  CURRENT_VERSION="v1.2.3"
  
  if [ "$CURRENT_VERSION" = "$PRE_DEPLOY_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Production version matches pre-deployment"
    echo "  Expected: $PRE_DEPLOY_VERSION"
    echo "  Actual:   $CURRENT_VERSION"
  else
    fail_test "Production version mismatch (expected: $PRE_DEPLOY_VERSION, actual: $CURRENT_VERSION)"
  fi
else
  # Query actual production version
  if CURRENT_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/version.txt'); then
    if [ "$CURRENT_VERSION" = "$PRE_DEPLOY_VERSION" ]; then
      echo -e "${GREEN}✓${NC} Production version matches pre-deployment"
      echo "  Expected: $PRE_DEPLOY_VERSION"
      echo "  Actual:   $CURRENT_VERSION"
    else
      fail_test "Production version mismatch (expected: $PRE_DEPLOY_VERSION, actual: $CURRENT_VERSION)"
    fi
  else
    fail_test "Failed to query production version"
  fi
fi

echo ""

# ============================================================================
# Test Step 6: Verify health checks pass
# ============================================================================
echo "Step 6: Verifying production health checks pass"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would run health checks against $PRODUCTION_HOST"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating health checks..."
  HEALTH_STATUS="healthy"
  echo -e "${GREEN}✓${NC} Health checks passed (simulated)"
  echo "  Status: $HEALTH_STATUS"
else
  # Execute actual health checks
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
# Test Step 7: Verify no partial state
# ============================================================================
echo "Step 7: Verifying no partial deployment state"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would check for partial deployment artifacts"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating partial state check..."
  PARTIAL_STATE_FOUND=false
  echo -e "${GREEN}✓${NC} No partial state detected (simulated)"
else
  # Check for partially deployed artifacts
  PARTIAL_STATE_FOUND=false
  
  # Check for mixed version files
  if ssh "$PRODUCTION_HOST" '[ -f /opt/paws360/.deploy-in-progress ]'; then
    fail_test "Deployment lock file still present (partial state)"
    PARTIAL_STATE_FOUND=true
  fi
  
  # Check for temporary deployment files
  if ssh "$PRODUCTION_HOST" 'ls /opt/paws360/*.tmp 2>/dev/null'; then
    fail_test "Temporary deployment files present (partial state)"
    PARTIAL_STATE_FOUND=true
  fi
  
  if [ "$PARTIAL_STATE_FOUND" = "false" ]; then
    echo -e "${GREEN}✓${NC} No partial deployment state detected"
  fi
fi

echo ""

# ============================================================================
# Test Summary
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "Test Summary: Mid-Deployment Interruption Rollback"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$TEST_PASSED" = "true" ]; then
  echo -e "${GREEN}✅ TEST PASSED${NC}"
  echo ""
  echo "All validations passed:"
  echo "  ✓ Pre-deployment state captured"
  echo "  ✓ Deployment interruption simulated"
  echo "  ✓ Automatic rollback triggered"
  echo "  ✓ Production version restored to pre-deployment"
  echo "  ✓ Health checks passed"
  echo "  ✓ No partial deployment state"
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
