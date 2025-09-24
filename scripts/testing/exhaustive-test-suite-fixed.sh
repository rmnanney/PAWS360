#!/bin/bash

# 🧪 PAWS360 EXHAUSTIVE TEST SUITE
# Comprehensive testing with pattern detection and automated fixes

set -e  # Exit on any error

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0
FIXED_ISSUES=0

# Pattern tracking for automated fixes
declare -A FAILURE_PATTERNS
declare -A FIX_SUGGESTIONS

# Logging functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    # Track failure patterns
    key="$2"
    if [ -z "${FAILURE_PATTERNS[$key]}" ]; then
        FAILURE_PATTERNS["$key"]=1
    else
        FAILURE_PATTERNS["$key"]=$((FAILURE_PATTERNS["$key"] + 1))
    fi
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

log_fix() {
    echo -e "${CYAN}[FIX]${NC} $1"
    FIXED_ISSUES=$((FIXED_ISSUES + 1))
}

log_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Header
echo "🧪 PAWS360 EXHAUSTIVE TEST SUITE"
echo "================================="
echo "Date: $(date)"
echo "Testing with relentless improvement mindset"
echo ""

# 1. FILE SYSTEM & ORGANIZATION TESTS
echo "📁 FILE SYSTEM TESTS"
echo "==================="

# Test 1: Required directories exist
log_test "Checking required directory structure"
REQUIRED_DIRS=("specs" "templates" "scripts" "memory" "docs")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        log_pass "Directory $dir exists"
    else
        log_fail "Missing required directory: $dir" "missing_directory"
        FIX_SUGGESTIONS["missing_directory"]="mkdir -p $dir"
    fi
done

# Test 2: File permissions
log_test "Checking file permissions"
find . -name "*.sh" -exec test -x {} \; -print 2>/dev/null | while read -r file; do
    if [ -n "$file" ]; then
        log_pass "Script $file is executable"
    fi
done

