# JIRA MCP Server - Team Documentation

## 🎯 **Overview**

The JIRA MCP Server is a fully functional Model Context Protocol (MCP) server that enables seamless integration between AI assistants (like Claude, VS Code Copilot) and JIRA for the PAWS360 project. This documentation provides everything your team needs to get started with creating, managing, and automating JIRA work items.

**Status**: ✅ **PRODUCTION READY**  
**Date**: September 20, 2025  
**Version**: 1.0.0  
**Project**: PGB (PAWS360)  

---

## 📋 **Table of Contents**

1. [Quick Start](#-quick-start)
2. [Configuration](#-configuration)
3. [Usage Methods](#-usage-methods)
4. [Available Tools](#-available-tools)
5. [Examples & Templates](#-examples--templates)
6. [Integration Guides](#-integration-guides)
7. [Troubleshooting](#-troubleshooting)
8. [Best Practices](#-best-practices)
9. [API Reference](#-api-reference)

---

## 🚀 **Quick Start**

### **Prerequisites**
- ✅ Python 3.11+
- ✅ JIRA API token with appropriate permissions
- ✅ Access to PAWS360 JIRA project (PGB)

### **3-Step Setup**

```bash
# 1. Clone and navigate to project
cd /home/ryan/repos/PAWS360ProjectPlan

# 2. Set environment variables
export JIRA_URL="https://paw360.atlassian.net"
export JIRA_API_KEY="REPLACE_ME"
export JIRA_EMAIL="your-email@university.edu"
export JIRA_PROJECT_KEY="PGB"

# 3. Start the server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

**Expected Output:**
```
JIRA MCP Server starting...
JIRA URL: https://paw360.atlassian.net
Project Key: PGB
Available tools: import_project, export_workitems, search_workitems, create_workitem, update_workitem
Server ready for MCP connections
```

---

## ⚙️ **Configuration**

### **Environment Variables**

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `JIRA_URL` | JIRA instance URL | ✅ | - |
| `JIRA_API_KEY` | JIRA API token | ✅ | - |
| `JIRA_EMAIL` | JIRA account email | ✅ | - |
| `JIRA_PROJECT_KEY` | Project key | ❌ | PGB |
| `JIRA_TIMEOUT` | API timeout (seconds) | ❌ | 30 |
| `JIRA_RATE_LIMIT` | Rate limit (req/min) | ❌ | 50 |

### **Configuration Files**

#### **`.env` File**
```bash
# JIRA MCP Server Configuration
JIRA_URL=https://paw360.atlassian.net
JIRA_API_KEY=your_actual_api_token_here
JIRA_EMAIL=your-email@university.edu
JIRA_PROJECT_KEY=PGB
JIRA_TIMEOUT=30
JIRA_RATE_LIMIT=50
```

#### **Centralized Configuration**
The project uses a centralized configuration system. Generate environment-specific configs:

```bash
# Generate development configuration
./scripts/config/generate-env.sh development

# Generate production configuration
./scripts/config/generate-env.sh production
```

---

## 🔧 **Usage Methods**

### **Method 1: Direct MCP Protocol**

**Start Server:**
```bash
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

**Send MCP Messages:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "create_workitem",
    "arguments": {
      "summary": "Implement user authentication",
      "description": "Add secure login functionality",
      "issue_type": "Story"
    }
  }
}
```

### **Method 2: Claude Desktop Integration**

**Configuration File:** `claude_desktop_config.json`
```json
{
  "mcpServers": {
    "jira-paws360": {
      "command": "python",
      "args": ["-m", "cli", "serve"],
      "env": {
        "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
        "JIRA_URL": "https://paw360.atlassian.net",
        "JIRA_API_KEY": "REPLACE_ME",
        "JIRA_EMAIL": "your-email@university.edu",
        "JIRA_PROJECT_KEY": "PGB"
      }
    }
  }
}
```

**Usage:**
> "Create a JIRA story for implementing student course registration"

### **Method 3: VS Code MCP Extension**

**VS Code Settings:**
```json
{
  "mcp.server.jira-paws360": {
    "command": "python",
    "args": ["-m", "cli", "serve"],
    "env": {
      "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
      "JIRA_URL": "https://paw360.atlassian.net",
      "JIRA_API_KEY": "REPLACE_ME"
    }
  }
}
```

### **Method 4: Programmatic Integration**

```python
import json
import subprocess
import os

# Configure environment
os.environ.update({
    'PYTHONPATH': '/home/ryan/repos/PAWS360ProjectPlan/src',
    'JIRA_URL': 'https://paw360.atlassian.net',
    'JIRA_API_KEY': 'REPLACE_ME',
    'JIRA_PROJECT_KEY': 'PGB'
})

# Start server
server = subprocess.Popen([
    'python', '-m', 'cli', 'serve'
], stdin=subprocess.PIPE, stdout=subprocess.PIPE)

# Create story
request = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
        "name": "create_workitem",
        "arguments": {
            "summary": "User login functionality",
            "description": "Implement secure authentication",
            "issue_type": "Story"
        }
    }
}

# Send request
server.stdin.write(json.dumps(request).encode())
server.stdin.flush()

# Get response
response = server.stdout.readline()
result = json.loads(response)
print(f"Created issue: {result['result']['issue']['key']}")
```

---

## 🛠️ **Available Tools**

### **Core Tools**

| Tool | Description | Use Case |
|------|-------------|----------|
| `create_workitem` | Create new issues | Adding user stories, bugs, tasks |
| `search_workitems` | Search with JQL | Finding issues by criteria |
| `update_workitem` | Modify existing issues | Updating status, assignee, fields |
| `import_project` | Get project data | Project analysis and reporting |
| `export_workitems` | Bulk create issues | Importing from other systems |

### **Advanced Tools**

| Tool | Description | Use Case |
|------|-------------|----------|
| `create_sprint` | Create sprints | Sprint planning |
| `assign_to_sprint` | Add issues to sprints | Sprint management |
| `assign_team` | Assign teams/users | Resource allocation |
| `bulk_update_issues` | Update multiple issues | Batch operations |
| `get_sprint_capacity_report` | Capacity analysis | Sprint planning |

---

## 📝 **Examples & Templates**

### **User Story Template**

```json
{
  "name": "create_workitem",
  "arguments": {
    "summary": "As a [user type], I want [functionality] so that [benefit]",
    "description": "Detailed description of the requirement.\n\n**Acceptance Criteria:**\n- Criterion 1\n- Criterion 2\n- Criterion 3\n\n**Technical Notes:**\n- Any technical considerations",
    "issue_type": "Story"
  }
}
```

### **Bug Report Template**

```json
{
  "name": "create_workitem",
  "arguments": {
    "summary": "Brief description of the bug",
    "description": "**Steps to Reproduce:**\n1. Step 1\n2. Step 2\n3. Step 3\n\n**Expected Result:** What should happen\n\n**Actual Result:** What actually happens\n\n**Environment:** Browser, OS, etc.",
    "issue_type": "Bug"
  }
}
```

### **Search Examples**

```json
// Find open stories
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = PGB AND issuetype = Story AND status != Done",
    "max_results": 20
  }
}

// Find high priority items
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = PGB AND priority = High AND status != Done"
  }
}

// Find items assigned to current sprint
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = PGB AND sprint in openSprints()"
  }
}
```

### **Update Examples**

```json
// Update status and assignee
{
  "name": "update_workitem",
  "arguments": {
    "issue_key": "PGB-123",
    "updates": {
      "status": "In Progress",
      "assignee": {"accountId": "user123"}
    }
  }
}

