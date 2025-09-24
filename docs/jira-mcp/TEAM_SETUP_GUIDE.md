# JIRA MCP Server - Team Setup Guide

## 🎯 **5-Minute Team Setup**

This guide will get your entire team up and running with the JIRA MCP Server in under 5 minutes.

---

## 📋 **Prerequisites Checklist**

### **For Each Team Member**
- [ ] JIRA account with API token access
- [ ] Python 3.11+ installed
- [ ] Access to PAWS360 repository
- [ ] Claude Desktop or VS Code with MCP extension

### **Team Resources**
- [ ] JIRA API tokens distributed
- [ ] Repository access granted
- [ ] This documentation shared

---

## 🚀 **Individual Setup (2 minutes)**

### **Step 1: Clone Repository**
```bash
git clone https://github.com/your-org/PAWS360ProjectPlan.git
cd PAWS360ProjectPlan
```

### **Step 2: Set Environment Variables**
```bash
# Copy the setup script
cp docs/jira-mcp/setup_jira_env.sh .
chmod +x setup_jira_env.sh

# Edit with your credentials
nano setup_jira_env.sh
```

**Edit the file:**
```bash
# Set your JIRA credentials
export JIRA_URL='https://paw360.atlassian.net'
export JIRA_API_KEY='your_personal_api_token_here'
export JIRA_EMAIL='your-email@university.edu'
export JIRA_PROJECT_KEY='PGB'
```

### **Step 3: Test Setup**
```bash
# Load your environment
source setup_jira_env.sh

# Test the server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

**Expected output:**
```
JIRA MCP Server starting...
JIRA URL: https://paw360.atlassian.net
Project Key: PGB
Available tools: import_project, export_workitems, search_workitems, create_workitem, update_workitem
Server ready for MCP connections
```

---

## 🔗 **Integration Setup**

### **Option A: Claude Desktop (Recommended)**

1. **Find Claude Config File:**
   ```bash
   # macOS
   open ~/Library/Application\ Support/Claude/

   # Windows
   explorer %APPDATA%/Claude/

   # Linux
   xdg-open ~/.config/Claude/
   ```

2. **Edit `claude_desktop_config.json`:**
   ```json
   {
     "mcpServers": {
       "jira-paws360": {
         "command": "python",
         "args": ["-m", "cli", "serve"],
         "env": {
           "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
           "JIRA_URL": "https://paw360.atlassian.net",
           "JIRA_API_KEY": "your_api_token_here",
           "JIRA_EMAIL": "your-email@university.edu",
           "JIRA_PROJECT_KEY": "PGB"
         }
       }
     }
   }
   ```

3. **Restart Claude Desktop**

### **Option B: VS Code**

1. **Install MCP Extension:**
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "MCP"
   - Install the MCP extension

2. **Configure in Settings:**
   ```json
   {
     "mcp.server.jira-paws360": {
       "command": "python",
       "args": ["-m", "cli", "serve"],
       "env": {
         "PYTHONPATH": "/home/ryan/repos/PAWS360ProjectPlan/src",
         "JIRA_URL": "https://paw360.atlassian.net",
         "JIRA_API_KEY": "your_api_token_here"
       }
     }
   }
   ```

---

## 🧪 **Quick Test (1 minute)**

### **Test 1: Create Your First Story**
In Claude Desktop, type:
> "Create a JIRA story for testing the MCP server integration"

**Expected Result:**
- Claude will create a story in your PGB project
- You'll see the issue key (e.g., PGB-456)
- Story will have appropriate summary and description

### **Test 2: Search for Stories**
> "Find all open stories in the PGB project"

**Expected Result:**
- Claude will return a list of open stories
- Each story shows key, summary, status, assignee

### **Test 3: Update a Story**
> "Update PGB-456 to 'In Progress' status and assign it to me"

**Expected Result:**
- Story status changes to "In Progress"
- Assignee field updates to your account

---

## 📝 **Team Story Templates**

### **User Story Template**
```
As a [student/teacher/admin], I want [functionality] so that [benefit]

**Description:**
[Clear description of the requirement]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

