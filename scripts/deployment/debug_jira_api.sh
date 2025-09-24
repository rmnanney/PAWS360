#!/bin/bash

# Debug script to test JIRA API calls

JIRA_URL="https://paw360.atlassian.net"
PROJECT_KEY="PGB"
EMAIL="rmnanney@uwm.edu"
API_TOKEN="ATATT3xFfGF0qMcnOY3Z5usMtKIxQ16g6f36hUFG8TEEYlFea5H1wJ37VigKh1-yaUs4EyxFtVj3BltKapYbUkQ4WIQOWe2SkNf1Emf_EwGG2_NATtuPs007rFQgfzyC0QveMz_yNeCH_YpJGXM66rW85TPEyqxFOnkkJL8Cye6yPDf5jfP2cUg=EB4C127B"

echo "🔧 Testing JIRA API connectivity..."

# Test 1: Get a specific issue
echo "Test 1: Getting issue PGB-63..."
RESPONSE=$(curl -s -X GET \
  -u "$EMAIL:$API_TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_URL/rest/api/3/issue/PGB-63")

if echo "$RESPONSE" | grep -q '"key":"PGB-63"'; then
    echo "✅ Test 1 PASSED: Can retrieve issue"
else
    echo "❌ Test 1 FAILED: Cannot retrieve issue"
    echo "Response: $RESPONSE"
fi

# Test 2: Update issue summary
echo ""
echo "Test 2: Updating issue summary..."
UPDATE_DATA='{"fields":{"summary":"[DEBUG] Database Schema Implementation"}}'

echo "Update data: $UPDATE_DATA"

RESPONSE=$(curl -s -X PUT \
  -u "$EMAIL:$API_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  --data "$UPDATE_DATA" \
  "$JIRA_URL/rest/api/3/issue/PGB-63")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q '"key":"PGB-63"'; then
    echo "✅ Test 2 PASSED: Can update issue"
else
    echo "❌ Test 2 FAILED: Cannot update issue"
fi

# Test 3: Check current summary
echo ""
echo "Test 3: Checking current summary..."
RESPONSE=$(curl -s -X GET \
  -u "$EMAIL:$API_TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_URL/rest/api/3/issue/PGB-63?fields=summary")

echo "Current summary response: $RESPONSE"

echo ""
echo "🔧 Debug complete!"