# JIRA User Stories Import Guide

This guide explains how to import the AdminLTE user stories CSV into JIRA for project management.

## Prerequisites
- JIRA administrator access or project permissions
- CSV file: `jira-user-stories-import.csv` (16 comprehensive user stories)
- Understanding of your JIRA project structure

## Step 1: Prepare JIRA Project
1. Create or navigate to your JIRA project (e.g., "PAWS360 Admin Dashboard")
2. Ensure you have the following Issue Types available:
   - **Story** (primary type used)
   - **Epic** (optional, for grouping)
3. Create custom fields if needed:
   - **Story Points** (numeric field for estimation)
   - **Labels** (multi-value field for categorization)

## Step 2: Create Epics (Optional but Recommended)
Before importing stories, create these epics to organize work:

| Epic Key | Epic Name | Description |
|----------|-----------|-------------|
| ADMIN-1 | Foundation & Security | Core admin infrastructure, authentication, RBAC |
| ADMIN-2 | Data Management | Student/course management interfaces |
| ADMIN-3 | Analytics & Reporting | Dashboard analytics, reports, system config |
| DEPLOY-1 | Deployment & Operations | DevOps, automation, performance |

## Step 3: Import CSV to JIRA

### Method A: JIRA Web Interface
1. Navigate to **Issues** → **Import Issues** → **CSV**
2. Select the `jira-user-stories-import.csv` file
3. Configure field mappings:

   | CSV Column | JIRA Field | Notes |
   |------------|------------|-------|
   | Summary | Summary | Story title |
   | Description | Description | Full technical context |
   | Issue Type | Issue Type | Should be "Story" |
   | Priority | Priority | Critical/High/Medium/Low |
   | Labels | Labels | Comma-separated tags |
   | Story Points | Story Points | Fibonacci estimation |
   | Epic Link | Epic Link | Links to epics created above |
   | Assignee | Assignee | Can be left blank initially |
   | Sprint | Sprint | Can be assigned later |

4. **Review mapping** - ensure all fields align correctly
5. **Import preview** - validate 16 stories will be created
6. **Complete import**

### Method B: JIRA CLI (if available)
```bash
# Example using jira-cli tool
jira import csv --file jira-user-stories-import.csv --project ADMIN
```

## Step 4: Post-Import Configuration

### 1. Verify Stories
- Check all 16 stories imported successfully
- Verify story points total: **127 points** (typical 3-4 sprints)
- Confirm epic links are working

### 2. Sprint Planning
**Recommended sprint breakdown:**
- **Sprint 1 (29 pts)**: Foundation stories - AdminLTE setup, RBAC, SAML2
- **Sprint 2 (34 pts)**: Core functionality - Student/Course management, Analytics
- **Sprint 3 (40 pts)**: Advanced features - System config, Alerts, Communication
- **Sprint 4 (24 pts)**: Polish & deployment - Audit reports, Export, DevOps

### 3. Assign Teams
Update assignee fields based on your team:
- **Backend Dev**: Security, API, database stories
- **Frontend Dev**: UI/UX, AdminLTE, dashboard stories  
- **Full Stack Dev**: Integration stories
- **DevOps Engineer**: Deployment, performance stories
- **Security/Compliance**: Audit, accessibility stories

### 4. Customize Workflows
Configure JIRA workflows for story progression:
- **To Do** → **In Progress** → **Code Review** → **Testing** → **Done**
- Add story acceptance criteria from descriptions
- Set up automated transitions if desired

## Step 5: Quality Assurance

### Validate Import Success
- [ ] All 16 stories imported
- [ ] Story points sum to 127
- [ ] Epic links functional  
- [ ] Labels properly categorized
- [ ] Priorities correctly set
- [ ] Technical context preserved in descriptions

### Test JIRA Functionality
- [ ] Create sample sprint and add stories
- [ ] Test filtering by labels (authentication, ui, security, etc.)
- [ ] Verify epic rollup shows story count/points
- [ ] Test bulk editing capabilities
- [ ] Confirm reporting works with imported data

## Story Quality Standards

Each imported story follows best practices:

### 1. **Clear User Perspective**
- "As a [role], I need [functionality] so that [benefit]"
- Real personas: staff member, registrar, dean, advisor, etc.

### 2. **Comprehensive Technical Context**
- **Implementation details**: Specific technologies, frameworks, versions
- **Component specifications**: Exact files, classes, methods to create
- **Integration requirements**: APIs, endpoints, authentication flows
- **Configuration details**: Properties, settings, environment variables
- **Acceptance criteria**: Testable, measurable outcomes

### 3. **Proper Estimation**
- **Story points** using Fibonacci sequence (1, 2, 3, 5, 8, 13)
- Based on complexity, effort, and uncertainty
- **8+ points**: Complex integration stories requiring multiple developers
- **5 points**: Medium complexity, single developer, 2-3 days
- **3 points**: Standard development task, well-understood requirements
- **1-2 points**: Simple configuration or minor enhancements

### 4. **Categorization**
- **Labels**: Technology-focused (admin-dashboard, rbac, saml2, etc.)
- **Epics**: Functional grouping for sprint planning
- **Priorities**: Based on technical dependencies and business value

## Troubleshooting

### Common Import Issues
1. **Field mapping errors**: Double-check CSV headers match JIRA fields exactly
2. **Character encoding**: Save CSV as UTF-8 to handle special characters
3. **Epic linking**: Ensure epic keys exist before importing stories
4. **Permission errors**: Verify you have "Create Issues" permission

### Data Validation Issues
1. **Missing story points**: Add manually after import if field mapping failed
2. **Malformed labels**: Clean up comma-separated values in JIRA interface
3. **Long descriptions**: JIRA may truncate - check all technical context preserved

### Integration Issues
1. **Sprint assignment**: Use bulk edit to assign stories to sprints post-import
2. **Team assignment**: Update assignee field based on actual team members
3. **Custom fields**: Map additional fields like "Complexity" or "Technical Debt" if needed

## Best Practices for Ongoing Management

### 1. Story Refinement
- Review technical context with implementing developer
- Break down 13-point stories if team velocity suggests they're too large
- Add acceptance criteria as JIRA checklist items

### 2. Sprint Planning
- Start with Foundation stories (Epic ADMIN-1) - they unlock other work
- Balance frontend/backend work within sprints
- Include buffer time for integration testing between AdminLTE and Spring Boot

### 3. Progress Tracking
- Use JIRA burndown charts to track sprint progress
- Monitor velocity across sprints to improve estimation
- Update story status frequently to maintain visibility

---

**File Generated**: `/home/ryan/repos/PAWS360ProjectPlan/JIRA-IMPORT-HOWTO.md`  
**User Stories**: 16 comprehensive stories, 127 story points  
**Sprint Capacity**: 3-4 sprints depending on team velocity  
**Focus**: AdminLTE v4.0.0-rc4 admin dashboard with comprehensive RBAC system