// Add comment and update priority
{
  "name": "update_workitem",
  "arguments": {
    "issue_key": "PGB-123",
    "updates": {
      "priority": "High",
      "comment": "This is blocking the next sprint"
    }
  }
}
```

---

## 🔗 **Integration Guides**

### **Claude Desktop Setup**

1. **Locate Configuration File:**
   ```bash
   # macOS
   ~/Library/Application Support/Claude/claude_desktop_config.json

   # Windows
   %APPDATA%/Claude/claude_desktop_config.json
   ```

2. **Add JIRA MCP Server:**
   ```json
   {
     "mcpServers": {
       "jira-paws360": {
         "command": "python",
         "args": ["-m", "cli", "serve"],
         "env": {
           "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
           "JIRA_URL": "https://paw360.atlassian.net",
           "JIRA_API_KEY": "REPLACE_ME",
           "JIRA_EMAIL": "your-email@university.edu",
           "JIRA_PROJECT_KEY": "PGB"
         }
       }
     }
   }
   ```

3. **Restart Claude Desktop**

### **VS Code Setup**

1. **Install MCP Extension:**
   - Search for "MCP" in VS Code extensions
   - Install the official MCP extension

2. **Configure Server:**
   ```json
   {
     "mcp.server.jira-paws360": {
       "command": "python",
       "args": ["-m", "cli", "serve"],
       "env": {
         "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
         "JIRA_URL": "https://paw360.atlassian.net",
         "JIRA_API_KEY": "REPLACE_ME"
       }
     }
   }
   ```

### **Custom Application Integration**

```python
import asyncio
import json
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

