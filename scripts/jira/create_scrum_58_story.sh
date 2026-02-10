#!/bin/bash

# Create SCRUM-58: Finances Module Implementation Story
# Implements the financial management functionality for PAWS360

JIRA_URL="https://paw360.atlassian.net"
AUTH_HEADER="Authorization: Basic cm1uYW5uZXlAdXdtLmVkdTpBVEFUVDN4RmZHRjBxTWNuT1kzWjV1c010S0l4UTE2ZzZmMzZoVUZHOFRFRVlsRmVhNUgxd0ozN1ZpZ0toMS15YVVzNEV5eEZ0VmozQmx0S2FwWWJVa1E0V0lRT1dlMlNrTmYxRW1mX0V3R0cyX05BVHR1UHMwMDdyRlFnZnp5QzBRdmVNel95TmVDSF9ZcEpHWE02NnJXODVUU EV5cXhGT25ra0pMOEN5ZTZ5UERmNWpmUDJjVWc9RUI0QzEyN0I=="

echo "🚀 Creating SCRUM-58: Finances Module Implementation Story"
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

# Create Finances Module Story
echo "💰 Creating Finances Module Implementation Story..."

STORY_SUMMARY="SCRUM-58: Finances Module Implementation - Account Management & Payment Processing"
STORY_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "💰 Finances Module Implementation Story", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a student, I want to manage my financial information so that I can view my account balance, make payments, and track financial aid.",
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
              "content": [{ "text": "✅ View current account balance and transaction history", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Make online payments for tuition, fees, and other charges", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Track financial aid awards and disbursements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ View billing statements and payment due dates", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Access 1098-T tax forms for education expenses", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Set up payment plans and installment agreements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Receive payment reminders and due date notifications", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Payment Processing", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Secure online payment processing with multiple payment methods", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Credit card and bank account payment options", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Third-party payment processor integration (Stripe, PayPal)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Payment confirmation and receipt generation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Refund processing and tracking", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Payment plan setup and management", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Automatic payment scheduling", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Financial Aid Management", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ View financial aid award letters and packages", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Track aid disbursement schedules and amounts", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Monitor satisfactory academic progress (SAP) requirements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Access loan information and repayment schedules", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ View work-study job opportunities and earnings", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Scholarship tracking and renewal requirements", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Financial aid application status and missing documents", "type": "text" }]
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
              "content": [{ "text": "Implement payment gateway integration", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create financial data API endpoints", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Develop financial aid tracking system", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up transaction processing and logging", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement payment plan calculation logic", "type": "text" }]
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
              "content": [{ "text": "Design financial dashboard with account overview", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create payment processing interface", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Build financial aid tracking views", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement transaction history display", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Develop billing statement viewer", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Payment Integration", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Integrate with payment processors (Stripe/PayPal)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up secure payment tokenization", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement PCI compliance measures", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Configure webhook handling for payment confirmations", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up refund and chargeback processing", "type": "text" }]
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
              "content": [{ "text": "Payment Success Rate: 99% successful payment processing", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Data Accuracy: 100% match with official financial records", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "User Satisfaction: > 90% positive feedback on financial tools", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Security: Zero payment data breaches or compliance violations", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Availability: 99.9% uptime for financial module", "type": "text" }]
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
              "content": [{ "text": "Authentication system (for secure financial access)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Database schema (financial and payment tables)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Notification system (for payment reminders)", "type": "text" }]
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
      "finances-module",
      "payment-processing",
      "financial-aid",
      "account-management",
      "billing-system",
      "payment-plans",
      "transaction-history"
    ]
  }
}'

RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q '"key":'; then
    STORY_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created Finances Module Story $STORY_KEY"
else
    echo "❌ FAILED: Could not create Finances Module Story"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "========================================"
echo "🎉 SCRUM-58 Story Creation Complete!"
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
echo "• finances-module, payment-processing"
echo "• financial-aid, account-management"
echo "• billing-system, payment-plans"
echo "• transaction-history"
echo ""
echo "🎯 Story ready for sprint planning and implementation!"
echo "Next steps: Add to current sprint and begin finances module development."
echo ""
echo "💰 This story implements comprehensive financial management functionality"
echo "including payment processing, financial aid tracking, and account management."