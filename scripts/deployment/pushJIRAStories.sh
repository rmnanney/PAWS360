#!/bin/bash

JIRA_URL="https://paw360.atlassian.net"
PROJECT_KEY="PGB"
EMAIL="rmnanney@uwm.edu"
API_TOKEN="ATATT3xFfGF0qMcnOY3Z5usMtKIxQ16g6f36hUFG8TEEYlFea5H1wJ37VigKh1-yaUs4EyxFtVj3BltKapYbUkQ4WIQOWe2SkNf1Emf_EwGG2_NATtuPs007rFQgfzyC0QveMz_yNeCH_YpJGXM66rW85TPEyqxFOnkkJL8Cye6yPDf5jfP2cUg=EB4C127B"

# Skip header row, then read CSV
tail -n +2 jira-user-stories-import.csv | while IFS=, read -r summary description issuetype
do
  curl -X POST \
    -u "$EMAIL:$API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data "{
      \"fields\": {
        \"project\": { \"key\": \"$PROJECT_KEY\" },
        \"summary\": \"$summary\",
        \"description\": \"$description\",
        \"issuetype\": { \"name\": \"$issuetype\" }
      }
    }" \
    "$JIRA_URL/rest/api/3/issue"
done
