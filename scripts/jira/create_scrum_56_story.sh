#!/bin/bash

# Create SCRUM-56: Academic Module Implementation Story
# Implements the core academic functionality for PAWS360

JIRA_URL="https://paw360.atlassian.net"
AUTH_HEADER="Authorization: Basic cm1uYW5uZXlAdXdtLmVkdTpBVEFUVDN4RmZHRjBxTWNuT1kzWjV1c010S0l4UTE2ZzZmMzZoVUZHOFRFRVlsRmVhNUgxd0ozN1ZpZ0toMS15YVVzNEV5eEZ0VmozQmx0S2FwWWJVa1E0V0lRT1dlMlNrTmYxRW1mX0V3R0cyX05BVHR1UHMwMDdyRlFnZnp5QzBRdmVNel95TmVDSF9ZcEpHWE02NnJXODVUU EV5cXhGT25ra0pMOEN5ZTZ5UERmNWpmUDJjVWc9RUI0QzEyN0I=="

echo "🚀 Creating SCRUM-56: Academic Module Implementation Story"
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

# Create Academic Module Story
echo "📚 Creating Academic Module Implementation Story..."

STORY_SUMMARY="SCRUM-56: Academic Module Implementation - Grades, Transcripts & Academic Records"
STORY_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "📚 Academic Module Implementation Story", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a student, I want to access my academic information so that I can view my grades, transcripts, and academic records in one place.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📋 Acceptance Criteria", "type": "text" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Core Functionality", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Current semester grades display with real-time updates", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Complete academic transcript view with all semesters", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ GPA calculation and display (cumulative and semester)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Course history with enrollment dates and completion status", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Academic standing indicators (Good Standing, Probation, etc.)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Grade point distribution visualization", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Download/print transcript functionality", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Database Integration", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Student enrollment records properly queried", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Grade data accurately retrieved from database", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Course catalog integration for course details", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Academic program requirements tracking", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ FERPA compliance for sensitive academic data", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "User Interface", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Responsive design for mobile and desktop", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Intuitive navigation between different academic views", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Clear grade visualization with color coding", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Search and filter capabilities for course history", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Export functionality for transcripts and grade reports", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🏗️ Technical Implementation Tasks", "type": "text" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Backend Development", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create academic data models and database queries", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement GPA calculation algorithms", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Develop transcript generation logic", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up API endpoints for academic data", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement data caching for performance", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Frontend Implementation", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Design academic dashboard layout", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create grade display components", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement transcript viewer", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Build GPA visualization charts", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Develop search and filter functionality", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Database Integration", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Connect to student enrollment tables", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Integrate with course catalog data", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement grade data retrieval", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up academic program tracking", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Configure database indexing for performance", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📊 Success Metrics", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Data Accuracy: 100% match with official university records", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Performance: < 2 second load time for transcript views", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "User Satisfaction: > 90% positive feedback on usability", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "FERPA Compliance: Zero security incidents", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Availability: 99.9% uptime for academic module", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🔗 Dependencies", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "SCRUM-55 Production Deployment Setup (infrastructure ready)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Database schema and seed data (from previous sprints)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Authentication system (login functionality)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "UI component library (existing components)", "type": "text" }]
            }
          ]
        }
      ]
    }
  ]
}'

PAYLOAD='{
  "fields": {
    "project": {
      "key": "PGB"
    },
    "summary": "'"$STORY_SUMMARY"'",
    "description": '"$STORY_DESCRIPTION"',
    "issuetype": {
      "name": "Story"
    },
    "assignee": {
      "name": "rmnanney@uwm.edu"
    },
    "labels": [
      "academic-module",
      "grades",
      "transcripts",
      "gpa-calculation",
      "student-records",
      "database-integration",
      "ferpa-compliance",
      "user-interface"
    ]
  }
}'

RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q '"key":'; then
    STORY_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created Academic Module Story $STORY_KEY"
else
    echo "❌ FAILED: Could not create Academic Module Story"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "========================================"
echo "🎉 SCRUM-56 Story Creation Complete!"
echo ""
echo "📋 Story Details:"
echo "✅ Story Key: $STORY_KEY"
echo "✅ Summary: $STORY_SUMMARY"
echo "✅ Assignee: Ryan Nanney (rmnanney@uwm.edu)"
echo ""
echo "🔗 Story URL:"
echo "https://paw360.atlassian.net/browse/$STORY_KEY"
echo ""
echo "📝 Labels Applied:"
echo "• academic-module, grades, transcripts"
echo "• gpa-calculation, student-records"
echo "• database-integration, ferpa-compliance"
echo "• user-interface"
echo ""
echo "🎯 Story ready for sprint planning and implementation!"
echo "Next steps: Add to current sprint and begin academic module development."
echo ""
echo "📚 This story implements the core academic functionality that students"
echo "will use most frequently - grades, transcripts, and GPA tracking."