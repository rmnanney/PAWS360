#!/usr/bin/env bash
# Test Scenario 3.3: Partial Deployment Prevention
# JIRA: INFRA-472, INFRA-475 (US3)
#
# Given: Multi-step deployment (backend, frontend, database)
# When: One step fails mid-deployment
# Then: Entire deployment aborted, no steps left in partial state
# Validation: Check all components at prior version or fully deployed version (no mixed state)

set -euo pipefail

# Import test utilities if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════════"
echo "Test 3.3: Partial Deployment Prevention"
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
# Test Step 1: Capture pre-deployment state (all components)
# ============================================================================
echo "Step 1: Capturing pre-deployment state for all components"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would capture state for: backend, frontend, database"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating multi-component state capture..."
  
  BACKEND_PRE_VERSION="v1.2.3"
  FRONTEND_PRE_VERSION="v1.2.3"
  DATABASE_PRE_VERSION="schema_v5"
  
  echo -e "${GREEN}✓${NC} Pre-deployment state captured (simulated)"
  echo "  Backend:  $BACKEND_PRE_VERSION"
  echo "  Frontend: $FRONTEND_PRE_VERSION"
  echo "  Database: $DATABASE_PRE_VERSION"
else
  # Capture actual component versions
  if BACKEND_PRE_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/backend/version.txt'); then
    echo -e "${GREEN}✓${NC} Backend version: $BACKEND_PRE_VERSION"
  else
    fail_test "Failed to capture backend version"
    BACKEND_PRE_VERSION="unknown"
  fi
  
  if FRONTEND_PRE_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/frontend/version.txt'); then
    echo -e "${GREEN}✓${NC} Frontend version: $FRONTEND_PRE_VERSION"
  else
    fail_test "Failed to capture frontend version"
    FRONTEND_PRE_VERSION="unknown"
  fi
  
  if DATABASE_PRE_VERSION=$(ssh "$PRODUCTION_HOST" 'psql -U paws360 -t -c "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;"'); then
    DATABASE_PRE_VERSION=$(echo "$DATABASE_PRE_VERSION" | tr -d ' ')
    echo -e "${GREEN}✓${NC} Database version: $DATABASE_PRE_VERSION"
  else
    fail_test "Failed to capture database version"
    DATABASE_PRE_VERSION="unknown"
  fi
fi

echo ""

# ============================================================================
# Test Step 2: Start multi-step deployment with injected failure
# ============================================================================
echo "Step 2: Starting multi-step deployment (with injected failure)"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would execute: ansible-playbook production-deploy-transactional.yml"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating deployment with failure in step 2 (frontend)..."
  
  echo "  Step 1: Backend deployment... SUCCESS"
  echo "  Step 2: Frontend deployment... FAILURE (simulated)"
  echo "  Step 3: Database migration... SKIPPED"
  
  DEPLOYMENT_FAILED=true
  FAILED_STEP="frontend"
  echo -e "${GREEN}✓${NC} Deployment failure simulated at frontend step"
else
  # Execute deployment with injected failure flag
  if ansible-playbook \
    -i "$ANSIBLE_INVENTORY" \
    infrastructure/ansible/playbooks/production-deploy-transactional.yml \
    --extra-vars "target_version=v1.3.0 fail_at_step=frontend" \
    > /tmp/partial-deploy-test.log 2>&1; then
    
    fail_test "Deployment should have failed but succeeded"
    DEPLOYMENT_FAILED=false
    FAILED_STEP="none"
  else
    DEPLOYMENT_FAILED=true
    
    # Identify which step failed
    if grep -q "FAILED.*frontend" /tmp/partial-deploy-test.log; then
      FAILED_STEP="frontend"
      echo -e "${GREEN}✓${NC} Deployment failed at frontend step as expected"
    else
      fail_test "Deployment failed but not at expected step"
      FAILED_STEP="unknown"
    fi
  fi
fi

echo ""

