# JIRA MCP Server - Quick Reference Card

## 🚀 **Quick Start**
```bash
# Set environment
source docs/jira-mcp/setup_jira_env.sh

# Start server
PYTHONPATH=/home/ryan/repos/PAWS360ProjectPlan/src python -m cli serve
```

## 📋 **Essential Commands**

### **Create Story**
```json
{
  "name": "create_workitem",
  "arguments": {
    "summary": "As a student, I want to log in",
    "description": "Secure authentication system",
    "issue_type": "Story"
  }
}
```

### **Search Stories**
```json
{
  "name": "search_workitems",
  "arguments": {
    "jql": "project = PGB AND issuetype = Story AND status != Done"
  }
}
```

### **Update Story**
```json
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
```

## 🎯 **Common JQL Queries**

| Query | Description |
|-------|-------------|
| `project = PGB AND status = "To Do"` | Open items |
| `project = PGB AND assignee = currentUser()` | My items |
| `project = PGB AND priority = High` | High priority |
| `project = PGB AND sprint in openSprints()` | Current sprint |
| `project = PGB AND issuetype = Bug` | All bugs |
| `project = PGB AND created > -7d` | Created this week |

## 📝 **Story Templates**

### **User Story**
```
As a [user], I want [functionality] so that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

### **Bug Report**
```
**Summary:** [Brief description]

**Steps:** 1. [Step 1] 2. [Step 2] 3. [Step 3]

**Expected:** [Expected result]
**Actual:** [Actual result]
```

### **Task**
```
**Summary:** [Brief description]

**Description:** [Detailed description]

**Sub-tasks:**
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
```

## 🔧 **Bulk Operations**

### **Update Multiple Issues**
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

### **Add to Sprint**
```json
{
  "name": "assign_to_sprint",
  "arguments": {
    "issue_keys": ["PGB-123", "PGB-124"],
    "sprint_id": 123
  }
}
```

## 📊 **Sprint Management**

### **Create Sprint**
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

### **Sprint Capacity Report**
```json
{
  "name": "get_sprint_capacity_report",
  "arguments": {
    "sprint_id": 123
  }
}
```

## 👥 **Team Operations**

### **Assign Team**
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

### **Team Workload**
```json
{
  "name": "get_team_workload",
  "arguments": {
    "team_id": "frontend-team",
    "sprint_id": 123
  }
}
```

## 🔍 **Search Shortcuts**

| Shortcut | JQL Query |
|----------|-----------|
| `my work` | `assignee = currentUser() AND status != Done` |
| `open bugs` | `issuetype = Bug AND status != Done` |
| `this sprint` | `sprint in openSprints()` |
| `high priority` | `priority = High AND status != Done` |
| `recent` | `created > -7d` |
| `blocked` | `status = "Blocked"` |

## ⚡ **Power User Tips**

### **1. Combine Operations**
```json
// Create and assign in one go
{
  "name": "create_workitem",
  "arguments": {
    "summary": "New feature",
    "description": "Feature description",
    "issue_type": "Story"
  }
}
// Then assign to sprint and team
```

### **2. Use Variables**
```bash
# Store issue key for reuse
ISSUE_KEY="PGB-123"

# Update multiple times
{
  "name": "update_workitem",
  "arguments": {
    "issue_key": "$ISSUE_KEY",
    "updates": {"status": "In Progress"}
  }
}
```

### **3. Batch Processing**
```bash
# Process multiple issues
for issue in "PGB-123 PGB-124 PGB-125"; do
  echo "Updating $issue..."
  # Update each issue
done
```

## 🚨 **Quick Troubleshooting**

| Problem | Solution |
|---------|----------|
| `API key invalid` | Regenerate token at id.atlassian.com |
| `Connection timeout` | Check network, increase `JIRA_TIMEOUT` |
| `403 Forbidden` | Verify project permissions |
| `Rate limit` | Reduce `JIRA_RATE_LIMIT`, add delays |
| `Module not found` | Set `PYTHONPATH` correctly |

## 📞 **Help Resources**

- **Full Documentation:** `docs/jira-mcp/README.md`
- **Team Setup:** `docs/jira-mcp/TEAM_SETUP_GUIDE.md`
- **Examples:** `docs/jira-mcp/mcp_examples.json`
- **Configuration:** `docs/jira-mcp/setup_jira_env.sh`

## 🎯 **Daily Workflow**

1. **Morning:** Check assigned items
   > "Show me my open stories"

2. **Planning:** Create new stories
   > "Create a story for [feature]"

3. **Updates:** Update progress
   > "Update PGB-123 to In Progress"

4. **Reviews:** Check team status
   > "Show sprint capacity report"

---

**Keep this card handy for quick reference!** 📌

*Version 1.0.0 - September 20, 2025*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/docs/jira-mcp/QUICK_REFERENCE_CARD.md