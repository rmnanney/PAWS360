#!/usr/bin/env bash
# Constitutional Compliance Self-Check Script
# Purpose: Validate adherence to PAWS360 Constitutional Framework
# JIRA: INFRA-472 (GitHub Runner Deployment Stabilization)
# Usage: ./scripts/compliance/constitutional-self-check.sh [--fix]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0
FIX_MODE=false

if [[ "${1:-}" == "--fix" ]]; then
    FIX_MODE=true
    echo -e "${YELLOW}Running in FIX mode - will attempt automatic remediation${NC}"
fi

echo "====================================="
echo " Constitutional Compliance Self-Check"
echo "====================================="
echo ""

# Article I: JIRA-First Approach
echo "Checking Article I: JIRA-First Approach..."

# Check if feature has JIRA epic
if [[ ! -f "docs/jira/INFRA-472.md" ]]; then
    echo -e "${RED}✗ FAIL: Missing JIRA epic documentation${NC}"
    echo "  Expected: docs/jira/INFRA-472.md"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ PASS: JIRA epic documentation exists${NC}"
fi

# Check if user stories have JIRA tickets
for story in "INFRA-473" "INFRA-474" "INFRA-475"; do
    if [[ ! -f "docs/jira/${story}.md" ]]; then
        echo -e "${RED}✗ FAIL: Missing JIRA story documentation for ${story}${NC}"
        ((ERRORS++))
    else
        echo -e "${GREEN}✓ PASS: JIRA story ${story} documented${NC}"
    fi
done

echo ""

# Article II: Context Management
echo "Checking Article II: Context Management..."

# Check if context files exist
CONTEXT_FILES=(
    "contexts/infrastructure/github-runners.md"
    "contexts/infrastructure/deployment-pipeline.md"
    "contexts/infrastructure/monitoring-stack.md"
)

for context_file in "${CONTEXT_FILES[@]}"; do
    if [[ ! -f "${context_file}" ]]; then
        echo -e "${RED}✗ FAIL: Missing context file: ${context_file}${NC}"
        ((ERRORS++))
    else
        # Check if context file has JIRA reference
        if ! grep -q "INFRA-472" "${context_file}"; then
            echo -e "${YELLOW}⚠ WARN: Context file ${context_file} missing JIRA reference${NC}"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✓ PASS: Context file ${context_file} exists with JIRA reference${NC}"
        fi
    fi
done

# Check session file exists
if [[ ! -f "contexts/sessions/001-github-runner-deploy.yml" ]]; then
    echo -e "${RED}✗ FAIL: Missing session tracking file${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓ PASS: Session tracking file exists${NC}"
fi

echo ""

# Article VIIa: Monitoring Discovery (No Hardcoded IPs)
echo "Checking Article VIIa: Monitoring Discovery (IaC Mandate)..."

# Check scripts for hardcoded IPs (exclude localhost/127.0.0.1 and test scripts)
# Looking for infrastructure IPs like 192.168.x.x, 10.x.x.x, 172.16-31.x.x
HARDCODED_IP_PATTERN='(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})'

# Exclude patterns: test scripts, chaos scripts, Docker compose CIDR blocks
EXCLUDE_PATTERN='(test|chaos|docker-compose)'

# Search in scripts directory (excluding test/chaos scripts)
if [[ -d "scripts" ]]; then
    HARDCODED_FILES=$(grep -r -l -E "${HARDCODED_IP_PATTERN}" scripts/ 2>/dev/null | \
        grep -v -E "${EXCLUDE_PATTERN}" || true)
    if [[ -n "${HARDCODED_FILES}" ]]; then
        echo -e "${RED}✗ FAIL: Hardcoded infrastructure IPs found in scripts (violates IaC mandate)${NC}"
        echo "${HARDCODED_FILES}" | while read -r file; do
            echo "  - ${file}"
            grep -n -E "${HARDCODED_IP_PATTERN}" "${file}" | head -3
        done
        ((ERRORS++))
    else
        echo -e "${GREEN}✓ PASS: No hardcoded infrastructure IPs in scripts${NC}"
    fi
