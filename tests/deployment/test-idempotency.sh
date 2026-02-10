#!/usr/bin/env bash
#
# Deployment Idempotency Tests
# Validates that deployments are idempotent and can be safely re-run
#
# Usage:
#   ./test-idempotency.sh [--environment ENV] [--test-version VERSION]
#
# Options:
#   --environment ENV      Target environment (staging|production) (default: staging)
#   --test-version VERSION Version to use for testing (default: current+test suffix)
#   --dry-run              Simulate test execution without actual deploys
#
# Exit Codes:
#   0 - All idempotency tests passed
#   1 - One or more tests failed
#
# Constitutional Compliance:
#   - Article X: Truth & Partnership - accurate test validation
#   - Article VIIa: Monitoring Discovery - test results logged
#
# JIRA: INFRA-475 (User Story 3 - Protect production during deploy anomalies)
# Task: T076 - Add deployment idempotency tests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${ENVIRONMENT:-staging}"
TEST_VERSION="${TEST_VERSION:-v1.0.0-idempotency-test}"
DRY_RUN="${DRY_RUN:-false}"
ANSIBLE_INVENTORY="infrastructure/ansible/inventories/${ENVIRONMENT}/hosts"
DEPLOY_PLAYBOOK="infrastructure/ansible/playbooks/production-deploy-transactional.yml"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            ANSIBLE_INVENTORY="infrastructure/ansible/inventories/${ENVIRONMENT}/hosts"
            shift 2
            ;;
        --test-version)
            TEST_VERSION="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
    ((TESTS_PASSED++))
}

failure() {
    echo -e "${RED}✗${NC} $*"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Run Ansible deployment
run_deployment() {
    local version="$1"
    local extra_vars="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY_RUN: Would deploy version $version with vars: $extra_vars"
        return 0
    fi
    
    log "Deploying version $version..."
    
    if ansible-playbook -i "$ANSIBLE_INVENTORY" "$DEPLOY_PLAYBOOK" \
        -e "target_version=$version" \
        -e "$extra_vars" \
        >/tmp/deploy-output.log 2>&1; then
        return 0
    else
        cat /tmp/deploy-output.log
        return 1
    fi
}

# Get current deployed version
get_deployed_version() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$TEST_VERSION"
        return 0
    fi
    
    # Query version from backend via SSH
    local backend_host
    backend_host=$(grep -A5 '\[production_web_servers\]' "$ANSIBLE_INVENTORY" | grep -v '^\[' | head -n1 | awk '{print $1}')
    
    ssh "$backend_host" "cat /opt/paws360/backend/version.txt 2>/dev/null || echo 'unknown'"
}

# Check if deployment made changes
check_deployment_changed() {
    local log_file="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        return 1  # Assume no changes in DRY_RUN
    fi
    
    # Check Ansible output for "changed" tasks
    if grep -q "changed: " "$log_file"; then
        return 0  # Changes were made
    else
        return 1  # No changes (idempotent)
    fi
}

# Test 1: Deploy same version twice (should be idempotent)
test_deploy_twice_same_version() {
    log "========================================="
    log "Test 1: Deploy same version twice"
    log "========================================="
    log "Expected: Second deployment should be no-op (idempotent)"
    echo
    
    local test_version="$TEST_VERSION"
    
    # First deployment
    log "Step 1: First deployment of $test_version"
    if ! run_deployment "$test_version" ""; then
        failure "Test 1: First deployment failed"
        return 1
    fi
    success "First deployment completed"
    
    # Wait for stabilization
    sleep 5
    
    # Second deployment (should be idempotent)
    log "Step 2: Second deployment of $test_version (should be no-op)"
    run_deployment "$test_version" "" >/tmp/deploy-second.log 2>&1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        success "Test 1: Idempotent deployment (DRY_RUN)"
        return 0
    fi
    
    # Check if second deployment made changes
    if check_deployment_changed /tmp/deploy-second.log; then
        failure "Test 1: Second deployment made changes (not idempotent)"
        cat /tmp/deploy-second.log
        return 1
    else
        success "Test 1: Second deployment was idempotent (no changes)"
        return 0
    fi
}