**Technical Notes:**
[Any technical considerations or dependencies]
```

### **Bug Report Template**
```
**Summary:** [Brief description of the bug]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:** [What should happen]
**Actual Result:** [What actually happens]

**Environment:** [Browser, OS, device, etc.]
**Severity:** [Critical/High/Medium/Low]
```

### **Task Template**
```
**Summary:** [Brief description of the task]

**Description:**
[Clear description of what needs to be done]

**Sub-tasks:**
- [ ] Sub-task 1
- [ ] Sub-task 2
- [ ] Sub-task 3

**Dependencies:**
- [Dependency 1]
- [Dependency 2]

**Estimated Effort:** [Time estimate]
```

---

## 🎯 **Daily Workflow**

### **Morning Standup**
1. **Review yesterday's progress:**
   > "Show me all stories I updated yesterday"

2. **Check sprint status:**
   > "What's the current sprint capacity and team assignments?"

3. **Identify blockers:**
   > "Find high priority bugs that are blocking progress"

### **Story Creation**
1. **Create user story:**
   > "Create a story for implementing student grade viewing functionality"

2. **Add acceptance criteria:**
   > "Update PGB-123 with these acceptance criteria: [list]"

3. **Assign to sprint:**
   > "Add PGB-123 to the current sprint"

### **Sprint Planning**
1. **Create sprint:**
   > "Create a new sprint starting next Monday for 2 weeks"

2. **Plan sprint:**
   > "Add these stories to the sprint and assign team members: [list]"

3. **Capacity check:**
   > "Generate a capacity report for the current sprint"

---

## 🔧 **Troubleshooting**

### **❌ "Module not found"**
```bash
# Ensure PYTHONPATH is set
export PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src
```

### **❌ "API token invalid"**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Generate new token
3. Update your `setup_jira_env.sh` file

### **❌ "Permission denied"**
- Ensure you have access to the PGB project
- Check that your API token has the right permissions
- Verify your email address matches the token owner

### **❌ "Connection timeout"**
```bash
# Test network connectivity
ping paw360.atlassian.net

# Increase timeout if needed
export JIRA_TIMEOUT=60
```

---

## 📞 **Getting Help**

### **Quick Help**
1. **Check the main documentation:** `docs/jira-mcp/README.md`
2. **Review examples:** `docs/jira-mcp/mcp_examples.json`
3. **Test with scripts:** `docs/jira-mcp/test_jira_server.sh`

### **Team Support**
- **Slack Channel:** #jira-mcp-support
- **Documentation:** `docs/jira-mcp/`
- **Lead Contact:** Development Team Lead

### **Debug Mode**
```bash
# Enable detailed logging
export MCP_LOG_LEVEL=DEBUG
export JIRA_LOG_LEVEL=DEBUG

# Start server with verbose output
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

---

## ✅ **Success Checklist**

### **Individual Setup**
- [ ] Repository cloned
- [ ] Environment variables configured
- [ ] Server starts successfully
- [ ] Claude Desktop configured
- [ ] First story created successfully

### **Team Integration**
- [ ] All team members have API tokens
- [ ] Shared story templates established
- [ ] Communication channels set up
- [ ] Support processes documented

### **Workflow Integration**
- [ ] Daily standup process updated
- [ ] Sprint planning workflow defined
- [ ] Story creation guidelines established
- [ ] Reporting and tracking processes set up

---

## 🎉 **You're All Set!**

**Congratulations!** Your team is now ready to revolutionize JIRA workflow management with AI-powered automation.

### **Next Steps**
1. **Start creating stories** for your current sprint
2. **Experiment with bulk operations** for efficiency
3. **Set up automated reporting** for sprint reviews
4. **Customize templates** for your team's specific needs

### **Pro Tips**
- Use consistent story formats for better searchability
- Leverage bulk operations for sprint planning
- Set up automated notifications for status changes
- Regularly review and update your templates

**Happy JIRA automating! 🚀**

---
*Team Setup Guide - Version 1.0.0*  
*Last Updated: September 20, 2025*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/jira-mcp/TEAM_SETUP_GUIDE.md