class JIRAMCPClient:
    def __init__(self):
        self.session = None

    async def connect(self):
        server_params = StdioServerParameters(
            command="python",
            args=["-m", "cli", "serve"],
            env={
                "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
                "JIRA_URL": "https://paw360.atlassian.net",
                "JIRA_API_KEY": "REPLACE_ME",
                "JIRA_PROJECT_KEY": "PGB"
            }
        )

        async with stdio_client(server_params) as (read, write):
            async with ClientSession(read, write) as session:
                self.session = session
                await session.initialize()
                return session

    async def create_story(self, summary, description):
        if not self.session:
            await self.connect()

        result = await self.session.call_tool(
            "create_workitem",
            arguments={
                "summary": summary,
                "description": description,
                "issue_type": "Story"
            }
        )
        return result

# Usage
async def main():
    client = JIRAMCPClient()
    result = await client.create_story(
        "Implement user dashboard",
        "Create a personalized dashboard for students"
    )
    print(f"Created issue: {result.content[0].text}")

asyncio.run(main())
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **❌ "JIRA API key is not configured"**
```bash
# Set the API key
export JIRA_API_KEY="REPLACE_ME_here"

# Or add to .env file
echo "JIRA_API_KEY=REPLACE_ME_here" >> .env
```

#### **❌ "JIRA URL must use HTTPS"**
```bash
# Use HTTPS URL
export JIRA_URL="https://paw360.atlassian.net"
```

#### **❌ "403 Forbidden"**
- ✅ Verify API token has correct permissions
- ✅ Check token hasn't expired
- ✅ Ensure user has access to PGB project
- ✅ Confirm email address matches token owner

#### **❌ "Connection timeout"**
```bash
# Increase timeout
export JIRA_TIMEOUT=60

# Check network connectivity
ping paw360.atlassian.net
```

#### **❌ "Rate limit exceeded"**
```bash
# Reduce rate limit
export JIRA_RATE_LIMIT=30

# Wait before retrying
sleep 60
```

### **Debug Mode**

```bash
# Enable debug logging
export MCP_LOG_LEVEL=DEBUG

# Start server with verbose output
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

### **Validation**

```bash
# Validate configuration
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli validate

# Test connection
curl -H "Authorization: Bearer $JIRA_API_KEY" \
     "https://paw360.atlassian.net/rest/api/3/project/PGB"
```

---

## 📋 **Best Practices**

### **Story Writing**

#### **Good Story Format**
```
As a [user type], I want [functionality] so that [benefit]

Description:
- Clear, concise description
- Include acceptance criteria
- Add technical notes if needed
- Reference related issues
```

#### **Acceptance Criteria**
```
**Acceptance Criteria:**
- [ ] User can perform action X
- [ ] System validates input Y
- [ ] Error message Z is displayed
- [ ] Performance meets requirement W
```

### **Search Optimization**

#### **Effective JQL Queries**
```sql
-- Find open stories in current sprint
project = PGB AND issuetype = Story AND sprint in openSprints() AND status != Done

-- Find high priority bugs assigned to me
project = PGB AND issuetype = Bug AND priority = High AND assignee = currentUser()

