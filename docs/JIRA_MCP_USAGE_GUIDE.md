# JIRA MCP Server Usage Guide

## 🎯 **How to Use the JIRA MCP Server**

The JIRA MCP Server is now **fully packaged and ready to use**! Here's everything you need to know:

## 📦 **Packaging & Isolation**

### ✅ **Isolated Package Structure**
```
src/
├── cli/                    # Command-line interface
│   ├── __init__.py
│   └── __main__.py        # CLI entry point
└── jira_mcp_server/       # Main package
    ├── __init__.py
    ├── config.py          # Configuration management
    ├── jira_client.py     # JIRA API client
    ├── middleware.py      # Authentication & rate limiting
    ├── models.py          # Pydantic models
    ├── server.py          # FastMCP server implementation
    └── tools.py           # Legacy tools (being phased out)
```

### ✅ **Installed as Standalone Tool**
The server is installed as a **global command-line tool**:
```bash
jira-mcp-server --help
```

### ✅ **Isolated from Main Repository**
- ✅ **Separate package**: `jira-mcp-server` (not part of main PAWS360 repo)
- ✅ **Independent dependencies**: Listed in `pyproject.toml`
- ✅ **Standalone CLI**: Can be used without the rest of the repository
- ✅ **Development mode**: Changes to source code are reflected immediately

## 🚀 **Quick Start**

### 1. **Set Environment Variables**
```bash
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_API_KEY="REPLACE_ME"
export JIRA_PROJECT_KEY="RGB"
```

### 2. **Start the Server**
```bash
jira-mcp-server serve
```

### 3. **Verify It's Running**
```bash
# Server will show:
JIRA MCP Server starting...
JIRA URL: https://yourcompany.atlassian.net
Project Key: RGB
Available tools: import_project, export_workitems, search_workitems, create_workitem, update_workitem
Server ready for MCP connections
```

## 🛠 **Configuration Options**

### **Environment Variables** (Recommended)
```bash
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_API_KEY="REPLACE_ME"
export JIRA_PROJECT_KEY="RGB"
export JIRA_TIMEOUT="30"
export JIRA_MAX_RETRIES="3"
export JIRA_RATE_LIMIT="50"
```

### **Command-Line Options**
```bash
jira-mcp-server serve \
  --jira-url "https://yourcompany.atlassian.net" \
  --api-key "REPLACE_ME" \
  --project-key "RGB"
```

### **Config File** (Optional)
```bash
# Create config.yaml
jira:
  url: "https://yourcompany.atlassian.net"
  api_key: "REPLACE_ME"
  project_key: "RGB"
  timeout: 30
  max_retries: 3
  rate_limit: 50

# Use with:
jira-mcp-server serve --config config.yaml
```

## 🔧 **Available Tools**

The server provides **5 MCP tools** for JIRA operations:

### 1. **import_project**
Import project data from JIRA
```json
{
  "name": "import_project",
  "arguments": {
    "project_key": "RGB"
  }
}
```

### 2. **export_workitems**
Export work items to JIRA
```json
{
  "name": "export_workitems",
  "arguments": {
    "workitems": [
      {
        "summary": "Implement new feature",
        "description": "Add functionality for user preferences",
        "issue_type": "Story"
      }
    ]
  }
}
```

### 3. **search_workitems**
Search work items using JQL
```json
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = RGB AND status = 'In Progress'",
    "max_results": 50
  }
}
```

### 4. **create_workitem**
Create a new work item
```json
{
  "name": "create_workitem",
  "arguments": {
    "summary": "Fix login bug",
    "description": "Users cannot log in with valid credentials",
    "issue_type": "Bug"
  }
}
```

### 5. **update_workitem**
Update an existing work item
```json
{
  "name": "update_workitem",
  "arguments": {
    "issue_key": "RGB-123",
    "updates": {
      "status": "Done",
      "comment": "Completed implementation"
    }
  }
}
```

## 🔗 **MCP Client Integration**

### **Claude Desktop**
Add to your `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "jira-RGB": {
      "command": "jira-mcp-server",
      "args": ["serve"],
      "env": {
        "JIRA_URL": "https://yourcompany.atlassian.net",
        "JIRA_API_KEY": "REPLACE_ME",
        "JIRA_PROJECT_KEY": "RGB"
      }
    }
  }
}
```

### **VS Code Extension**
Configure in your VS Code MCP extension settings:
```json
{
  "mcp.server.jira-RGB": {
    "command": "jira-mcp-server",
    "args": ["serve"],
    "env": {
      "JIRA_URL": "https://yourcompany.atlassian.net",
      "JIRA_API_KEY": "REPLACE_ME"
    }
  }
}
```

### **Other MCP Clients**
Any MCP-compatible client can use the server via stdio transport.

## 🧪 **Testing & Validation**

### **Test Server Startup**
```bash
jira-mcp-server serve --jira-url "https://test.atlassian.net" --api-key "test_key"
```

### **Validate Configuration**
```bash
jira-mcp-server validate
```

### **Test MCP Protocol**
```bash
# Send MCP initialize message
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | jira-mcp-server serve
```

## 📋 **Development Mode**

Since it's installed in development mode, **any changes you make to the source code are immediately available**:

```bash
# Edit source files
vim src/jira_mcp_server/server.py

# Changes are immediately available
jira-mcp-server serve
```

## 🔒 **Security & Authentication**

### **API Token Requirements**
- ✅ **Browse Projects**: View project details and work items
- ✅ **Create Issues**: Create new work items in RGB project
- ✅ **Edit Issues**: Update existing work items
- ✅ **Browse Users**: Search and view user information
- ✅ **Add Comments**: Add comments to work items

### **Security Features**
- ✅ **HTTPS Only**: Enforces secure connections
- ✅ **API Key Validation**: Validates token presence and format
- ✅ **Rate Limiting**: 50 requests/minute protection
- ✅ **Structured Logging**: Comprehensive audit trail
- ✅ **Error Handling**: Secure error responses

## 🚨 **Troubleshooting**

### **Common Issues**

**❌ "JIRA API key is not configured"**
```bash
export JIRA_API_KEY="REPLACE_ME"
```

**❌ "JIRA URL must use HTTPS"**
```bash
export JIRA_URL="https://yourcompany.atlassian.net"
```

**❌ "403 Forbidden"**
- Verify API token has required permissions
- Check token hasn't expired
- Ensure user has access to RGB project

**❌ "Connection timeout"**
- Check internet connectivity
- Verify JIRA instance is accessible
- Consider proxy settings

### **Debug Mode**
```bash
export MCP_LOG_LEVEL=DEBUG
jira-mcp-server serve
```

## 📊 **Performance & Limits**

- **Rate Limit**: 50 requests/minute
- **Timeout**: 30 seconds per request
- **Retries**: 3 attempts with exponential backoff
- **Concurrent**: Single-threaded (FastMCP handles async internally)

## 🎯 **Success Criteria**

✅ **Server starts successfully**  
✅ **MCP protocol handshake works**  
✅ **All 5 tools are available**  
✅ **Authentication is validated**  
✅ **JIRA API calls succeed**  
✅ **Error handling works properly**  

## 🚀 **Ready to Use!**

The JIRA MCP Server is **fully packaged, isolated, and ready for production use**:

```bash
# Quick test
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_API_KEY="REPLACE_ME"
export JIRA_PROJECT_KEY="RGB"

jira-mcp-server serve
```

**🎉 Happy JIRA automating!**</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/JIRA_MCP_USAGE_GUIDE.md