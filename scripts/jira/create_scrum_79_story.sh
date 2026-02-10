#!/bin/bash

# Create SCRUM-79: AdminLTE Multi-Role Dashboard Story
# Implements comprehensive multi-role dashboard with full interactive features

JIRA_URL="https://paw360.atlassian.net"
AUTH_HEADER="Authorization: Basic cm1uYW5uZXlAdXdtLmVkdTpBVEFUVDN4RmZHRjBxTWNuT1kzWjV1c010S0l4UTE2ZzZmMzZoVUZHOFRFRVlsRmVhNUgxd0ozN1ZpZ0toMS15YVVzNEV5eEZ0VmozQmx0S2FwWWJVa1E0V0lRT1dlMlNrTmYxRW1mX0V3R0cyX05BVHR1UHMwMDdyRlFnZnp5QzBRdmVNel95TmVDSF9ZcEpHWE02NnJXODVUUEV5cXhGT25ra0pMOEN5ZTZ5UERmNWpmUDJjVWc9RUI0QzEyN0I="

echo "🚀 Creating SCRUM-79: Multi-Role AdminLTE Dashboard Story"
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

# Create AdminLTE Dashboard Story
echo "📊 Creating Multi-Role AdminLTE Dashboard Story..."

STORY_SUMMARY="SCRUM-79: Implement Multi-Role AdminLTE Dashboard with Full Interactive Features"
STORY_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "📊 Multi-Role AdminLTE Dashboard Story", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a PAWS360 administrator, instructor, student, or registrar, I want a unified AdminLTE dashboard with role-switching capabilities, so that I can access role-specific functionality and preview different user experiences from a single interface.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🎯 Business Value", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Unified Interface: Single dashboard for all administrative and preview functions", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Role Flexibility: Admins can switch between roles to preview student/instructor/registrar views", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Efficient Testing: UI tests validate all role-specific features in one application", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Scalability: Extensible architecture for adding new roles and features", "type": "text" }]
            }
          ]
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
      "content": [{ "text": "AC1: Role Navigation and Switching", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Role tabs (Admin, Student, Instructor, Registrar) are clickable", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Active tab is highlighted correctly", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Content area displays role-specific interface", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Role-specific navigation items appear in sidebar", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "AC2: Admin Role Functionality", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Class Creation & Management heading displayed", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Create New Class button opens modal dialog", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Modal form has fields: Class Code, Class Name, Credits, Semester", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Classes table displays data from /api/classes/ endpoint", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Table shows CS101, CS201, and MATH201 courses", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "AC3: Student Role Functionality", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Academic Planning heading displayed", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Course Registration section with search input (id=courseSearch)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Degree Progress section shows Credits Completed and GPA", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Data loaded from /api/student/planning/ endpoint", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "AC4: Instructor Role Functionality", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Course Management Dashboard heading displayed", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Create Assignment button present", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Statistics: Active Courses, Total Students, Assignments Due", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Course data loaded from /api/instructor/courses/ endpoint", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "AC5: Registrar Role Functionality", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Enrollment Management System heading displayed", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Bulk Student Enrollment section present", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Enrollment statistics and data tables displayed", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "AC6: System Status Tab", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ System tab with href=#system clickable", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Service health status indicators displayed", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Database, Redis, and API service status shown", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "AC7: API Error Handling", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Non-existent API endpoints return 404 status", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ User-friendly error messages displayed", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🧪 Test Coverage", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "All 17 Playwright tests must pass (tests/ui/tests/dashboard.spec.ts):",
          "type": "text"
        }
      ]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Role navigation tests (6 tests)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Admin role tests (3 tests)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Student role tests (2 tests)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Instructor role tests (2 tests)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Registrar role tests (2 tests)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ System status tests (2 tests)", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "🏗️ Technical Implementation", "type": "text" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Technology Stack", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Framework: AdminLTE 4.0.0 (Bootstrap 4 + jQuery)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "API Integration: RESTful endpoints with JSON responses", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "State Management: JavaScript object to track current role", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Dynamic Rendering: jQuery DOM manipulation", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Files to Create/Update", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "src/main/resources/static/index.html - Main dashboard (UPDATE)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "src/main/resources/static/js/dashboard.js - Role-switching logic (NEW)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "src/main/resources/static/css/custom.css - Custom styles (NEW - optional)", "type": "text" }]
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
              "content": [{ "text": "Test Pass Rate: 17/17 Playwright tests passing (100%)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Code Quality: No JavaScript console errors", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Performance: All API responses < 2 seconds", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Responsiveness: Mobile-friendly on all screen sizes", "type": "text" }]
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
              "content": [{ "text": "SCRUM-54: CI/CD Pipeline Setup (provides test infrastructure)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Mock API endpoints (MockApiController.java already implemented)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Static resource serving configured (WebConfig.java)", "type": "text" }]
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
    "customfield_10016": 13,
    "labels": [
      "adminlte",
      "multi-role-dashboard",
      "ui-testing",
      "playwright",
      "frontend",
      "api-integration",
      "test-driven-development"
    ]
  }
}'

RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q '"key":'; then
    STORY_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created Multi-Role Dashboard Story $STORY_KEY"
else
    echo "❌ FAILED: Could not create Multi-Role Dashboard Story"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "========================================"
echo "🎉 SCRUM-79 Story Creation Complete!"
echo ""
echo "📋 Story Details:"
echo "✅ Story Key: $STORY_KEY"
echo "✅ Story Points: 13"
echo "✅ Summary: $STORY_SUMMARY"
echo ""
echo "🔗 Story URL:"
echo "https://paw360.atlassian.net/browse/$STORY_KEY"
echo ""
echo "📝 Labels Applied:"
echo "• adminlte, multi-role-dashboard, ui-testing"
echo "• playwright, frontend, api-integration"
echo "• test-driven-development"
echo ""
echo "🧪 Test Requirements:"
echo "• 17 Playwright tests (tests/ui/tests/dashboard.spec.ts)"
echo "• All role-switching, API integration, and error handling"
echo ""
echo "🎯 Story ready for sprint planning and TDD implementation!"
echo "Next steps: Follow SCRUM-79-gpt-context.md for RED-GREEN-REFACTOR cycle."
echo ""
