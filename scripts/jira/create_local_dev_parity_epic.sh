#!/bin/bash
# Create JIRA Epic and Stories for 001-local-dev-parity
# Feature: Local Development HA Environment

set -e

JIRA_BASE_URL="${JIRA_BASE_URL:-https://ryannanney.atlassian.net}"
JIRA_EMAIL="${JIRA_EMAIL}"
JIRA_API_TOKEN="${JIRA_API_TOKEN}"
PROJECT_KEY="SCRUM"

# Validate environment
if [[ -z "$JIRA_EMAIL" || -z "$JIRA_API_TOKEN" ]]; then
    echo "❌ JIRA credentials not set. Please set JIRA_EMAIL and JIRA_API_TOKEN"
    exit 1
fi

AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)

echo "🚀 Creating JIRA Epic for 001-local-dev-parity"
echo "Project: $PROJECT_KEY"
echo "URL: $JIRA_BASE_URL"
echo "========================================"

# Test API connectivity
echo "🔍 Testing API connectivity..."
TEST_RESPONSE=$(curl -s -X GET "$JIRA_BASE_URL/rest/api/3/myself" \
    -H "Authorization: Basic $AUTH" \
    -H "Content-Type: application/json")

if echo "$TEST_RESPONSE" | grep -q '"accountId"'; then
    ACCOUNT_ID=$(echo "$TEST_RESPONSE" | jq -r '.accountId')
    echo "✅ API connection successful (Account: $ACCOUNT_ID)"
else
    echo "❌ API connection failed"
    echo "Response: $TEST_RESPONSE"
    exit 1
fi

echo ""

# Create Epic
echo "📋 Creating Epic: Local Development HA Environment..."

EPIC_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "🏗️ Local Development HA Environment", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "Epic for implementing a production-parity local development environment with High Availability infrastructure using Docker Compose.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📊 Epic Summary", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Feature ID: 001-local-dev-parity", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Total Tasks: 381", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Completed: 348 (91%)", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Branch: 001-local-dev-parity", "type": "text" }] }]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🎯 Business Value", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [{ "text": "Provide developers with a local environment that mirrors production HA infrastructure, enabling:", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "✅ Reliable local testing of failover scenarios", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "✅ Consistent database behavior across environments", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "✅ Reduced production incidents from environment drift", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "✅ Faster developer onboarding", "type": "text" }] }]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🏛️ Infrastructure Components", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "3-node etcd cluster (distributed consensus)", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "3-node Patroni PostgreSQL cluster (automatic failover)", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Redis master + 2 replicas", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "3-node Redis Sentinel (automatic promotion)", "type": "text" }] }]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📚 Documentation", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "specs/001-local-dev-parity/spec.md - Feature specification", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "specs/001-local-dev-parity/tasks.md - Task tracking", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "docs/quickstart.sh - Automated setup script", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "docs/local-development/ - Developer guides", "type": "text" }] }]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "✅ Acceptance Criteria", "type": "text" }]
    },
    {
      "type": "orderedList",
      "content": [
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "All 12 infrastructure services start and become healthy", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Patroni failover completes in <60 seconds", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Redis Sentinel failover completes in <30 seconds", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Full environment starts in <5 minutes", "type": "text" }] }]
        },
        {
          "type": "listItem",
          "content": [{ "type": "paragraph", "content": [{ "text": "Documentation complete and tested", "type": "text" }] }]
        }
      ]
    }
  ]
}'

EPIC_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "project": { "key": "$PROJECT_KEY" },
    "summary": "001-local-dev-parity: Local Development HA Environment",
    "description": $EPIC_DESCRIPTION,
    "issuetype": { "name": "Epic" },
    "labels": ["infrastructure", "local-dev", "ha", "docker"]
  }
}
EOF
)

EPIC_RESPONSE=$(curl -s -X POST "$JIRA_BASE_URL/rest/api/3/issue" \
    -H "Authorization: Basic $AUTH" \
    -H "Content-Type: application/json" \
    -d "$EPIC_PAYLOAD")

EPIC_KEY=$(echo "$EPIC_RESPONSE" | jq -r '.key // empty')

if [[ -n "$EPIC_KEY" ]]; then
    echo "✅ Epic created: $EPIC_KEY"
    echo "   URL: $JIRA_BASE_URL/browse/$EPIC_KEY"
else
    echo "❌ Failed to create Epic"
    echo "Response: $EPIC_RESPONSE"
    exit 1
fi

echo ""
echo "========================================"
echo "📝 Creating User Stories linked to Epic..."
echo ""