# Test 3: Spec structure validation
log_test "Validating spec folder structure"
for spec_dir in specs/*/; do
    if [ -d "$spec_dir" ]; then
        spec_name=$(basename "$spec_dir")
        log_info "Checking spec: $spec_name"

        # Check for required files
        required_files=("spec.md" "plan.md" "tasks.md")
        for file in "${required_files[@]}"; do
            if [ -f "$spec_dir$file" ]; then
                log_pass "Spec $spec_name has $file"
            else
                log_fail "Spec $spec_name missing $file" "missing_spec_file"
                FIX_SUGGESTIONS["missing_spec_file"]="cp templates/spec-template.md $spec_dir$file"
            fi
        done
    fi
done

# 2. MARKDOWN & DOCUMENTATION TESTS
echo ""
echo "📝 DOCUMENTATION TESTS"
echo "======================"

# Test 4: Markdown file validation
log_test "Validating Markdown files"
find . -name "*.md" | while read -r file; do
    if [ -f "$file" ]; then
        # Basic checks
        if grep -q "^#" "$file"; then
            log_pass "Markdown structure OK: $file"
        else
            log_warn "No headers found in: $file"
        fi
    fi
done

# Test 5: Documentation completeness
log_test "Checking documentation completeness"
find specs/ -name "*.md" | while read -r file; do
    # Check for common issues
    if grep -q "\[NEEDS CLARIFICATION\]" "$file" 2>/dev/null; then
        log_fail "Unresolved clarification needed: $file" "needs_clarification"
        FIX_SUGGESTIONS["needs_clarification"]="sed -i 's/\[NEEDS CLARIFICATION\]//g' $file"
    fi

    if grep -q "\[TODO\]" "$file" 2>/dev/null; then
        log_warn "TODO items found: $file"
    fi
done

# 3. SCRIPT & AUTOMATION TESTS
echo ""
echo "🔧 SCRIPT TESTS"
echo "==============="

# Test 6: Shell script validation
log_test "Validating shell scripts"
find . -name "*.sh" | while read -r script; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            # Basic syntax check
            if bash -n "$script" 2>/dev/null; then
                log_pass "Shell script syntax OK: $script"
            else
                log_fail "Shell script syntax error: $script" "shell_syntax"
                FIX_SUGGESTIONS["shell_syntax"]="bash -n $script # Check syntax manually"
            fi
        else
            log_fail "Script not executable: $script" "non_executable_script"
            FIX_SUGGESTIONS["non_executable_script"]="chmod +x $script"
        fi
    fi
done

# 4. JAVA CODE QUALITY TESTS
echo ""
echo "☕ JAVA CODE TESTS"
echo "================="

# Test 7: Java file validation
log_test "Validating Java files"
find . -name "*.java" | while read -r java_file; do
    if [ -f "$java_file" ]; then
        # Check for basic Java syntax (class, interface, or enum)
        if grep -q "public class\|public interface\|public enum" "$java_file" 2>/dev/null; then
            log_pass "Java file structure OK: $java_file"
        else
            log_fail "Java file missing class/interface/enum declaration: $java_file" "java_structure"
        fi

        # Check for common issues
        if grep -q "System.out.println" "$java_file" 2>/dev/null; then
            log_warn "Debug print statements found: $java_file"
        fi

        if ! grep -q "package" "$java_file" 2>/dev/null; then
            log_fail "Missing package declaration: $java_file" "missing_package"
        fi
    fi
done

# 5. CONFIGURATION & ENVIRONMENT TESTS
echo ""
echo "⚙️ CONFIGURATION TESTS"
echo "======================"

# Test 8: Environment file validation
log_test "Checking environment configuration"
if [ -f ".env.example" ]; then
    log_pass "Environment template exists"

    # Check for required variables
    required_vars=("JIRA_URL" "JIRA_PROJECT_KEY")
    for var in "${required_vars[@]}"; do
        if grep -q "$var=" .env.example 2>/dev/null; then
            log_pass "Required env var template: $var"
        else
            log_fail "Missing required env var: $var" "missing_env_var"
        fi
    done
else
    log_fail "Missing .env.example file" "missing_env_template"
    FIX_SUGGESTIONS["missing_env_template"]="Create .env.example with required variables"
fi

# Test 9: Git configuration
log_test "Validating Git configuration"
if git rev-parse --git-dir > /dev/null 2>&1; then
    log_pass "Git repository initialized"

    # Check for required files
    required_git_files=(".gitignore")
    for file in "${required_git_files[@]}"; do
        if [ -f "$file" ]; then
            log_pass "Git file exists: $file"
        else
            log_fail "Missing Git file: $file" "missing_git_file"
        fi
    done
else
    log_fail "Not a Git repository" "not_git_repo"
fi

# 6. SECURITY TESTS
echo ""
echo "🔒 SECURITY TESTS"
echo "================="

# Test 10: Security file scan
log_test "Basic security scan"
find . -name "*.md" -o -name "*.sh" -o -name "*.py" | while read -r file; do
    if [ -f "$file" ]; then
        # Check for hardcoded secrets
        if grep -q "password\|secret\|key\|token" "$file" 2>/dev/null | grep -v "example\|template\|placeholder" > /dev/null; then
            log_fail "Potential hardcoded secret: $file" "hardcoded_secret"
            FIX_SUGGESTIONS["hardcoded_secret"]="Move secrets to environment variables"
        fi
    fi
done

# Test 11: File permissions security
log_test "Checking file permissions security"
find . -name "*.sh" -exec ls -la {} \; 2>/dev/null | while read -r line; do
    if echo "$line" | grep -q "rwxrwxrwx"; then
        file_path=$(echo "$line" | awk '{print $9}')
        log_fail "Insecure permissions (777): $file_path" "insecure_permissions"
        FIX_SUGGESTIONS["insecure_permissions"]="chmod 755 $file_path"
    fi
done

# 7. PERFORMANCE & EFFICIENCY TESTS
echo ""
echo "⚡ PERFORMANCE TESTS"
echo "==================="

# Test 12: File size check
log_test "Checking file sizes"
find . -name "*.md" -exec wc -l {} \; 2>/dev/null | while read -r lines file; do
    if [ "$lines" -gt 1000 ] 2>/dev/null; then
        log_warn "Large file (>1000 lines): $file"
    fi
done

# 8. PATTERN ANALYSIS & AUTOMATED FIXES
echo ""
echo "🔍 PATTERN ANALYSIS"
echo "==================="

# Analyze failure patterns
log_info "Failure Pattern Analysis:"
for pattern in "${!FAILURE_PATTERNS[@]}"; do
    count=${FAILURE_PATTERNS[$pattern]}
    echo "  $pattern: $count occurrences"
done

# Suggest automated fixes
if [ ${#FIX_SUGGESTIONS[@]} -gt 0 ]; then
    echo ""
    log_info "Automated Fix Suggestions:"
    for issue in "${!FIX_SUGGESTIONS[@]}"; do
        suggestion=${FIX_SUGGESTIONS[$issue]}
        echo "  $issue → $suggestion"
    done

    echo ""
    log_info "Applying automated fixes..."

    # Apply fixes
    for issue in "${!FIX_SUGGESTIONS[@]}"; do
        case $issue in
            "non_executable_script")
                find . -name "*.sh" ! -executable -exec chmod +x {} \; 2>/dev/null
                log_fix "Made scripts executable"
                ;;
            "insecure_permissions")
                find . -name "*.sh" -exec chmod 755 {} \; 2>/dev/null
                log_fix "Fixed script permissions"
                ;;
        esac
    done
fi

# 9. FINAL REPORT
echo ""
echo "📊 FINAL TEST REPORT"
echo "==================="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "Warnings: $WARNINGS"
echo "Auto-fixed: $FIXED_ISSUES"

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Success Rate: ${success_rate}%"
fi

# Overall assessment
if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo "Your codebase is in excellent shape!"
elif [ $FAILED_TESTS -lt 5 ]; then
    echo ""
    echo -e "${YELLOW}⚠️ MOSTLY GOOD${NC}"
    echo "Only $FAILED_TESTS minor issues to address"
else
    echo ""
    echo -e "${RED}🚨 NEEDS ATTENTION${NC}"
    echo "$FAILED_TESTS issues require fixing"
fi

echo ""
echo "Next steps:"
echo "1. Review failed tests above"
echo "2. Apply automated fixes where available"
echo "3. Address pattern-based issues"
echo "4. Re-run tests to verify improvements"

echo ""
echo "Test completed at: $(date)"