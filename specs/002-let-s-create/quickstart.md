# Quickstart: JIRA MCP Server for PGB Project Management

**Date**: 2025-09-18
**Feature**: JIRA MCP Server for PGB Project Management
**Status**: Ready for Implementation

## Overview

This quickstart guide provides step-by-step instructions for setting up and validating the JIRA MCP Server for PGB project management. The server enables seamless import and export of project data between local systems and JIRA.

## Prerequisites

### System Requirements
- Python 3.11 or higher
- Access to PGB JIRA instance: https://paw360.atlassian.net/jira/software/projects/PGB
- Valid JIRA API token with appropriate permissions

### Required Permissions
- **Browse Projects**: View project details and work items
- **Create Issues**: Create new work items in PGB project
- **Edit Issues**: Update existing work items
- **Browse Users**: Search and view user information
- **Add Comments**: Add comments to work items

## Installation

### 1. Clone Repository
```bash
git clone <repository-url>
cd jira-mcp-server
```

### 2. Create Virtual Environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment
Create a `.env` file in the project root:
```bash
# JIRA Configuration
JIRA_BASE_URL=https://paw360.atlassian.net
JIRA_PROJECT_KEY=PGB
JIRA_API_TOKEN=your_api_token_here
JIRA_EMAIL=your_email@example.com

# MCP Server Configuration
MCP_SERVER_PORT=3000
MCP_LOG_LEVEL=INFO
```

## Basic Usage

### Starting the Server
```bash
# Start MCP server in stdio mode (for MCP clients)
python -m jira_mcp_server

# Start with HTTP transport (for testing)
python -m jira_mcp_server --http --port 3000
```

### MCP Client Integration
The server communicates via stdio and can be integrated with any MCP-compatible client:

```json
{
  "mcpServers": {
    "jira-pgb": {
      "command": "python",
      "args": ["-m", "jira_mcp_server"],
      "env": {
        "JIRA_API_TOKEN": "your_token",
        "JIRA_EMAIL": "your_email"
      }
    }
  }
}
```

## Core Operations

### 1. Import Project Data
**Purpose**: Retrieve all work items from the PGB project

**MCP Tool Call**:
```json
{
  "method": "tools/call",
  "params": {
    "name": "import_project_data",
    "arguments": {
      "include_comments": true,
      "include_attachments": false,
      "max_results": 1000
    }
  }
}
```

**Expected Response**:
```json
{
  "result": {
    "project": {
      "key": "PGB",
      "name": "PGB Project",
      "total_issues": 150
    },
    "issues": [...],
    "export_timestamp": "2025-09-18T10:30:00Z"
  }
}
```

### 2. Export Work Items
**Purpose**: Create or update work items in JIRA

**MCP Tool Call**:
```json
{
  "method": "tools/call",
  "params": {
    "name": "export_work_items",
    "arguments": {
      "issues": [
        {
          "summary": "Implement user authentication",
          "description": "Add OAuth2 authentication flow",
          "issuetype": "Story",
          "priority": "High",
          "assignee": "john.doe@example.com",
          "labels": ["authentication", "security"]
        }
      ]
    }
  }
}
```

**Expected Response**:
```json
{
  "result": {
    "created": [
      {
        "key": "PGB-151",
        "id": "12345",
        "self": "https://paw360.atlassian.net/rest/api/3/issue/12345"
      }
    ],
    "errors": []
  }
}
```

### 3. Search Work Items
**Purpose**: Find specific work items using JQL queries

**MCP Tool Call**:
```json
{
  "method": "tools/call",
  "params": {
    "name": "search_issues",
    "arguments": {
      "jql": "project = PGB AND status = 'In Progress' AND assignee = currentUser()",
      "fields": "summary,status,assignee,priority",
      "max_results": 50
    }
  }
}
```

**Expected Response**:
```json
{
  "result": {
    "issues": [
      {
        "key": "PGB-123",
        "fields": {
          "summary": "Fix login bug",
          "status": {"name": "In Progress"},
          "assignee": {"displayName": "John Doe"},
          "priority": {"name": "High"}
        }
      }
    ],
    "total": 1
  }
}
```

### 4. Update Work Item Status
**Purpose**: Change the status of existing work items

**MCP Tool Call**:
```json
{
  "method": "tools/call",
  "params": {
    "name": "update_issue_status",
    "arguments": {
      "issue_key": "PGB-123",
      "status": "Done",
      "comment": "Completed implementation and testing"
    }
  }
}
```

**Expected Response**:
```json
{
  "result": {
    "issue": {
      "key": "PGB-123",
      "status": "Done",
      "updated": "2025-09-18T11:00:00Z"
    }
  }
}
```

## Validation Steps

### 1. Health Check
Verify server connectivity and authentication:
```bash
curl -H "Authorization: Bearer $JIRA_API_TOKEN" \
     "https://paw360.atlassian.net/rest/api/3/project/PGB"
```

**Expected**: HTTP 200 with project JSON

### 2. Permission Validation
Test API token permissions:
```bash
curl -H "Authorization: Bearer $JIRA_API_TOKEN" \
     "https://paw360.atlassian.net/rest/api/3/search?jql=project=PGB&maxResults=1"
```

**Expected**: HTTP 200 with at least one issue

### 3. MCP Server Test
Test MCP server initialization:
```bash
echo '{"method": "initialize", "params": {}}' | python -m jira_mcp_server
```

**Expected**: Valid MCP initialization response

## Common Issues & Solutions

### Authentication Errors
**Error**: `401 Unauthorized`
**Solution**:
- Verify API token is correct and not expired
- Ensure token has required permissions
- Check email address matches token owner

### Rate Limiting
**Error**: `429 Too Many Requests`
**Solution**:
- Wait for Retry-After header duration
- Reduce request frequency
- Implement exponential backoff

### Permission Errors
**Error**: `403 Forbidden`
**Solution**:
- Verify user has access to PGB project
- Check project permissions in JIRA
- Ensure API token has necessary scopes

### Network Issues
**Error**: Connection timeouts
**Solution**:
- Check internet connectivity
- Verify JIRA instance is accessible
- Consider proxy settings if applicable

## Performance Guidelines

### Bulk Operations
- Use bulk APIs for multiple items (>10)
- Limit concurrent requests to 5-10
- Respect JIRA's 50 requests/minute limit

### Data Synchronization
- Cache project metadata for 24 hours
- Use incremental sync for large projects
- Implement conflict resolution for concurrent edits

### Memory Management
- Stream large result sets
- Limit attachment downloads
- Clean up temporary files regularly

## Next Steps

### Development Workflow
1. **Setup**: Complete installation and configuration
2. **Test**: Run validation steps above
3. **Integrate**: Connect with your MCP client
4. **Customize**: Modify tools for specific PGB workflows
5. **Deploy**: Set up production environment

### Advanced Features
- **Webhooks**: Real-time JIRA event notifications
- **Workflows**: Custom JIRA workflow integration
- **Reports**: Generate project analytics
- **Automation**: Set up rule-based actions

### Support
- Check logs in `logs/jira-mcp-server.log`
- Enable debug mode: `MCP_LOG_LEVEL=DEBUG`
- Review JIRA API documentation for advanced features

## Success Criteria

✅ **Server starts without errors**  
✅ **Authentication successful**  
✅ **Can import PGB project data**  
✅ **Can create new work items**  
✅ **Can update existing items**  
✅ **Search functionality works**  
✅ **Error handling is robust**  

When all criteria are met, the JIRA MCP Server is ready for production use with the PGB project!</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/specs/002-let-s-create/quickstart.md