# Function to create a story
create_story() {
    local STORY_NUM="$1"
    local SUMMARY="$2"
    local DESCRIPTION="$3"
    local STORY_POINTS="$4"
    
    local STORY_PAYLOAD=$(cat <<EOF
{
  "fields": {
    "project": { "key": "$PROJECT_KEY" },
    "summary": "$SUMMARY",
    "description": $DESCRIPTION,
    "issuetype": { "name": "Story" },
    "parent": { "key": "$EPIC_KEY" },
    "labels": ["001-local-dev-parity"]
  }
}
EOF
)

    local RESPONSE=$(curl -s -X POST "$JIRA_BASE_URL/rest/api/3/issue" \
        -H "Authorization: Basic $AUTH" \
        -H "Content-Type: application/json" \
        -d "$STORY_PAYLOAD")
    
    local STORY_KEY=$(echo "$RESPONSE" | jq -r '.key // empty')
    
    if [[ -n "$STORY_KEY" ]]; then
        echo "✅ Story $STORY_NUM: $STORY_KEY - $SUMMARY"
    else
        echo "⚠️ Story $STORY_NUM failed: $(echo "$RESPONSE" | jq -r '.errors // .errorMessages // "Unknown error"')"
    fi
}

# US1: Full Stack Local Environment
US1_DESC='{
  "type": "doc",
  "version": 1,
  "content": [
    {"type": "paragraph", "content": [{"text": "As a developer, I want a single command to start a full-stack local environment with all services (DB, cache, backend, frontend) so that I can develop and test features locally.", "type": "text"}]},
    {"type": "heading", "attrs": {"level": 3}, "content": [{"text": "Acceptance Criteria", "type": "text"}]},
    {"type": "bulletList", "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "make dev-up starts all services", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "make dev-down stops all services cleanly", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Services recover from host sleep/hibernate", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Environment starts in <5 minutes", "type": "text"}]}]}
    ]}
  ]
}'
create_story "US1" "US1: Full Stack Local Environment" "$US1_DESC" "8"

# US2: CI/CD Pipeline Parity
US2_DESC='{
  "type": "doc",
  "version": 1,
  "content": [
    {"type": "paragraph", "content": [{"text": "As a developer, I want to run CI checks locally before pushing so that I can catch issues early and reduce PR cycle time.", "type": "text"}]},
    {"type": "heading", "attrs": {"level": 3}, "content": [{"text": "Acceptance Criteria", "type": "text"}]},
    {"type": "bulletList", "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "make ci runs same checks as GitHub Actions", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Results match remote CI within tolerance", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Can run individual CI stages locally", "type": "text"}]}]}
    ]}
  ]
}'
create_story "US2" "US2: CI/CD Pipeline Parity" "$US2_DESC" "5"

# US3: Rapid Development Iteration
US3_DESC='{
  "type": "doc",
  "version": 1,
  "content": [
    {"type": "paragraph", "content": [{"text": "As a developer, I want instant feedback on code changes without full rebuilds so that I can iterate quickly during development.", "type": "text"}]},
    {"type": "heading", "attrs": {"level": 3}, "content": [{"text": "Acceptance Criteria", "type": "text"}]},
    {"type": "bulletList", "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Backend hot-reload in <2 seconds", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Frontend HMR instant updates", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Incremental rebuilds in <30 seconds", "type": "text"}]}]}
    ]}
  ]
}'
create_story "US3" "US3: Rapid Development Iteration" "$US3_DESC" "5"

# US4: Environment Parity Validation
US4_DESC='{
  "type": "doc",
  "version": 1,
  "content": [
    {"type": "paragraph", "content": [{"text": "As a developer, I want to verify my local environment matches production configuration so that I can catch environment-specific bugs before deployment.", "type": "text"}]},
    {"type": "heading", "attrs": {"level": 3}, "content": [{"text": "Acceptance Criteria", "type": "text"}]},
    {"type": "bulletList", "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "make validate-parity compares local vs production config", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Drift detection reports differences", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Database schema validation", "type": "text"}]}]}
    ]}
  ]
}'
create_story "US4" "US4: Environment Parity Validation" "$US4_DESC" "3"

# US5: Debugging & Troubleshooting
US5_DESC='{
  "type": "doc",
  "version": 1,
  "content": [
    {"type": "paragraph", "content": [{"text": "As a developer, I want easy access to service logs, metrics, and debugging tools so that I can quickly diagnose and fix issues.", "type": "text"}]},
    {"type": "heading", "attrs": {"level": 3}, "content": [{"text": "Acceptance Criteria", "type": "text"}]},
    {"type": "bulletList", "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "make logs aggregates all service logs", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "make health shows service status", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Database shell access via make db-shell", "type": "text"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"text": "Comprehensive troubleshooting guide", "type": "text"}]}]}
    ]}
  ]
}'
create_story "US5" "US5: Debugging & Troubleshooting" "$US5_DESC" "3"

echo ""
echo "========================================"
echo "✅ JIRA Epic and Stories Created!"
echo ""
echo "Epic: $EPIC_KEY"
echo "URL: $JIRA_BASE_URL/browse/$EPIC_KEY"
echo ""
echo "Next steps:"
echo "1. Review stories at $JIRA_BASE_URL/browse/$EPIC_KEY"
echo "2. Assign story points and sprints"
echo "3. Attach gpt-context.md to epic"
echo "========================================"