-- Find items without acceptance criteria
project = PGB AND "Acceptance Criteria" is EMPTY
```

### **Bulk Operations**

#### **Efficient Bulk Updates**
```json
{
  "name": "bulk_update_issues",
  "arguments": {
    "issue_keys": ["PGB-123", "PGB-124", "PGB-125"],
    "updates": {
      "status": "In Progress",
      "assignee": {"accountId": "user123"}
    }
  }
}
```

### **Sprint Management**

#### **Sprint Planning Workflow**
1. **Create Sprint:**
   ```json
   {
     "name": "create_sprint",
     "arguments": {
       "name": "Sprint 25",
       "board_id": 1,
       "start_date": "2025-09-23",
       "end_date": "2025-10-04"
     }
   }
   ```

2. **Add Issues to Sprint:**
   ```json
   {
     "name": "assign_to_sprint",
     "arguments": {
       "issue_keys": ["PGB-123", "PGB-124"],
       "sprint_id": 123
     }
   }
   ```

3. **Assign Teams:**
   ```json
   {
     "name": "assign_team",
     "arguments": {
       "issue_key": "PGB-123",
       "team_id": "frontend-team",
       "assignee": "user123"
     }
   }
   ```

---

## 📚 **API Reference**

### **Tool Specifications**

#### **create_workitem**
```typescript
interface CreateWorkitemArgs {
  summary: string;           // Issue summary (required)
  description?: string;      // Issue description
  issue_type?: string;       // Story, Bug, Task, Epic (default: Task)
}

interface CreateWorkitemResponse {
  success: boolean;
  issue?: Issue;
  error?: string;
}
```

#### **search_workitems**
```typescript
interface SearchWorkitemsArgs {
  jql: string;              // JQL query (required)
  max_results?: number;     // Maximum results (default: 50)
}

interface SearchWorkitemsResponse {
  success: boolean;
  total: number;
  issues: Issue[];
  error?: string;
}
```

#### **update_workitem**
```typescript
interface UpdateWorkitemArgs {
  issue_key: string;        // Issue key (required)
  updates: object;          // Fields to update (required)
}

interface UpdateWorkitemResponse {
  success: boolean;
  issue?: Issue;
  error?: string;
}
```

### **Issue Object**
```typescript
interface Issue {
  id: string;
  key: string;
  fields: {
    summary: string;
    description?: string;
    issuetype: {
      name: string;
    };
    status: {
      name: string;
    };
    assignee?: {
      accountId: string;
      displayName: string;
    };
    priority?: {
      name: string;
    };
    created: string;
    updated: string;
  };
}
```

---

## 📞 **Support & Resources**

### **Getting Help**

1. **Check Logs:**
   ```bash
   # Enable debug logging
   export MCP_LOG_LEVEL=DEBUG
   ```

2. **Validate Configuration:**
   ```bash
   PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli validate
   ```

3. **Test API Connection:**
   ```bash
   curl -H "Authorization: Bearer $JIRA_API_KEY" \
        "https://paw360.atlassian.net/rest/api/3/myself"
   ```

### **Documentation Links**

- **[JIRA MCP Complete Implementation](../JIRA_MCP_COMPLETE_IMPLEMENTATION.md)**: Technical implementation details
- **[Centralized Configuration](../config/README.md)**: Configuration management
- **[JIRA MCP Usage Guide](../JIRA_MCP_USAGE_GUIDE.md)**: Basic usage guide
- **[MCP Protocol Examples](mcp_examples.json)**: Sample MCP messages
- **[Claude Configuration](claude_config_example.json)**: Claude Desktop setup

### **Team Resources**

- **Quick Reference:** `docs/jira-mcp/JIRA_MCP_QUICK_REFERENCE.md`
- **Setup Scripts:** `docs/jira-mcp/setup_jira_env.sh`
- **Test Scripts:** `docs/jira-mcp/test_jira_server.sh`
- **MCP Examples:** `docs/jira-mcp/mcp_examples.json`

---

## 🎯 **Next Steps**

### **Immediate Actions**
- [ ] Set up JIRA API tokens for team members
- [ ] Configure Claude Desktop integration
- [ ] Test story creation workflow
- [ ] Set up automated sprint planning

### **Team Training**
- [ ] Review this documentation with the team
- [ ] Demonstrate live story creation
- [ ] Practice bulk operations
- [ ] Set up individual configurations

### **Process Integration**
- [ ] Integrate with existing development workflow
- [ ] Create story templates for common scenarios
- [ ] Set up automated reporting
- [ ] Establish team usage guidelines

---

**🚀 Ready to revolutionize your JIRA workflow with AI-powered automation!**

*Last Updated: September 20, 2025*  
*Version: 1.0.0*  
*Contact: Development Team*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/jira-mcp/README.md