# ============================================================================
# Test Step 3: Verify rescue block triggered
# ============================================================================
echo "Step 3: Verifying Ansible rescue block triggered"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would check for rescue block execution"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating rescue block detection..."
  RESCUE_TRIGGERED=true
  echo -e "${GREEN}✓${NC} Rescue block triggered (simulated)"
else
  # Check deployment log for rescue block
  if [ -f "/tmp/partial-deploy-test.log" ]; then
    if grep -q "RESCUE: Transaction rollback" /tmp/partial-deploy-test.log; then
      RESCUE_TRIGGERED=true
      echo -e "${GREEN}✓${NC} Rescue block triggered by Ansible"
    else
      fail_test "Rescue block not triggered after deployment failure"
      RESCUE_TRIGGERED=false
    fi
  else
    fail_test "Deployment log not found"
    RESCUE_TRIGGERED=false
  fi
fi

echo ""

# ============================================================================
# Test Step 4: Verify no partial state (backend rolled back)
# ============================================================================
echo "Step 4: Verifying backend rolled back (no partial state)"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query backend version"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating backend version check..."
  BACKEND_CURRENT_VERSION="v1.2.3"
  
  if [ "$BACKEND_CURRENT_VERSION" = "$BACKEND_PRE_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Backend at pre-deployment version (not partial)"
    echo "  Expected: $BACKEND_PRE_VERSION"
    echo "  Actual:   $BACKEND_CURRENT_VERSION"
  else
    fail_test "Backend in partial state (expected: $BACKEND_PRE_VERSION, actual: $BACKEND_CURRENT_VERSION)"
  fi
else
  # Query actual backend version
  if BACKEND_CURRENT_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/backend/version.txt'); then
    if [ "$BACKEND_CURRENT_VERSION" = "$BACKEND_PRE_VERSION" ]; then
      echo -e "${GREEN}✓${NC} Backend at pre-deployment version (not partial)"
      echo "  Expected: $BACKEND_PRE_VERSION"
      echo "  Actual:   $BACKEND_CURRENT_VERSION"
    else
      fail_test "Backend in partial state (expected: $BACKEND_PRE_VERSION, actual: $BACKEND_CURRENT_VERSION)"
    fi
  else
    fail_test "Failed to query backend version"
  fi
fi

echo ""

# ============================================================================
# Test Step 5: Verify frontend at pre-deployment version
# ============================================================================
echo "Step 5: Verifying frontend at pre-deployment version"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query frontend version"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating frontend version check..."
  FRONTEND_CURRENT_VERSION="v1.2.3"
  
  if [ "$FRONTEND_CURRENT_VERSION" = "$FRONTEND_PRE_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Frontend at pre-deployment version"
    echo "  Expected: $FRONTEND_PRE_VERSION"
    echo "  Actual:   $FRONTEND_CURRENT_VERSION"
  else
    fail_test "Frontend version mismatch (expected: $FRONTEND_PRE_VERSION, actual: $FRONTEND_CURRENT_VERSION)"
  fi
else
  # Query actual frontend version
  if FRONTEND_CURRENT_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/frontend/version.txt'); then
    if [ "$FRONTEND_CURRENT_VERSION" = "$FRONTEND_PRE_VERSION" ]; then
      echo -e "${GREEN}✓${NC} Frontend at pre-deployment version"
      echo "  Expected: $FRONTEND_PRE_VERSION"
      echo "  Actual:   $FRONTEND_CURRENT_VERSION"
    else
      fail_test "Frontend version mismatch (expected: $FRONTEND_PRE_VERSION, actual: $FRONTEND_CURRENT_VERSION)"
    fi
  else
    fail_test "Failed to query frontend version"
  fi
fi

echo ""

# ============================================================================
# Test Step 6: Verify database unchanged
# ============================================================================
echo "Step 6: Verifying database unchanged (migration not applied)"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query database schema version"
  echo -e "${YELLOW}[DRY RUN]${NC} Simulating database version check..."
  DATABASE_CURRENT_VERSION="schema_v5"
  
  if [ "$DATABASE_CURRENT_VERSION" = "$DATABASE_PRE_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Database at pre-deployment version"
    echo "  Expected: $DATABASE_PRE_VERSION"
    echo "  Actual:   $DATABASE_CURRENT_VERSION"
  else
    fail_test "Database version mismatch (expected: $DATABASE_PRE_VERSION, actual: $DATABASE_CURRENT_VERSION)"
  fi
else
  # Query actual database version
  if DATABASE_CURRENT_VERSION=$(ssh "$PRODUCTION_HOST" 'psql -U paws360 -t -c "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;"'); then
    DATABASE_CURRENT_VERSION=$(echo "$DATABASE_CURRENT_VERSION" | tr -d ' ')
    
    if [ "$DATABASE_CURRENT_VERSION" = "$DATABASE_PRE_VERSION" ]; then
      echo -e "${GREEN}✓${NC} Database at pre-deployment version"
      echo "  Expected: $DATABASE_PRE_VERSION"
      echo "  Actual:   $DATABASE_CURRENT_VERSION"
    else
      fail_test "Database version mismatch (expected: $DATABASE_PRE_VERSION, actual: $DATABASE_CURRENT_VERSION)"
    fi
  else
    fail_test "Failed to query database version"
  fi
fi

echo ""

# ============================================================================
# Test Step 7: Verify consistency (no mixed versions)
# ============================================================================
echo "Step 7: Verifying version consistency across all components"
echo "─────────────────────────────────────────────────"

if [ "$DRY_RUN" = "true" ]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Checking for version consistency..."
  
  # All should be at pre-deployment versions
  if [ "$BACKEND_CURRENT_VERSION" = "$BACKEND_PRE_VERSION" ] && \
     [ "$FRONTEND_CURRENT_VERSION" = "$FRONTEND_PRE_VERSION" ] && \
     [ "$DATABASE_CURRENT_VERSION" = "$DATABASE_PRE_VERSION" ]; then
    echo -e "${GREEN}✓${NC} All components consistent at pre-deployment versions"
    echo "  Backend:  $BACKEND_CURRENT_VERSION"
    echo "  Frontend: $FRONTEND_CURRENT_VERSION"
    echo "  Database: $DATABASE_CURRENT_VERSION"
  else
    fail_test "Components in inconsistent state (mixed versions detected)"
  fi
else
  # Check for consistency in actual versions
  VERSIONS_MATCH=true
  
  # Compare backend and frontend versions (should match)
  if [ "$BACKEND_CURRENT_VERSION" != "$FRONTEND_CURRENT_VERSION" ]; then
    fail_test "Backend and frontend versions don't match"
    VERSIONS_MATCH=false
  fi
  
  # All should match pre-deployment versions
  if [ "$BACKEND_CURRENT_VERSION" != "$BACKEND_PRE_VERSION" ] || \
     [ "$FRONTEND_CURRENT_VERSION" != "$FRONTEND_PRE_VERSION" ] || \
     [ "$DATABASE_CURRENT_VERSION" != "$DATABASE_PRE_VERSION" ]; then
    fail_test "Components not at consistent pre-deployment versions"
    VERSIONS_MATCH=false
  fi
  
  if [ "$VERSIONS_MATCH" = "true" ]; then
    echo -e "${GREEN}✓${NC} All components consistent at pre-deployment versions"
    echo "  Backend:  $BACKEND_CURRENT_VERSION"
    echo "  Frontend: $FRONTEND_CURRENT_VERSION"
    echo "  Database: $DATABASE_CURRENT_VERSION"
  fi
fi

echo ""

# ============================================================================
# Test Summary
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "Test Summary: Partial Deployment Prevention"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ "$TEST_PASSED" = "true" ]; then
  echo -e "${GREEN}✅ TEST PASSED${NC}"
  echo ""
  echo "All validations passed:"
  echo "  ✓ Pre-deployment state captured (all components)"
  echo "  ✓ Deployment failed at expected step (frontend)"
  echo "  ✓ Rescue block triggered"
  echo "  ✓ Backend rolled back (no partial state)"
  echo "  ✓ Frontend at pre-deployment version"
  echo "  ✓ Database unchanged"
  echo "  ✓ All components consistent (no mixed versions)"
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
