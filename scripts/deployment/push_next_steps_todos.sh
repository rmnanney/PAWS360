#!/bin/bash

JIRA_URL="https://paw360.atlassian.net"
PROJECT_KEY="PGB"
EMAIL="rmnanney@uwm.edu"
API_TOKEN="ATATT3xFfGF0qMcnOY3Z5usMtKIxQ16g6f36hUFG8TEEYlFea5H1wJ37VigKh1-yaUs4EyxFtVj3BltKapYbUkQ4WIQOWe2SkNf1Emf_EwGG2_NATtuPs007rFQgfzyC0QveMz_yNeCH_YpJGXM66rW85TPEyqxFOnkkJL8Cye6yPDf5jfP2cUg=EB4C127B"

echo "🚀 Starting JIRA Todo Import from next_steps_todos_simple.csv"
echo "Project: $PROJECT_KEY"
echo "JIRA URL: $JIRA_URL"
echo "========================================"

# Counter for successful/failed imports
SUCCESS_COUNT=0
FAIL_COUNT=0

# Skip header row, then read CSV
tail -n +2 next_steps_todos_simple.csv | while IFS=, read -r summary issuetype description priority labels assignee
do
  echo ""
  echo "📝 Creating: $summary"
  echo "   Type: $issuetype"

  # Create JSON payload
  JSON_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "project": {
      "key": "$PROJECT_KEY"
    },
    "summary": "$summary",
    "description": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "$description"
            }
          ]
        }
      ]
    },
    "issuetype": {
      "name": "$issuetype"
    },
    "labels": ["$labels"]
  }
}
EOF
)

  # Make the API call
  RESPONSE=$(curl -s -X POST \
    -u "$EMAIL:$API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data "$JSON_PAYLOAD" \
    "$JIRA_URL/rest/api/3/issue")

  # Check if successful
  if echo "$RESPONSE" | grep -q '"key":'; then
    ISSUE_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created JIRA issue $ISSUE_KEY"
    ((SUCCESS_COUNT++))
  else
    echo "❌ FAILED: $RESPONSE"
    ((FAIL_COUNT++))
  fi

  # Small delay to respect rate limits
  sleep 1
done

echo ""
echo "========================================"
echo "🎉 Import Complete!"
echo "✅ Successful: $SUCCESS_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo "📊 Total: $((SUCCESS_COUNT + FAIL_COUNT))"