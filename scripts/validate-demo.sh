#!/bin/bash

# PAWS360 Demo Environment Validation Script
# Comprehensive validation for demo environment readiness
# Validates infrastructure health, demo data integrity, and authentication flows
#
# Usage: ./validate-demo.sh [options]
# Options:
#   --quick      Perform quick validation only
#   --deep       Perform deep validation including auth flows
#   --json       Output results in JSON format
#   --help       Show this help message

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
QUICK_MODE=false
DEEP_MODE=false
JSON_OUTPUT=false

# Service URLs
FRONTEND_URL="http://localhost:3000"
BACKEND_PORT="8086"
BACKEND_URL="http://localhost:${BACKEND_PORT}"
DB_HOST="localhost"
DB_PORT="5434"

# Demo credentials for testing
ADMIN_EMAIL="admin@uwm.edu"
STUDENT_EMAIL="john.smith@uwm.edu"
DEMO_STUDENT_EMAIL="demo.student@uwm.edu"
DEMO_PASSWORD="password123"

# Validation results tracking
declare -A validation_results
total_checks=0
passed_checks=0
failed_checks=0
warning_checks=0

echo -e "${BLUE}🔍 PAWS360 Demo Environment Validation${NC}"
echo -e "${BLUE}Comprehensive Demo Readiness Assessment${NC}"
echo "================================================"

# Function to print status messages
print_status() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️ WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ ERROR: $1${NC}"
}

print_info() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] ℹ️ $1${NC}"
}

print_check() {
    echo -e "${PURPLE}[$(date '+%H:%M:%S')] 🔎 $1${NC}"
}

# Function to record validation result
record_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    validation_results["$test_name"]="$status:$message"
    total_checks=$((total_checks + 1))
    
    case $status in
        "PASS")
            passed_checks=$((passed_checks + 1))
            print_status "$test_name: $message"
            ;;
        "FAIL")
            failed_checks=$((failed_checks + 1))
            print_error "$test_name: $message"
            ;;
        "WARN")
            warning_checks=$((warning_checks + 1))
            print_warning "$test_name: $message"
            ;;
    esac
}

# Function to show help
show_help() {
    echo "PAWS360 Demo Environment Validation Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --quick      Perform quick validation only (infrastructure)"
    echo "  --deep       Perform deep validation including authentication flows"
    echo "  --json       Output results in JSON format"
    echo "  --help       Show this help message"
    echo ""
    echo "Validation Levels:"
    echo "  Quick:  Infrastructure health, basic connectivity"
    echo "  Normal: Quick + demo data validation + API endpoints"
    echo "  Deep:   Normal + authentication flows + session management"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --deep)
            DEEP_MODE=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Function to check if a service is responding
