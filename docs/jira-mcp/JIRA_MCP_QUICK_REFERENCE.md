# Complete JIRA MCP Server Quick Reference

## 🚀 Quick Start Commands

# 1. Set environment variables
export JIRA_URL='https://paw360.atlassian.net'
export JIRA_API_KEY='your_api_token_here'
export JIRA_EMAIL='your-email@university.edu'
export JIRA_PROJECT_KEY='PGB'

# 2. Start server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve

# 3. Test with MCP protocol (in another terminal)
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve

## 📋 Available Tools

1. create_workitem - Create stories, bugs, tasks
2. search_workitems - Find issues with JQL
3. update_workitem - Modify existing issues
4. import_project - Get project data
5. export_workitems - Bulk create issues

## 🎯 Create Story Examples

### Basic Story
{
  "name": "create_workitem",
  "arguments": {
    "summary": "User login functionality",
    "description": "Implement secure user authentication",
    "issue_type": "Story"
  }
}

### Detailed Story with Acceptance Criteria
{
  "name": "create_workitem",
  "arguments": {
    "summary": "As a student, I want to view my course schedule",
    "description": "Students should be able to see their weekly schedule with class times, locations, and instructor information.",
    "issue_type": "Story"
  }
}

## 🔍 Search Examples

# Find open stories
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = PGB AND issuetype = Story AND status != Done"
  }
}

# Find high priority bugs
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = PGB AND issuetype = Bug AND priority = High"
  }
}