# Test 2: Deploy, rollback, re-deploy (should succeed)
test_deploy_rollback_redeploy() {
    log "========================================="
    log "Test 2: Deploy, rollback, re-deploy"
    log "========================================="
    log "Expected: Re-deployment after rollback should succeed"
    echo
    
    local new_version="${TEST_VERSION}-v2"
    local old_version="$TEST_VERSION"
    
    # Deploy new version
    log "Step 1: Deploy new version $new_version"
    if ! run_deployment "$new_version" ""; then
        failure "Test 2: New version deployment failed"
        return 1
    fi
    success "New version deployed"
    
    # Wait for stabilization
    sleep 5
    
    # Rollback to old version
    log "Step 2: Rollback to $old_version"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY_RUN: Would rollback to $old_version"
    else
        if ! ansible-playbook -i "$ANSIBLE_INVENTORY" \
            infrastructure/ansible/playbooks/rollback-production-safe.yml \
            -e "target_version=$old_version" \
            -e "failed_version=$new_version" \
            -e "rollback_reason=Idempotency test" \
            >/tmp/rollback.log 2>&1; then
            failure "Test 2: Rollback failed"
            cat /tmp/rollback.log
            return 1
        fi
    fi
    success "Rollback completed"
    
    # Wait for stabilization
    sleep 5
    
    # Re-deploy new version (should succeed)
    log "Step 3: Re-deploy $new_version after rollback"
    if ! run_deployment "$new_version" ""; then
        failure "Test 2: Re-deployment after rollback failed"
        return 1
    fi
    success "Test 2: Re-deployment after rollback succeeded"
    
    # Verify version
    local deployed_version
    deployed_version=$(get_deployed_version)
    if [[ "$deployed_version" == "$new_version" || "$DRY_RUN" == "true" ]]; then
        success "Test 2: Correct version deployed after rollback"
        return 0
    else
        failure "Test 2: Version mismatch (expected: $new_version, got: $deployed_version)"
        return 1
    fi
}

# Test 3: Interrupted deployment re-run (should converge)
test_interrupted_deployment_convergence() {
    log "========================================="
    log "Test 3: Interrupted deployment re-run"
    log "========================================="
    log "Expected: Re-running after interruption should converge to target state"
    echo
    
    local target_version="${TEST_VERSION}-v3"
    
    # Simulate interrupted deployment (fail intentionally at backend step)
    log "Step 1: Simulate interrupted deployment"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY_RUN: Would simulate interrupted deployment"
    else
        # Deploy with intentional failure
        ansible-playbook -i "$ANSIBLE_INVENTORY" "$DEPLOY_PLAYBOOK" \
            -e "target_version=$target_version" \
            -e "fail_intentionally=true" \
            -e "fail_at_step=backend" \
            >/tmp/deploy-interrupted.log 2>&1 || true
    fi
    warning "Simulated deployment interruption"
    
    # Wait for cleanup
    sleep 5
    
    # Re-run full deployment (should succeed and converge)
    log "Step 2: Re-run full deployment (should converge)"
    if ! run_deployment "$target_version" ""; then
        failure "Test 3: Re-run after interruption failed"
        return 1
    fi
    success "Re-run after interruption completed"
    
    # Verify convergence to target state
    local deployed_version
    deployed_version=$(get_deployed_version)
    if [[ "$deployed_version" == "$target_version" || "$DRY_RUN" == "true" ]]; then
        success "Test 3: Converged to target state after interruption"
        return 0
    else
        failure "Test 3: Did not converge (expected: $target_version, got: $deployed_version)"
        return 1
    fi
}

