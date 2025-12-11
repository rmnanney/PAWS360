#!/bin/bash
# T041a: Provision GitHub Actions Runner on Staging
# Purpose: Deploy runner to dell-r640-01 with monitoring
# Usage: ./deploy-staging-runner.sh
# JIRA: INFRA-473

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INVENTORY="infrastructure/ansible/inventories/staging/hosts"
GITHUB_ORG="rmnanney"
GITHUB_REPO="PAWS360"
RUNNER_LABELS="self-hosted,staging,primary"
ENVIRONMENT="staging"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}T041a: Provision Staging Runner${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "Target: dell-r640-01 (from Ansible inventory)"
echo -e "Environment: ${ENVIRONMENT}"
echo -e "Labels: ${RUNNER_LABELS}"
echo ""

# Step 1: Validate prerequisites
echo -e "${YELLOW}📋 Step 1: Validating prerequisites...${NC}"

if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}❌ Inventory file not found: $INVENTORY${NC}"
    exit 1
fi

if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}❌ ansible-playbook not found. Please install Ansible.${NC}"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found. You'll need to manually generate registration token.${NC}"
    GH_AVAILABLE=false
else
    GH_AVAILABLE=true
fi

echo -e "${GREEN}✅ Prerequisites validated${NC}"
echo ""

# Step 2: Check Ansible connectivity
echo -e "${YELLOW}📋 Step 2: Testing Ansible connectivity...${NC}"

if ansible webservers -i "$INVENTORY" -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ansible connectivity verified${NC}"
else
    echo -e "${RED}❌ Cannot reach staging host. Check SSH access and inventory configuration.${NC}"
    exit 1
fi
echo ""

# Step 3: Provision runner software
echo -e "${YELLOW}📋 Step 3: Provisioning runner software...${NC}"

ansible-playbook -i "$INVENTORY" \
    infrastructure/ansible/playbooks/provision-github-runner.yml \
    -e "runner_custom_labels=$RUNNER_LABELS" \
    -e "github_org=$GITHUB_ORG" \
    -e "github_repo=$GITHUB_REPO"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Runner software provisioned${NC}"
else
    echo -e "${RED}❌ Runner provisioning failed${NC}"
    exit 1
fi
echo ""

# Step 4: Generate registration token
echo -e "${YELLOW}📋 Step 4: Generating runner registration token...${NC}"

if [ "$GH_AVAILABLE" = true ]; then
    echo -e "Attempting to generate token with GitHub CLI..."
    
    TOKEN_RESPONSE=$(gh api --method POST \
        -H "Accept: application/vnd.github+json" \
        /repos/$GITHUB_ORG/$GITHUB_REPO/actions/runners/registration-token 2>&1)
    
    if [ $? -eq 0 ]; then
        REGISTRATION_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.token')
        echo -e "${GREEN}✅ Registration token generated${NC}"
        echo ""
        
        # Step 5: Register runner
        echo -e "${YELLOW}📋 Step 5: Registering runner with GitHub...${NC}"
        
        ansible webservers -i "$INVENTORY" \
            -m shell \
            -a "su - actions-runner -c '/opt/actions-runner/register-runner.sh $REGISTRATION_TOKEN'" \
            -b
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Runner registered successfully${NC}"
        else
            echo -e "${RED}❌ Runner registration failed${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  Could not generate token automatically${NC}"
        echo -e "Please generate manually and register the runner:"
        echo ""
        echo -e "  1. Generate token:"
        echo -e "     gh api --method POST -H 'Accept: application/vnd.github+json' \\"
        echo -e "       /repos/$GITHUB_ORG/$GITHUB_REPO/actions/runners/registration-token"
        echo ""
        echo -e "  2. SSH to dell-r640-01:"
        echo -e "     ssh dell-r640-01"
        echo ""
        echo -e "  3. Register runner:"
        echo -e "     sudo su - actions-runner"
        echo -e "     /opt/actions-runner/register-runner.sh <TOKEN>"
        echo ""
        echo -e "${YELLOW}Press Enter when registration is complete...${NC}"
        read
    fi
else
    echo -e "${YELLOW}⚠️  Manual registration required${NC}"
    echo ""
    echo -e "Generate token and register runner manually:"
    echo -e "  1. Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/actions/runners/new"
    echo -e "  2. Copy the registration token"
    echo -e "  3. SSH to dell-r640-01 and run:"
    echo -e "     sudo su - actions-runner"
    echo -e "     /opt/actions-runner/register-runner.sh <TOKEN>"
    echo ""
    echo -e "${YELLOW}Press Enter when registration is complete...${NC}"
    read
fi
echo ""

# Step 6: Deploy runner-exporter
echo -e "${YELLOW}📋 Step 6: Deploying runner-exporter for monitoring...${NC}"

ansible-playbook -i "$INVENTORY" \
    infrastructure/ansible/playbooks/deploy-runner-exporter.yml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Runner exporter deployed${NC}"
else
    echo -e "${RED}❌ Exporter deployment failed${NC}"
    exit 1
fi
echo ""

# Step 7: Validate deployment
echo -e "${YELLOW}📋 Step 7: Validating deployment...${NC}"

# Check runner service
echo -e "Checking runner service status..."
ansible webservers -i "$INVENTORY" \
    -m shell \
    -a "systemctl status actions.runner.*.service | grep 'Active:'" \
    -b

# Check exporter endpoint
echo -e "Checking exporter endpoint..."
STAGING_HOST=$(ansible webservers -i "$INVENTORY" --list-hosts | tail -n1 | tr -d ' ')
if curl -s "http://$STAGING_HOST:9100/metrics" | grep -q "runner_status"; then
    echo -e "${GREEN}✅ Exporter endpoint responding${NC}"
else
    echo -e "${YELLOW}⚠️  Exporter endpoint not responding${NC}"
fi
echo ""

# Final status
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}✅ T041a: Staging Runner Deployment Complete${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "Deployment Summary:"
echo -e "  • Host: dell-r640-01 (from Ansible inventory)"
echo -e "  • Runner Labels: $RUNNER_LABELS"
echo -e "  • Exporter Port: 9100"
echo -e "  • Environment: $ENVIRONMENT"
echo ""
echo -e "Verification:"
echo -e "  • GitHub: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/actions/runners"
echo -e "  • Metrics: http://\$STAGING_HOST:9100/metrics"
echo -e "  • Service: ssh dell-r640-01 'systemctl status actions.runner.*.service'"
echo ""
echo -e "Next Steps:"
echo -e "  • T041b: Deploy monitoring (Prometheus scrape config, Grafana dashboard)"
echo -e "  • T042: Execute LIVE staging tests"
echo ""
echo -e "${BLUE}================================================${NC}"
