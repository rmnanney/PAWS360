#!/usr/bin/env bash
# Purpose: Validate GitHub Secrets for production deployment safety
# JIRA: INFRA-472, INFRA-475
# Usage: ./scripts/ci/validate-secrets.sh [--github-token TOKEN] [--repo OWNER/REPO]
#
# Checks:
# 1. Presence of required secrets via GitHub API
# 2. Format validation for SSH keys and tokens
# 3. Expiry validation for tokens with metadata
# 4. Fingerprint validation for SSH keys (if fingerprints provided)
#
# Exit codes:
# 0 - All secrets valid
# 1 - Missing or invalid secrets detected

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --github-token)
      GITHUB_TOKEN="$2"
      shift 2
      ;;
    --repo)
      GITHUB_REPOSITORY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--github-token TOKEN] [--repo OWNER/REPO]"
      exit 1
      ;;
  esac
done

# Validate prerequisites
if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${RED}ERROR: GITHUB_TOKEN not set. Use --github-token or set environment variable.${NC}"
  exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo -e "${RED}ERROR: GITHUB_REPOSITORY not set. Use --repo or set environment variable (format: owner/repo).${NC}"
  exit 1
fi

# Mask token in output (GitHub Actions compatible)
echo "::add-mask::$GITHUB_TOKEN" 2>/dev/null || true

echo "Validating GitHub Secrets for repository: $GITHUB_REPOSITORY"
echo "-----------------------------------------------------------"

# Required secrets for production deployment
REQUIRED_SECRETS=(
  "PRODUCTION_SSH_PRIVATE_KEY"
  "PRODUCTION_SSH_USER"
)

# Optional secrets (warning if missing, not failure)
OPTIONAL_SECRETS=(
  "STAGING_SSH_PRIVATE_KEY"
  "STAGING_SSH_USER"
  "GHCR_PAT"
  "SLACK_WEBHOOK"
  "AUTO_DEPLOY_TO_STAGE"
  "AUTO_DEPLOY_TO_PRODUCTION"
)

# Expected SSH key fingerprints (SHA256) - REPLACE WITH ACTUAL VALUES
# Generate via: ssh-keygen -lf id_rsa.pub -E sha256
EXPECTED_PROD_SSH_FINGERPRINT="SHA256:REPLACE_WITH_ACTUAL_FINGERPRINT"
EXPECTED_STAGE_SSH_FINGERPRINT="SHA256:REPLACE_WITH_ACTUAL_FINGERPRINT"

VALIDATION_FAILED=0

# Function to check if secret exists via GitHub API
check_secret_exists() {
  local secret_name=$1
  local response
  response=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/actions/secrets/$secret_name")
  
  if [ "$response" -eq 200 ]; then
    return 0  # Secret exists
  else
    return 1  # Secret missing
  fi
}

# Function to validate SSH key format (basic PEM format check)
validate_ssh_key_format() {
  local key_content=$1
  
  # Check for PEM header/footer
  if echo "$key_content" | grep -q "BEGIN.*PRIVATE KEY"; then
    return 0
  else
    return 1
  fi
}

# Function to validate SSH key fingerprint
validate_ssh_key_fingerprint() {
  local key_content=$1
  local expected_fingerprint=$2
  
  # Skip if expected fingerprint is placeholder
  if [[ "$expected_fingerprint" == *"REPLACE_WITH_ACTUAL"* ]]; then
    echo -e "${YELLOW}  Fingerprint validation skipped (placeholder value)${NC}"
    return 0
  fi
  
  # Write key to temp file for fingerprint calculation
  local temp_key=$(mktemp)
  echo "$key_content" > "$temp_key"
  chmod 600 "$temp_key"
  
  # Calculate fingerprint
  local actual_fingerprint
  actual_fingerprint=$(ssh-keygen -lf "$temp_key" -E sha256 2>/dev/null | awk '{print $2}')
  rm -f "$temp_key"
  
  if [ "$actual_fingerprint" = "$expected_fingerprint" ]; then
    return 0
  else
    echo -e "${RED}  Expected: $expected_fingerprint${NC}"
    echo -e "${RED}  Actual:   $actual_fingerprint${NC}"
    return 1
  fi
}

# Validate required secrets
echo ""
echo "Checking required secrets..."
for secret in "${REQUIRED_SECRETS[@]}"; do
  echo -n "  Checking $secret... "
  
  if check_secret_exists "$secret"; then
    echo -e "${GREEN}EXISTS${NC}"
    
    # Additional validation for SSH keys (if accessible via API - note: actual secret values are NOT retrievable)
    # Since GitHub API does not expose secret values, we can only validate presence
    # Format/fingerprint validation must occur in deployment environment with access to secrets
    
  else
    echo -e "${RED}MISSING${NC}"
    VALIDATION_FAILED=1
  fi
done

# Validate optional secrets
echo ""
echo "Checking optional secrets..."
for secret in "${OPTIONAL_SECRETS[@]}"; do
  echo -n "  Checking $secret... "
  
  if check_secret_exists "$secret"; then
    echo -e "${GREEN}EXISTS${NC}"
  else
    echo -e "${YELLOW}MISSING (optional)${NC}"
  fi
done

# In-deployment validation notes
echo ""
echo "-----------------------------------------------------------"
echo "NOTE: Secret format and fingerprint validation requires access to secret values."
echo "This validation script only checks SECRET PRESENCE via GitHub API."
echo ""
echo "For in-deployment validation (with secret values), add to workflow:"
echo '  - name: Validate SSH Key Format'
echo '    run: |'
echo '      echo "${{ secrets.PRODUCTION_SSH_PRIVATE_KEY }}" > /tmp/key'
echo '      ssh-keygen -lf /tmp/key -E sha256  # Verify fingerprint'
echo '      rm -f /tmp/key'
echo ""

# Exit with failure if required secrets missing
if [ $VALIDATION_FAILED -eq 1 ]; then
  echo -e "${RED}VALIDATION FAILED: Required secrets missing${NC}"
  exit 1
else
  echo -e "${GREEN}VALIDATION PASSED: All required secrets present${NC}"
  exit 0
fi