# Test 4: Partial state cleanup (verify no residual state)
test_partial_state_cleanup() {
    log "========================================="
    log "Test 4: Partial state cleanup"
    log "========================================="
    log "Expected: No residual state from failed deployments"
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY_RUN: Would verify no residual state"
        success "Test 4: No residual state (DRY_RUN)"
        return 0
    fi
    
    # Check for common residual artifacts
    local backend_host
    backend_host=$(grep -A5 '\[production_web_servers\]' "$ANSIBLE_INVENTORY" | grep -v '^\[' | head -n1 | awk '{print $1}')
    
    log "Checking for residual deployment artifacts..."
    
    # Check for lock files
    if ssh "$backend_host" "test -f /var/lib/paws360/deployment.lock" 2>/dev/null; then
        failure "Test 4: Deployment lock file still exists"
        return 1
    fi
    success "No deployment lock file"
    
    # Check for temp directories
    local temp_count
    temp_count=$(ssh "$backend_host" "find /tmp -name 'deploy-temp-*' -type d 2>/dev/null | wc -l" || echo "0")
    if [[ "$temp_count" -gt 0 ]]; then
        failure "Test 4: Found $temp_count temporary deployment directories"
        return 1
    fi
    success "No temporary deployment directories"
    
    # Check for failed deployment markers
    if ssh "$backend_host" "test -f /var/lib/paws360/failed-deployment-*" 2>/dev/null; then
        failure "Test 4: Failed deployment markers exist"
        return 1
    fi
    success "No failed deployment markers"
    
    success "Test 4: No residual state from partial deployments"
    return 0
}

# Test 5: Check mode validation (dry-run should not make changes)
test_check_mode() {
    log "========================================="
    log "Test 5: Ansible check mode (dry-run)"
    log "========================================="
    log "Expected: Check mode should not make any changes"
    echo
    
    if [[ "$DRY_RUN" == "true" ]]; then
        success "Test 5: Check mode validation (DRY_RUN)"
        return 0
    fi
    
    local test_version="${TEST_VERSION}-check"
    
    # Run deployment in check mode
    log "Running deployment in check mode..."
    if ansible-playbook -i "$ANSIBLE_INVENTORY" "$DEPLOY_PLAYBOOK" \
        -e "target_version=$test_version" \
        --check \
        >/tmp/deploy-check-mode.log 2>&1; then
        success "Check mode completed without errors"
    else
        warning "Check mode reported errors (may be expected)"
    fi
    
    # Verify no changes were made
    local deployed_version
    deployed_version=$(get_deployed_version)
    if [[ "$deployed_version" == "$test_version" ]]; then
        failure "Test 5: Check mode made changes (deployed $test_version)"
        return 1
    else
        success "Test 5: Check mode did not make changes"
        return 0
    fi
}

# Main test execution
main() {
    log "========================================="
    log "Deployment Idempotency Tests"
    log "========================================="
    log "Environment: $ENVIRONMENT"
    log "Test Version: $TEST_VERSION"
    log "Dry Run: $DRY_RUN"
    log "Inventory: $ANSIBLE_INVENTORY"
    log "========================================="
    echo
    
    if [[ "$DRY_RUN" == "false" ]]; then
        warning "⚠ RUNNING LIVE TESTS - This will deploy to $ENVIRONMENT"
        warning "Press Ctrl+C within 5 seconds to abort..."
        sleep 5
    fi
    
    # Run idempotency tests
    test_deploy_twice_same_version || true
    echo
    test_deploy_rollback_redeploy || true
    echo
    test_interrupted_deployment_convergence || true
    echo
    test_partial_state_cleanup || true
    echo
    test_check_mode || true
    echo
    
    # Summary
    log "========================================="
    log "Idempotency Test Results"
    log "========================================="
    log "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
    log "Tests Failed: ${RED}${TESTS_FAILED}${NC}"
    
    if [[ ${TESTS_FAILED} -gt 0 ]]; then
        log "Failed Tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo
        log "${RED}IDEMPOTENCY TESTS FAILED${NC}"
        exit 1
    else
        echo
        log "${GREEN}ALL IDEMPOTENCY TESTS PASSED${NC}"
        exit 0
    fi
}

# Run tests
main
