#!/bin/bash

# Create SCRUM-57: Advising Module Implementation Story
# Implements the academic advising functionality for PAWS360

JIRA_URL="https://paw360.atlassian.net"
AUTH_HEADER="Authorization: Basic cm1uYW5uZXlAdXdtLmVkdTpBVEFUVDN4RmZHRjBxTWNuT1kzWjV1c010S0l4UTE2ZzZmMzZoVUZHOFRFRVlsRmVhNUgxd0ozN1ZpZ0toMS15YVVzNEV5eEZ0VmozQmx0S2FwWWJVa1E0V0lRT1dlMlNrTmYxRW1mX0V3R0cyX05BVHR1UHMwMDdyRlFnZnp5QzBRdmVNel95TmVDSF9ZcEpHWE02NnJXODVUU EV5cXhGT25ra0pMOEN5ZTZ5UERmNWpmUDJjVWc9RUI0QzEyN0I=="

echo "🚀 Creating SCRUM-57: Advising Module Implementation Story"
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

# Create Advising Module Story
echo "🎓 Creating Advising Module Implementation Story..."

STORY_SUMMARY="SCRUM-57: Advising Module Implementation - Academic Advising & Degree Planning"
STORY_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "🎓 Advising Module Implementation Story", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a student, I want to access academic advising services so that I can meet with advisors, plan my academic journey, and get guidance on degree requirements.",
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
              "content": [{ "text": "✅ Schedule and manage advising appointments with available advisors", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ View degree audit and progress toward graduation requirements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Access academic planning tools and course recommendations", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Communicate with assigned academic advisor through messaging system", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ View advising history and appointment records", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Access academic resources and planning guides", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Receive notifications for important advising deadlines", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Appointment Management", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Online appointment scheduling with real-time availability", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Appointment rescheduling and cancellation capabilities", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Automated reminders for upcoming appointments", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Virtual meeting integration (Zoom/Teams links)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Appointment history and notes tracking", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Advisor feedback and rating system", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Degree Planning", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Interactive degree audit showing completed and remaining requirements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Course planning for upcoming semesters", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Prerequisite checking and course sequencing", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Multiple degree path exploration (majors, minors, certificates)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Graduation timeline planning and milestone tracking", "type": "text" }]
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
              "content": [{ "text": "Create advising appointment scheduling system", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement degree audit calculation algorithms", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Develop advisor-student messaging platform", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up appointment reminder and notification system", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create degree requirement tracking logic", "type": "text" }]
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
              "content": [{ "text": "Design appointment scheduling interface", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Build degree audit visualization dashboard", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create advisor communication portal", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement academic planning tools", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Develop appointment management views", "type": "text" }]
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
              "content": [{ "text": "Connect to advisor and appointment tables", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Integrate with degree requirement data", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement student-advisor assignment tracking", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up appointment scheduling database", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Configure messaging system data storage", "type": "text" }]
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
              "content": [{ "text": "Appointment Success Rate: 95% successful appointment completions", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Degree Audit Accuracy: 100% match with official degree requirements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "User Satisfaction: > 90% positive feedback on advising tools", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Response Time: < 24 hours for advisor messages", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "System Availability: 99.9% uptime for advising module", "type": "text" }]
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
              "content": [{ "text": "SCRUM-56 Academic Module (for integration with academic records)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Authentication system (for advisor role permissions)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Database schema (advisor and appointment tables)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Notification system (for appointment reminders)", "type": "text" }]
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
      "advising-module",
      "appointment-scheduling",
      "degree-planning",
      "academic-advising",
      "student-advisor-communication",
      "graduation-requirements",
      "academic-planning"
    ]
  }
}'

RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q '"key":'; then
    STORY_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created Advising Module Story $STORY_KEY"
else
    echo "❌ FAILED: Could not create Advising Module Story"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "========================================"
echo "🎉 SCRUM-57 Story Creation Complete!"
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
echo "• advising-module, appointment-scheduling"
echo "• degree-planning, academic-advising"
echo "• student-advisor-communication"
echo "• graduation-requirements, academic-planning"
echo ""
echo "🎯 Story ready for sprint planning and implementation!"
echo "Next steps: Add to current sprint and begin advising module development."
echo ""
echo "🎓 This story implements comprehensive academic advising functionality"
echo "including appointment scheduling, degree planning, and advisor communication."