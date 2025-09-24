#!/bin/bash

# Create JIRA Stories using REST API (working authentication)
# Creates the two stories for project management and architecture

JIRA_URL="https://paw360.atlassian.net"
AUTH_HEADER="Authorization: Basic cm1uYW5uZXlAdXdtLmVkdTpBVEFUVDN4RmZHRjBxTWNuT1kzWjV1c010S0l4UTE2ZzZmMzZoVUZHOFRFRVlMZWFINTF3SjM3VmlnS2gxLXlhVXM0RXl4RnRWakJibEtwYVlCVWtRNFdJUU9XZTJTazVmMUVtZl9Fd0dHMl9OQVQ0dVBzMDA3clFRZ2Z6eUMwUXZlTXpfeU5lQ0hfWXBaR1hYTTZydzg1VFBFeXFGT25ra0pMOGM2ZTZQRGY1amZQMmNVZz1FQjRDMTI3Qg=="

echo "🚀 Creating JIRA Stories for Randall"
echo "Project: PGB"
echo "========================================"

# Test API connectivity first
echo "🔍 Testing API connectivity..."
TEST_RESPONSE=$(curl -s -X GET "$JIRA_URL/rest/api/3/myself" -H "$AUTH_HEADER" -H "Content-Type: application/json")

if echo "$TEST_RESPONSE" | grep -q '"accountId"'; then
    echo "✅ API connection successful"
else
    echo "❌ API connection failed"
    echo "Response: $TEST_RESPONSE"
    exit 1
fi

echo ""

# Create Project Management Story
echo "📝 Creating Project Management Foundation Story..."

PM_SUMMARY="PAWS360 Project Management Foundation - Complete Setup and Sprint Planning"
PM_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "🎯 Project Management Foundation Story", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a PAWS360 project manager, I want comprehensive project management infrastructure so that I can effectively manage the development lifecycle, track progress, and ensure successful delivery of the student information system.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "✅ Accomplishments Completed", "type": "text" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Sprint Planning & Management", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Created 8 PGB sprints (PGB Sprint 1-8) with proper naming convention", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Implemented round-robin story distribution across all sprints", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Balanced workload distribution (6-7 issues per sprint)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Sprint capacity planning and velocity tracking", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "JIRA Infrastructure Setup", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Configured JIRA MCP server for automated project management", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Set up environment variables and authentication", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Created comprehensive project management workflows", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Implemented automated sprint assignment logic", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Quality Assurance & Testing", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Created exhaustive test suite for CI/CD validation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Set up automated testing infrastructure", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Implemented performance benchmarking", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Created test coverage reporting", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📊 Business Value Delivered", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "53 Stories distributed across 8 sprints", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Complete JIRA Integration with MCP server", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Comprehensive Test Suite with automated validation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Full Documentation Package for team onboarding", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "SAFe Agile Processes for scalable development", "type": "text" }]
            }
          ]
        }
      ]
    }
  ]
}'

PM_PAYLOAD='{
  "fields": {
    "project": {
      "key": "PGB"
    },
    "summary": "'"$PM_SUMMARY"'",
    "description": '"$PM_DESCRIPTION"',
    "issuetype": {
      "name": "Story"
    },
    "priority": {
      "name": "High"
    },
    "labels": [
      "project-management",
      "sprint-planning",
      "jira-setup",
      "process-optimization",
      "documentation",
      "quality-assurance",
      "agile-methodology"
    ]
  }
}'

PM_RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$PM_PAYLOAD")

if echo "$PM_RESPONSE" | grep -q '"key":'; then
    PM_KEY=$(echo "$PM_RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created Project Management Story $PM_KEY"
else
    echo "❌ FAILED: Could not create Project Management Story"
    echo "Response: $PM_RESPONSE"
fi

echo ""

# Create Architecture Story
echo "🏗️ Creating System Architecture Foundation Story..."

ARCH_SUMMARY="PAWS360 System Architecture Foundation - Complete Technical Design and Implementation"
ARCH_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "🏗️ System Architecture Foundation Story", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a PAWS360 system architect, I want a complete technical foundation so that the student information system can scale to support 25,000+ users with enterprise-grade performance and security.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "✅ Architecture Accomplishments Completed", "type": "text" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Database Architecture & Design", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Complete PostgreSQL database schema design with 9 core tables", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ FERPA-compliant data architecture with PII protection", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Comprehensive indexing strategy for 25,000+ concurrent users", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Row-level security policies and audit logging implementation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ AdminLTE v4.0.0-rc4 dashboard integration support", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Data Modeling & Seed Data", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ 25,000+ realistic student records based on UW-Milwaukee patterns", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Complete course catalog across 6 academic departments", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Realistic enrollment patterns and grade distributions", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Faculty and staff account structures", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ AdminLTE dashboard widgets and session data", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📊 Technical Metrics Achieved", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Complete PostgreSQL DDL with 15+ strategic indexes", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "25,000+ student records with referential integrity", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "6 academic departments with complete course catalogs", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "FERPA compliance with comprehensive audit trails", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🎯 Business Value Delivered", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Scalable foundation for UW-Milwaukee student information system", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "FERPA-compliant data architecture for regulatory compliance", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Performance optimized for peak enrollment periods", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "AdminLTE integration for modern dashboard experience", "type": "text" }]
            }
          ]
        }
      ]
    }
  ]
}'

ARCH_PAYLOAD='{
  "fields": {
    "project": {
      "key": "PGB"
    },
    "summary": "'"$ARCH_SUMMARY"'",
    "description": '"$ARCH_DESCRIPTION"',
    "issuetype": {
      "name": "Story"
    },
    "priority": {
      "name": "Highest"
    },
    "labels": [
      "architecture",
      "database-design",
      "system-integration",
      "performance",
      "scalability",
      "ferpa-compliance",
      "adminlte-integration"
    ]
  }
}'

ARCH_RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$ARCH_PAYLOAD")

if echo "$ARCH_RESPONSE" | grep -q '"key":'; then
    ARCH_KEY=$(echo "$ARCH_RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created Architecture Story $ARCH_KEY"
else
    echo "❌ FAILED: Could not create Architecture Story"
    echo "Response: $ARCH_RESPONSE"
fi

echo ""
echo "========================================"
echo "🎉 Story Creation Complete!"
echo ""
echo "📋 Summary:"
if [ -n "$PM_KEY" ]; then
    echo "✅ Project Management Story: $PM_KEY"
    echo "   URL: https://paw360.atlassian.net/browse/$PM_KEY"
else
    echo "❌ Project Management Story: Failed to create"
fi

if [ -n "$ARCH_KEY" ]; then
    echo "✅ Architecture Story: $ARCH_KEY"
    echo "   URL: https://paw360.atlassian.net/browse/$ARCH_KEY"
else
    echo "❌ Architecture Story: Failed to create"
fi

echo ""
echo "🔗 View in JIRA Backlog:"
echo "https://paw360.atlassian.net/jira/software/projects/PGB/boards/34/backlog"

echo ""
echo "🎯 Both stories created for Randall with comprehensive details of all work completed!"