fi

# Check GitHub workflows for hardcoded infrastructure IPs (exclude localhost)
if [[ -f ".github/workflows/ci.yml" ]]; then
    if grep -q -E "${HARDCODED_IP_PATTERN}" ".github/workflows/ci.yml"; then
        echo -e "${RED}✗ FAIL: Hardcoded infrastructure IPs in ci.yml workflow${NC}"
        grep -n -E "${HARDCODED_IP_PATTERN}" ".github/workflows/ci.yml" | head -5
        ((ERRORS++))
    else
        echo -e "${GREEN}✓ PASS: No hardcoded infrastructure IPs in ci.yml${NC}"
    fi
fi

echo ""

# Article X: Truth & Partnership (Accurate Status Reporting)
echo "Checking Article X: Truth & Partnership..."

# Check if session file has accurate status
if [[ -f "contexts/sessions/001-github-runner-deploy.yml" ]]; then
    if grep -q "status: \"in_progress\"" "contexts/sessions/001-github-runner-deploy.yml"; then
        echo -e "${GREEN}✓ PASS: Session file reflects in-progress status${NC}"
    else
        echo -e "${YELLOW}⚠ WARN: Session status may not be accurate${NC}"
        ((WARNINGS++))
    fi
fi

# Check if JIRA tickets have acceptance criteria
for story in "INFRA-473" "INFRA-474" "INFRA-475"; do
    if [[ -f "docs/jira/${story}.md" ]]; then
        if ! grep -q "## Acceptance Criteria" "docs/jira/${story}.md"; then
            echo -e "${RED}✗ FAIL: ${story} missing acceptance criteria${NC}"
            ((ERRORS++))
        else
            echo -e "${GREEN}✓ PASS: ${story} has acceptance criteria${NC}"
        fi
    fi
done

echo ""

# Article XIII: Proactive Compliance
echo "Checking Article XIII: Proactive Compliance..."

# Check if pre-commit hook exists
if [[ ! -f ".git/hooks/pre-commit" ]]; then
    echo -e "${YELLOW}⚠ WARN: No pre-commit hook installed${NC}"
    echo "  Recommendation: Run scripts/compliance/install-pre-commit-hook.sh"
    ((WARNINGS++))
    
    if [[ "${FIX_MODE}" == "true" ]]; then
        echo "  Attempting to install pre-commit hook..."
        if [[ -f "scripts/compliance/install-pre-commit-hook.sh" ]]; then
            bash scripts/compliance/install-pre-commit-hook.sh
            echo -e "${GREEN}  ✓ Pre-commit hook installed${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ PASS: Pre-commit hook exists${NC}"
fi

# Check if constitutional compliance is referenced in tasks.md
if [[ -f "specs/001-github-runner-deploy/tasks.md" ]]; then
    if ! grep -q -i "constitutional" "specs/001-github-runner-deploy/tasks.md"; then
        echo -e "${YELLOW}⚠ WARN: tasks.md may not reference constitutional compliance${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓ PASS: tasks.md references constitutional compliance${NC}"
    fi
fi

echo ""

# Summary
echo "====================================="
echo " Compliance Check Summary"
echo "====================================="
if [[ ${ERRORS} -eq 0 && ${WARNINGS} -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED${NC}"
    echo "Constitutional compliance: FULL"
    exit 0
elif [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} WARNING(S)${NC}"
    echo "Constitutional compliance: PARTIAL (warnings only)"
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} ERROR(S), ${WARNINGS} WARNING(S)${NC}"
    echo "Constitutional compliance: FAILED"
    echo ""
    echo "Remediation steps:"
    echo "1. Address all ERRORS before proceeding with implementation"
    echo "2. Review WARNINGS for compliance improvements"
    echo "3. Re-run this script to validate fixes"
    echo "4. Use --fix flag to attempt automatic remediation"
    exit 1
fi
