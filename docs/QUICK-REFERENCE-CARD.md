# 🚀 PAWS360 Quick Reference Card

## ⚡ Daily Commands

### Start Your Day
```bash
cd ~/repos/PAWS360ProjectPlan
git pull origin main
git status
```

### Create New Feature
```bash
./scripts/create-new-feature.sh "feature-name"
```

### Check JIRA Status
```bash
# Open in browser
open https://paw360.atlassian.net/browse/PGB
```

## 📋 File Locations (Memorize!)

| What I Need | Where to Find It |
|-------------|------------------|
| Feature specs | `specs/###-feature/spec.md` |
| Implementation plan | `specs/###-feature/plan.md` |
| Task breakdown | `specs/###-feature/tasks.md` |
| Code templates | `templates/` |
| Helper scripts | `scripts/` |
| Project rules | `memory/constitution.md` |

## 🔄 Development Workflow

### Step 1: Get Assigned
```
JIRA Ticket → Assign to yourself → Move to "In Progress"
```

### Step 2: Create Feature Branch
```bash
git checkout -b feature/PGB-123-user-login
```

### Step 3: Write Code
```
Edit files → Test locally → Commit changes
```

### Step 4: Push & Create PR
```bash
git add .
git commit -m "feat: add user login functionality"
git push origin feature/PGB-123-user-login
# Create Pull Request in GitHub
```

## 🧪 Testing Checklist

### Before Committing
- [ ] Code runs without errors
- [ ] Basic functionality works
- [ ] No console errors
- [ ] Tests pass (if any)

### Before PR
- [ ] All acceptance criteria met
- [ ] Code reviewed by teammate
- [ ] Tests added/updated
- [ ] Documentation updated

## 🚨 When Stuck

### Quick Fixes
```
❓ Can't find file?     → Check FILE-STRUCTURE-GUIDE.md
❓ Git problem?         → Ask team or check Git docs
❓ JIRA issue?          → Screenshot + ask in Slack
❓ Code not working?    → Add console.log + test step-by-step
```

### Get Help Fast
```
1. Check existing documentation
2. Search in team Slack history
3. Ask specific question in Slack
4. Schedule 15-min call if needed
```

## 🎯 Success Metrics

### Daily Goals
- [ ] At least 3 commits
- [ ] JIRA ticket updated
- [ ] Code reviewed or reviewed others
- [ ] Learned something new

### Weekly Goals
- [ ] Complete assigned tasks
- [ ] Help at least 1 teammate
- [ ] Update documentation
- [ ] Participate in all meetings

## 📝 Commit Message Format

### Good Examples
```bash
feat: add user authentication
fix: resolve login timeout issue
docs: update API documentation
test: add unit tests for user service
```

### Bad Examples (Don't Do!)
```bash
fixed stuff
update
changes
wip
```

## 🏷️ JIRA Status Updates

### When Starting Work
```
Status: To Do → In Progress
Comment: "Starting work on this task"
```

### When Complete
```
Status: In Progress → Done
Comment: "Completed all acceptance criteria"
```

### When Blocked
```
Status: In Progress → Blocked
Comment: "Blocked by: [specific issue]"
```

## 🎨 Code Style Reminders

### JavaScript/React
```javascript
// ✅ Good
const userName = getUserName();
const isValid = validateEmail(email);

// ❌ Bad
const username = getusername();
const valid = validateemail(email);
```

### General Rules
- Use descriptive variable names
- Add comments for complex logic
- Keep functions under 20 lines
- Use consistent formatting

## 🚀 Deployment Checklist

### Before Deploy
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] JIRA ticket closed
- [ ] No console errors

### After Deploy
- [ ] Test in production
- [ ] Monitor for errors
- [ ] Update stakeholders
- [ ] Celebrate! 🎉

---

## 📞 Emergency Contacts

| Situation | Contact | Response Time |
|-----------|---------|---------------|
| System down | Ryan | Immediate |
| Can't access JIRA | IT Support | 1 hour |
| Git repository issue | Ryan | 30 minutes |
| General question | Team Slack | 15 minutes |

---

*Keep this card open in your browser! 📌*
*Updated: September 18, 2025*</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/QUICK-REFERENCE-CARD.md