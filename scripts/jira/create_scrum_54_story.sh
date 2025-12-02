#!/bin/bash

# Create SCRUM-54: CI/CD Pipeline Setup and Basic Operations
# Comprehensive CI/CD pipeline implementation

JIRA_URL="https://paw360.atlassian.net"
AUTH_HEADER="Authorization: Basic cm1uYW5uZXlAdXdtLmVkdTpBVEFUVDN4RmZHRjBxTWNuT1kzWjV1c010S0l4UTE2ZzZmMzZoVUZHOFRFRVlsRmVhNUgxd0ozN1ZpZ0toMS15YVVzNEV5eEZ0VmozQmx0S2FwWWJVa1E0V0lRT1dlMlNrTmYxRW1mX0V3R0cyX05BVHR1UHMwMDdyRlFnZnp5QzBRdmVNel95TmVDSF9ZcEpHWE02NnJXODVUUEV5cXhGT25ra0pMOEN5ZTZ5UERmNWpmUDJjVWc9RUI0QzEyN0I="

echo "🚀 Creating SCRUM-54: CI/CD Pipeline Setup Story"
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

# Create CI/CD Pipeline Story
echo "🔧 Creating CI/CD Pipeline Setup Story..."

STORY_SUMMARY="SCRUM-54: CI/CD Pipeline Setup and Basic Operations"
STORY_DESCRIPTION='{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "heading",
      "attrs": { "level": 1 },
      "content": [{ "text": "🚀 CI/CD Pipeline Setup and Basic Operations", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "As a DevOps engineer/developer, I want to implement a comprehensive CI/CD pipeline, so that I can automate build, test, and deployment processes for reliable software delivery.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "📋 Description", "type": "text" }]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "text": "Establish a complete CI/CD pipeline for the PAWS360 project that automates the entire software delivery lifecycle from code commit to production deployment. The pipeline includes automated testing, security scanning, containerization, and multi-environment deployments with proper monitoring and rollback capabilities.",
          "type": "text"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "text": "✅ Acceptance Criteria", "type": "text" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "CI Pipeline Requirements", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Automated build process triggered by Git pushes and PRs", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Unit and integration test execution with reporting", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Code quality checks (linting, code style, coverage)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Security vulnerability scanning (dependencies and containers)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Multi-stage Docker image building and optimization", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Container registry integration and image tagging", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Build artifact storage and retrieval", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "CD Pipeline Requirements", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Automated deployment to staging environment", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Production deployment with approval gates", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Health checks and service verification post-deployment", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Automatic rollback on deployment failures", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Environment-specific configuration management", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Deployment status notifications and reporting", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Infrastructure Requirements", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Docker containerization with multi-stage builds", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Docker Compose for local development and testing", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Container orchestration readiness (Kubernetes/Helm charts)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Database migration and seeding automation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Redis/cache service integration", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Nginx reverse proxy configuration", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Monitoring and Observability", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Application health check endpoints", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Service monitoring and alerting setup", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Log aggregation and centralized logging", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Performance metrics collection", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Error tracking and reporting integration", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "Security and Compliance", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Secret management and environment variables", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Container image security scanning", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Dependency vulnerability assessment", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Access control and permission management", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "✅ Audit logging and compliance reporting", "type": "text" }]
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
      "content": [{ "text": "CI Pipeline Development", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up GitHub Actions workflow with comprehensive job matrix", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement automated testing with JUnit, integration tests", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Configure security scanning with Trivy and OWASP Dependency Check", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create multi-stage Dockerfile for optimized builds", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up container registry integration (GitHub Container Registry)", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement build artifact management and caching", "type": "text" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "text": "CD Pipeline Development", "type": "text" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Configure staging environment deployment automation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement production deployment with manual approval", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Set up health checks and service verification", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Create rollback procedures and automation", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Implement environment-specific configuration", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Configure deployment notifications (Slack/Teams integration)", "type": "text" }]
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
              "content": [{ "text": "Build Success Rate: >95% of builds pass without failures", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Deployment Frequency: Multiple deployments per day to staging", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Lead Time: < 30 minutes from commit to staging deployment", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Test Coverage: >80% code coverage maintained", "type": "text" }]
            }
          ]
        },
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "text": "Security: Zero critical vulnerabilities in deployed images", "type": "text" }]
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
    "customfield_10016": 21,
    "labels": [
      "ci-cd",
      "devops",
      "automation",
      "docker",
      "github-actions",
      "infrastructure",
      "security",
      "monitoring",
      "deployment"
    ]
  }
}'

RESPONSE=$(curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q '"key":'; then
    STORY_KEY=$(echo "$RESPONSE" | grep -o '"key":"[^"]*"' | cut -d'"' -f4)
    echo "✅ SUCCESS: Created CI/CD Pipeline Story $STORY_KEY"
else
    echo "❌ FAILED: Could not create CI/CD Pipeline Story"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "========================================"
echo "🎉 SCRUM-54 Story Creation Complete!"
echo ""
echo "📋 Story Details:"
echo "✅ Story Key: $STORY_KEY"
echo "✅ Story Points: 21"
echo "✅ Summary: $STORY_SUMMARY"
echo ""
echo "🔗 Story URL:"
echo "https://paw360.atlassian.net/browse/$STORY_KEY"
echo ""
echo "📝 Labels Applied:"
echo "• ci-cd, devops, automation"
echo "• docker, github-actions, infrastructure"
echo "• security, monitoring, deployment"
echo ""
echo "🚀 Comprehensive CI/CD Pipeline Implementation"
echo "• GitHub Actions workflow"
echo "• Automated testing and security scanning"
echo "• Multi-environment deployments"
echo "• Monitoring and observability"
echo "• Security and compliance"
echo ""
echo "🎯 Story ready for current sprint!"
echo "Branch: SCRUM-54-CI-CD-Pipeline-Setup is in progress"
echo ""
