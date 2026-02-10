#!/bin/bash

# JIRA Work Item Reordering Script
# Uses JIRA REST API to reorder tasks/stories by logical operational order

JIRA_URL="https://paw360.atlassian.net"
PROJECT_KEY="PGB"
EMAIL="rmnanney@uwm.edu"
API_TOKEN="ATATT3xFfGF0qMcnOY3Z5usMtKIxQ16g6f36hUFG8TEEYlFea5H1wJ37VigKh1-yaUs4EyxFtVj3BltKapYbUkQ4WIQOWe2SkNf1Emf_EwGG2_NATtuPs007rFQgfzyC0QveMz_yNeCH_YpJGXM66rW85TPEyqxFOnkkJL8Cye6yPDf5jfP2cUg=EB4C127B"

echo "🚀 JIRA Work Item Reordering by Logical Operational Order"
echo "Project: $PROJECT_KEY"
echo "========================================"

# Get all work items (Stories and Tasks)
echo "🔍 Fetching all work items..."
WORK_ITEMS=$(curl -s -X GET \
  -u "$EMAIL:$API_TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_URL/rest/api/3/search?jql=project=$PROJECT_KEY+AND+(issuetype=Story+OR+issuetype=Task)&fields=key,summary,description,issuetype,status&maxResults=100")

# Extract total count
TOTAL=$(echo "$WORK_ITEMS" | grep -o '"total":[0-9]*' | cut -d':' -f2)
echo "📊 Found $TOTAL work items"

if [ "$TOTAL" -eq 0 ]; then
    echo "❌ No work items found to reorder"
    exit 1
fi

# Extract issues array
ISSUES=$(echo "$WORK_ITEMS" | sed -n 's/.*"issues":\[\(.*\)\].*/\1/p' | sed 's/},/}/g')

echo ""
echo "📋 Current Work Items:"
echo "======================"

# Parse and display current items
echo "$WORK_ITEMS" | jq -r '.issues[] | "\(.key): \(.fields.summary)"' 2>/dev/null || echo "Using fallback parsing..."

# For fallback parsing without jq
if ! command -v jq &> /dev/null; then
    echo "$WORK_ITEMS" | grep -o '"key":"[^"]*"' | sed 's/"key":"//g' | sed 's/"//g' | while read -r key; do
        summary=$(echo "$WORK_ITEMS" | grep -A 5 "\"key\":\"$key\"" | grep '"summary"' | head -1 | sed 's/.*"summary":"//g' | sed 's/".*//g')
        echo "$key: $summary"
    done
fi

echo ""
echo "🔄 Determining Logical Operational Order..."
echo "==========================================="

# Define logical order based on operational dependencies
# Phase 1: Foundation (Database & Infrastructure)
declare -a PHASE1=("Database Schema Implementation" "Seed Data Population")

# Phase 2: Security & Authentication
declare -a PHASE2=("Authentication Framework Setup")

# Phase 3: User Interface & Frontend
declare -a PHASE3=("AdminLTE Dashboard Integration")

# Phase 4: System Integration
declare -a PHASE4=("PeopleSoft Integration")

# Phase 5: Testing & Validation
declare -a PHASE5=("Comprehensive Testing" "Performance Validation")

# Phase 6: Operations & Maintenance
declare -a PHASE6=("Monitoring & Alerting Setup" "Documentation Updates" "CI/CD Pipeline Configuration")

# Combine all phases
ORDERED_SUMMARIES=("${PHASE1[@]}" "${PHASE2[@]}" "${PHASE3[@]}" "${PHASE4[@]}" "${PHASE5[@]}" "${PHASE6[@]}")

echo "📋 Logical Operational Order:"
echo "=============================="
COUNTER=1
for summary in "${ORDERED_SUMMARIES[@]}"; do
    printf "%2d. %s\n" $COUNTER "$summary"
    ((COUNTER++))
done

echo ""
echo "⚡ Starting Reordering Process..."
echo "================================="

# Get all issue keys and summaries for reordering
ISSUE_DATA=$(echo "$WORK_ITEMS" | jq -r '.issues[] | "\(.key)|\(.fields.summary)"' 2>/dev/null)

if [ -z "$ISSUE_DATA" ]; then
    # Fallback parsing without jq
    ISSUE_DATA=""
    while IFS= read -r line; do
        key=$(echo "$line" | grep -o '"key":"[^"]*"' | sed 's/"key":"//g' | sed 's/"//g')
        summary=$(echo "$line" | grep -o '"summary":"[^"]*"' | sed 's/"summary":"//g' | sed 's/"//g')
        if [ -n "$key" ] && [ -n "$summary" ]; then
            ISSUE_DATA="$ISSUE_DATA$key|$summary\n"
        fi
    done <<< "$WORK_ITEMS"
fi

SUCCESS_COUNT=0
TOTAL_COUNT=0

# Process each work item for reordering
while IFS='|' read -r issue_key current_summary; do
    if [ -z "$issue_key" ] || [ -z "$current_summary" ]; then
        continue
    fi

    ((TOTAL_COUNT++))

    # Find the logical position for this item
    POSITION=1
    NEW_SUMMARY="$current_summary"

    for ordered_summary in "${ORDERED_SUMMARIES[@]}"; do
        if [[ "$current_summary" == *"$ordered_summary"* ]]; then
            NEW_SUMMARY=$(printf "[%02d] %s" $POSITION "$current_summary")
            break
        fi
        ((POSITION++))
    done

    # Skip if no change needed
    if [ "$NEW_SUMMARY" = "$current_summary" ]; then
        echo "⏭️  $issue_key: No reordering needed"
        continue
    fi

    echo "🔄 Updating $issue_key: $current_summary"
    echo "   → $NEW_SUMMARY"

    # Update the issue with new summary
    UPDATE_RESPONSE=$(curl -s -X PUT \
      -u "$EMAIL:$API_TOKEN" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data "{\"fields\":{\"summary\":\"$NEW_SUMMARY\"}}" \
      "$JIRA_URL/rest/api/3/issue/$issue_key")

    # Check if update was successful (empty response = success for JIRA API)
    if [ -z "$UPDATE_RESPONSE" ] || echo "$UPDATE_RESPONSE" | grep -q '"key":'; then
        echo "   ✅ SUCCESS"
        ((SUCCESS_COUNT++))
    else
        echo "   ❌ FAILED: $UPDATE_RESPONSE"
    fi

    # Small delay to respect rate limits
    sleep 1

done <<< "$ISSUE_DATA"

echo ""
echo "========================================"
echo "🎉 Reordering Complete!"
echo "✅ Successfully updated: $SUCCESS_COUNT"
echo "📊 Total processed: $TOTAL_COUNT"
echo ""
echo "📋 Check JIRA to see the new logical operational sequence with [01], [02], etc. prefixes!"