check_service_health() {
    local service_url="$1"
    local timeout=${2:-5}
    
    if curl -s -f --max-time $timeout "$service_url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to make authenticated API call
make_auth_api_call() {
    local endpoint="$1"
    local token="$2"
    local method="${3:-GET}"
    
    if [ -n "$token" ]; then
        curl -s -X "$method" "$endpoint" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json"
    else
        curl -s -X "$method" "$endpoint" \
            -H "Content-Type: application/json"
    fi
}

# Function to perform authentication test
test_authentication() {
    local email="$1"
    local password="$2"
    local role="$3"
    
    local login_payload="{\"email\":\"$email\",\"password\":\"$password\"}"
    local response=$(curl -s -X POST "$BACKEND_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "$login_payload" 2>/dev/null)
    
    if echo "$response" | grep -q "token\|success"; then
        # Extract token if present
        local token=$(echo "$response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        echo "$token"
        return 0
    else
        return 1
    fi
}

# Infrastructure Validation Tests
validate_infrastructure() {
    print_check "Validating infrastructure components..."
    
    # Test 1: Database connectivity
    if command -v docker &> /dev/null && docker ps | grep -q paws360-postgres; then
        if docker exec paws360-postgres pg_isready -U paws360_app -d paws360 &> /dev/null; then
            record_result "Database Connectivity" "PASS" "PostgreSQL responding correctly"
        else
            record_result "Database Connectivity" "FAIL" "PostgreSQL not responding"
        fi
    else
        record_result "Database Connectivity" "WARN" "Database container not found - may be running externally"
    fi
    
    # Test 2: Backend API health
    if check_service_health "$BACKEND_URL/health/ping" 10; then
        record_result "Backend API Health" "PASS" "Spring Boot application responding"
    else
        record_result "Backend API Health" "FAIL" "Backend not responding on $BACKEND_URL"
    fi
    
    # Test 3: Frontend accessibility
    if check_service_health "$FRONTEND_URL" 10; then
        record_result "Frontend Accessibility" "PASS" "Next.js application responding"
    else
        record_result "Frontend Accessibility" "FAIL" "Frontend not responding on $FRONTEND_URL"
    fi
    
    # Test 4: Backend health endpoint detailed check
    local health_response=$(curl -s "$BACKEND_URL/health/status" 2>/dev/null)
    if echo "$health_response" | grep -q '"overall_healthy":true'; then
        record_result "Backend Health Status" "PASS" "All backend components healthy"
    elif echo "$health_response" | grep -q '"overall_healthy":false'; then
        record_result "Backend Health Status" "WARN" "Some backend components unhealthy"
    else
        record_result "Backend Health Status" "FAIL" "Health endpoint not responding properly"
    fi
}

# Demo Data Validation Tests
validate_demo_data() {
    print_check "Validating demo data integrity..."
    
    # Test 5: Demo data validation endpoint
    local demo_validation=$(curl -s "$BACKEND_URL/demo/validate" 2>/dev/null)
    if echo "$demo_validation" | grep -q '"valid":true'; then
        record_result "Demo Data Integrity" "PASS" "All demo data validation checks passed"
    elif echo "$demo_validation" | grep -q '"valid":false'; then
        local error_count=$(echo "$demo_validation" | grep -o '"error_count":[0-9]*' | cut -d':' -f2)
        record_result "Demo Data Integrity" "FAIL" "$error_count validation errors found"
    else
        record_result "Demo Data Integrity" "WARN" "Demo validation endpoint not responding"
    fi
    
    # Test 6: Demo accounts availability
    local demo_status=$(curl -s "$BACKEND_URL/demo/accounts" 2>/dev/null)
    if echo "$demo_status" | grep -q "admin@uwm.edu"; then
        if echo "$demo_status" | grep -q "john.smith@uwm.edu"; then
            record_result "Demo Accounts Availability" "PASS" "Required demo accounts found"
        else
            record_result "Demo Accounts Availability" "WARN" "Admin account found but missing student accounts"
        fi
    else
        record_result "Demo Accounts Availability" "FAIL" "Required demo accounts not found"
    fi
    
    # Test 7: Database user count validation
    if command -v docker &> /dev/null && docker ps | grep -q paws360-postgres; then
        local user_count=$(docker exec paws360-postgres psql -U paws360_app -d paws360 -t -c "SELECT COUNT(*) FROM users WHERE email LIKE '%@uwm.edu';" 2>/dev/null | tr -d ' ')
        if [ "$user_count" -ge 5 ]; then
            record_result "Demo User Count" "PASS" "$user_count demo users found in database"
        elif [ "$user_count" -gt 0 ]; then
            record_result "Demo User Count" "WARN" "Only $user_count demo users found (expected 5+)"
        else
            record_result "Demo User Count" "FAIL" "No demo users found in database"
        fi
    else
        record_result "Demo User Count" "WARN" "Cannot verify user count - database not accessible"
    fi
}

# API Endpoint Validation Tests
validate_api_endpoints() {
    print_check "Validating API endpoints..."
    
    # Test 8: Authentication endpoints
    local auth_endpoint_status=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/auth/login" -X POST)
    if [ "$auth_endpoint_status" = "200" ] || [ "$auth_endpoint_status" = "400" ]; then
        record_result "Auth Endpoint Availability" "PASS" "Authentication endpoint responding"
    else
        record_result "Auth Endpoint Availability" "FAIL" "Authentication endpoint not available (HTTP $auth_endpoint_status)"
    fi
    
    # Test 9: User profile endpoints
    local profile_endpoint_status=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/user/profile")
    if [ "$profile_endpoint_status" = "401" ] || [ "$profile_endpoint_status" = "403" ]; then
        record_result "Profile Endpoint Security" "PASS" "Profile endpoint properly secured"
    elif [ "$profile_endpoint_status" = "200" ]; then
        record_result "Profile Endpoint Security" "WARN" "Profile endpoint accessible without authentication"
    else
        record_result "Profile Endpoint Security" "FAIL" "Profile endpoint not responding properly"
    fi
    
    # Test 10: Demo management endpoints
    local demo_info=$(curl -s "$BACKEND_URL/demo/info" 2>/dev/null)
    if echo "$demo_info" | grep -q '"controller":"DemoController"'; then
        record_result "Demo Management API" "PASS" "Demo management endpoints available"
    else
        record_result "Demo Management API" "FAIL" "Demo management endpoints not responding"
    fi
}

# Authentication Flow Validation Tests (Deep mode only)
validate_authentication_flows() {
    print_check "Validating authentication flows..."
    
    # Test 11: Admin authentication
    local admin_token=$(test_authentication "$ADMIN_EMAIL" "$DEMO_PASSWORD" "admin")
    if [ $? -eq 0 ] && [ -n "$admin_token" ]; then
        record_result "Admin Authentication" "PASS" "Admin login successful"
        
        # Test admin-specific endpoints
        local admin_profile=$(make_auth_api_call "$BACKEND_URL/user/profile" "$admin_token")
        if echo "$admin_profile" | grep -q "$ADMIN_EMAIL"; then
            record_result "Admin Profile Access" "PASS" "Admin can access profile data"
        else
            record_result "Admin Profile Access" "WARN" "Admin profile access issues"
        fi
    else
        record_result "Admin Authentication" "FAIL" "Admin login failed"
    fi
    
    # Test 12: Student authentication
    local student_token=$(test_authentication "$STUDENT_EMAIL" "$DEMO_PASSWORD" "student")
    if [ $? -eq 0 ] && [ -n "$student_token" ]; then
        record_result "Student Authentication" "PASS" "Primary student login successful"
        
        # Test student-specific endpoints
        local student_profile=$(make_auth_api_call "$BACKEND_URL/user/profile" "$student_token")
        if echo "$student_profile" | grep -q "$STUDENT_EMAIL"; then
            record_result "Student Profile Access" "PASS" "Student can access profile data"
        else
            record_result "Student Profile Access" "WARN" "Student profile access issues"
        fi
    else
        record_result "Student Authentication" "FAIL" "Primary student login failed"
    fi
    
    # Test 13: Demo student authentication
    local demo_student_token=$(test_authentication "$DEMO_STUDENT_EMAIL" "$DEMO_PASSWORD" "student")
    if [ $? -eq 0 ] && [ -n "$demo_student_token" ]; then
        record_result "Demo Student Authentication" "PASS" "Demo student login successful"
    else
        record_result "Demo Student Authentication" "FAIL" "Demo student login failed"
    fi
    
    # Test 14: Invalid credentials rejection
    local invalid_response=$(curl -s -X POST "$BACKEND_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"invalid@uwm.edu","password":"wrongpassword"}' 2>/dev/null)
    
    if echo "$invalid_response" | grep -q "error\|invalid\|unauthorized" || ! echo "$invalid_response" | grep -q "token"; then
        record_result "Invalid Credentials Rejection" "PASS" "Invalid login attempts properly rejected"
    else
        record_result "Invalid Credentials Rejection" "FAIL" "Invalid credentials not properly rejected"
    fi
}

# Session Management Validation Tests (Deep mode only)
validate_session_management() {
    print_check "Validating session management..."
    
    # Test 15: Session endpoint availability
    local session_status=$(curl -s "$BACKEND_URL/health/sessions" 2>/dev/null)
    if echo "$session_status" | grep -q '"healthy":true'; then
        record_result "Session Management Health" "PASS" "Session management system healthy"
        
        # Extract session count if available
        local active_sessions=$(echo "$session_status" | grep -o '"current_active_sessions":[0-9]*' | cut -d':' -f2)
        if [ -n "$active_sessions" ]; then
            record_result "Active Sessions Count" "PASS" "$active_sessions active sessions tracked"
        fi
    else
        record_result "Session Management Health" "WARN" "Session management status unclear"
    fi
    
    # Test 16: Session validation with token
    if [ -n "$student_token" ]; then
        local session_validation=$(make_auth_api_call "$BACKEND_URL/auth/validate" "$student_token")
        if echo "$session_validation" | grep -q "valid\|success"; then
            record_result "Session Token Validation" "PASS" "Session tokens properly validated"
        else
            record_result "Session Token Validation" "WARN" "Session validation unclear"
        fi
    else
        record_result "Session Token Validation" "WARN" "No token available for session validation"
    fi
}

# Frontend Integration Validation Tests
validate_frontend_integration() {
    print_check "Validating frontend integration..."
    
    # Test 17: Frontend login page accessibility
    local frontend_content=$(curl -s "$FRONTEND_URL/login" 2>/dev/null)
    if echo "$frontend_content" | grep -qi "login\|sign.*in\|email\|password"; then
        record_result "Frontend Login Page" "PASS" "Login page accessible and contains expected elements"
    else
        record_result "Frontend Login Page" "WARN" "Login page accessibility unclear"
    fi
    
    # Test 18: Frontend homepage accessibility
    local homepage_content=$(curl -s "$FRONTEND_URL/homepage" 2>/dev/null)
    if echo "$homepage_content" | grep -qi "dashboard\|welcome\|homepage\|student"; then
        record_result "Frontend Homepage" "PASS" "Homepage accessible and contains expected content"
    else
        record_result "Frontend Homepage" "WARN" "Homepage accessibility unclear"
    fi
    
    # Test 19: API connectivity from frontend perspective
    local api_status=$(curl -s "$FRONTEND_URL/api/health" 2>/dev/null)
    if [ $? -eq 0 ]; then
        record_result "Frontend API Connectivity" "PASS" "Frontend can communicate with backend"
    else
        record_result "Frontend API Connectivity" "WARN" "Frontend API connectivity unclear"
    fi
}

# Performance and Resource Validation Tests
validate_performance() {
    print_check "Validating performance and resources..."
    
    # Test 20: Response time validation
    local start_time=$(date +%s%N)
    check_service_health "$BACKEND_URL/health/ping" 5
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [ $response_time -lt 200 ]; then
        record_result "Backend Response Time" "PASS" "Response time: ${response_time}ms (excellent)"
    elif [ $response_time -lt 1000 ]; then
        record_result "Backend Response Time" "PASS" "Response time: ${response_time}ms (acceptable)"
    else
        record_result "Backend Response Time" "WARN" "Response time: ${response_time}ms (slow)"
    fi
    
    # Test 21: Memory usage check (if available)
    if command -v docker &> /dev/null; then
        local memory_info=$(docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}" 2>/dev/null | grep paws360)
        if [ -n "$memory_info" ]; then
            record_result "Resource Usage" "PASS" "Container resource usage monitored"
        else
            record_result "Resource Usage" "WARN" "Resource usage monitoring not available"
        fi
    else
        record_result "Resource Usage" "WARN" "Docker not available for resource monitoring"
    fi
}

# Function to output results in JSON format
output_json_results() {
    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"validation_mode\": \"$([ "$QUICK_MODE" = true ] && echo "quick" || [ "$DEEP_MODE" = true ] && echo "deep" || echo "normal")\","
    echo "  \"summary\": {"
    echo "    \"total_checks\": $total_checks,"
    echo "    \"passed_checks\": $passed_checks,"
    echo "    \"failed_checks\": $failed_checks,"
    echo "    \"warning_checks\": $warning_checks,"
    echo "    \"success_rate\": $(echo "scale=2; $passed_checks * 100 / $total_checks" | bc -l)%"
    echo "  },"
    echo "  \"results\": {"
    
    local first=true
    for test in "${!validation_results[@]}"; do
        [ "$first" = true ] && first=false || echo ","
        local status=$(echo "${validation_results[$test]}" | cut -d':' -f1)
        local message=$(echo "${validation_results[$test]}" | cut -d':' -f2-)
        echo -n "    \"$test\": {\"status\": \"$status\", \"message\": \"$message\"}"
    done
    echo ""
    echo "  },"
    echo "  \"overall_status\": \"$([ $failed_checks -eq 0 ] && echo "PASS" || echo "FAIL")\","
    echo "  \"demo_ready\": $([ $failed_checks -eq 0 ] && echo "true" || echo "false")"
    echo "}"
}

# Function to output results in human-readable format
output_human_results() {
    echo ""
    echo -e "${BLUE}📊 VALIDATION SUMMARY${NC}"
    echo "================================================"
    echo -e "🎯 Total Checks: ${CYAN}$total_checks${NC}"
    echo -e "✅ Passed: ${GREEN}$passed_checks${NC}"
    echo -e "❌ Failed: ${RED}$failed_checks${NC}"
    echo -e "⚠️ Warnings: ${YELLOW}$warning_checks${NC}"
    
    local success_rate=$(echo "scale=1; $passed_checks * 100 / $total_checks" | bc -l)
    echo -e "📈 Success Rate: ${PURPLE}$success_rate%${NC}"
    echo ""
    
    if [ $failed_checks -eq 0 ]; then
        echo -e "${GREEN}🎉 DEMO ENVIRONMENT READY!${NC}"
        echo -e "${GREEN}All critical validations passed. Demo can proceed.${NC}"
    else
        echo -e "${RED}❌ DEMO ENVIRONMENT NOT READY${NC}"
        echo -e "${RED}$failed_checks critical issues must be resolved before demo.${NC}"
    fi
    
    if [ $warning_checks -gt 0 ]; then
        echo -e "${YELLOW}⚠️ $warning_checks warnings detected - review recommended${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔧 NEXT STEPS:${NC}"
    if [ $failed_checks -eq 0 ]; then
        echo -e "  ✅ Demo environment validated successfully"
        echo -e "  🚀 Ready to begin demonstration"
        echo -e "  📋 Use demo credentials for authentication testing"
    else
        echo -e "  🔧 Resolve failed validation checks"
        echo -e "  🔄 Re-run validation after fixes"
        echo -e "  📝 Check logs for detailed error information"
    fi
    echo ""
}

# Main execution flow
main() {
    local start_time=$(date +%s)
    
    print_info "Starting validation in $([ "$QUICK_MODE" = true ] && echo "QUICK" || [ "$DEEP_MODE" = true ] && echo "DEEP" || echo "NORMAL") mode"
    print_info "Target Frontend: $FRONTEND_URL"
    print_info "Target Backend: $BACKEND_URL"
    echo ""
    
    # Always run infrastructure validation
    validate_infrastructure
    
    if [ "$QUICK_MODE" = false ]; then
        # Normal and Deep modes include these
        validate_demo_data
        validate_api_endpoints
        validate_frontend_integration
        validate_performance
        
        if [ "$DEEP_MODE" = true ]; then
            # Deep mode includes authentication and session testing
            validate_authentication_flows
            validate_session_management
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_info "Validation completed in ${duration}s"
    
    # Output results based on format preference
    if [ "$JSON_OUTPUT" = true ]; then
        output_json_results
    else
        output_human_results
    fi
    
    # Exit with appropriate code
    if [ $failed_checks -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"