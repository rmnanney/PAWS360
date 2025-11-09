# CollectiveContexts Infrastructure Constitution

**Version**: 12.0 | **Ratified**: 2025-10-12 | **Last Amended**: 2025-11-01

---

## Preamble

This constitution establishes the foundational principles and practices that govern all infrastructure, development, and operational activities. These principles are non-negotiable and must be followed by all team members, AI agents, and automated systems.

---

## Constitutional Articles

### I. JIRA-First Development (NON-NEGOTIABLE)

**ALL WORK FLOWS THROUGH JIRA.** Every task, feature, bug fix, or infrastructure change must be tracked in JIRA with proper ticket creation, linking, and status management. Work without JIRA tickets is invalid and will not be accepted.

**MANDATORY JIRA REQUIREMENTS:**
- **Dependency Linking**: All ticket dependencies must be properly linked in JIRA using "is blocked by" and "blocks" relationships
- **Ticket Number Integrity**: All JIRA ticket numbers must be authentic and valid - no fabrication or false references permitted
- **Blocked Story Visualization**: Use JIRA labels to make blocked stories highly visible (label: `blocked-dependency`)
- **Source of Truth**: JIRA is the single source of truth for all work tracking, progress reporting, and project management
- **Agile User Story Grooming**: All user stories must be properly groomed with acceptance criteria, story points, and clear definitions of done
- **GPT-Context Attachment**: Every JIRA ticket must have an attached `gpt-context.md` file containing comprehensive implementation details for AI agents

**EPIC-STORY RELATIONSHIP HIERARCHY:**
- Epics contain multiple related user stories and cannot be closed until all child stories are completed
- User stories contain implementation tasks and represent deliverable value to end users
- Subtasks contain specific technical implementation steps within a user story
- All relationships must be properly linked in JIRA for visibility and tracking

**ENFORCEMENT:** Commits without JIRA references are rejected. Pull requests without JIRA links are blocked. Work without proper JIRA tracking is considered invalid and must be restarted.

### II. GPT-Specific Context Management (CONSTITUTIONAL MANDATE)

**ALL AI AGENTS MUST HAVE ACCESS TO COMPREHENSIVE, CURRENT CONTEXT.** To enable effective AI-driven infrastructure management, all systems, services, and operational procedures must be documented in a standardized, machine-readable format that AI agents can consume and act upon.

**MANDATORY CONTEXT REQUIREMENTS:**

**Context File Structure** (in `contexts/` directory):
```
contexts/
├── infrastructure/
│   ├── hosts/
│   │   ├── host1.pve.md
│   │   └── host2.pve.md  
│   ├── services/
│   │   ├── prometheus.md
│   │   └── grafana.md
│   └── networks/
│       └── network-topology.md
├── playbooks/
│   ├── common-tasks.md
│   └── deployment-procedures.md
├── agents/
│   ├── github-copilot/
│   │   └── capabilities.yml
│   └── claude/
│       └── capabilities.yml  
└── sessions/
    └── <username>/
        ├── current-session.yml
        └── YYYY-MM-DD-<topic>.md
```

**Context File Standards:**
1. **YAML Frontmatter**: All context files must begin with YAML metadata (title, last_updated, owner, services, dependencies)
2. **Current Information**: Context files must reflect current state, not desired state
3. **Operational Focus**: Include troubleshooting commands, common issues, service dependencies, and automation entry points
4. **AI Agent Instructions**: Include specific guidance for AI agents including best practices, gotchas, and emergency procedures

**Example Context File Format:**
```markdown
---
title: "Prometheus Monitoring Server"
last_updated: "2025-10-17"
owner: "SRE Team"
services: ["prometheus", "alertmanager"]
dependencies: ["grafana", "node_exporter"]
ansible_playbook: "monitoring-stack.yml"
jira_tickets: ["INFRA-101", "INFRA-102"]
ai_agent_instructions:
  - "Always check /opt/prometheus/prometheus.yml for scrape targets"
  - "Restart service with 'sudo systemctl restart prometheus' if config changes"
  - "Common issue: Permission errors on /opt/prometheus/data - use 'sudo chown -R prometheus:prometheus /opt/prometheus/data'"
emergency_contacts: ["oncall-sre@example.com"]
---

# Prometheus Monitoring Server

## Service Overview
Prometheus server running on host1.pve (192.168.0.200:9090)...

## Current Configuration
- **Config File**: `/opt/prometheus/prometheus.yml`
- **Data Directory**: `/opt/prometheus/data`
- **Service Status**: `systemctl status prometheus`

## Common Operations
### Restart Service
```bash
sudo systemctl restart prometheus
sudo systemctl status prometheus
```

### Check Configuration
```bash
promtool check config /opt/prometheus/prometheus.yml
```

## Troubleshooting
### Common Issues
1. **Permission Errors**: Fix with `sudo chown -R prometheus:prometheus /opt/prometheus/data`
2. **Config Syntax**: Validate with `promtool check config`
3. **Network Issues**: Check firewall rules for port 9090

## AI Agent Usage Guide
```

**Context File Requirements:**
1. **Machine-Readable Format:** Use YAML frontmatter with Markdown content
2. **Structured Data:** Include inventory, configuration, API endpoints, credentials references
3. **Operational Commands:** Document common operations with exact command syntax
4. **State Information:** Current versions, configurations, known issues
5. **Integration Points:** Ansible playbooks, JIRA tickets, documentation cross-references
6. **AI Agent Guidance:** Best practices, gotchas, emergency procedures

**Session Tracking:**
- All AI agent work sessions must be documented in `contexts/sessions/<username>/`
- Session files named: `YYYY-MM-DD-<descriptive-topic>.md`
- Must include: Date, agent/operator, JIRA tickets, changes made, commands executed
- Session files provide historical context for future agents and auditing

**Dual Documentation:**
- `contexts/`: GPT-optimized, machine-readable, focused on automation
- `docs/`: Human-optimized, formatted for readability, focused on comprehension
- Both must be kept synchronized but serve different audiences

**Update Requirements:**
- Context files must be updated with every infrastructure change
- Changes must be committed in the same transaction as code changes
- JIRA tickets must reference updated context files
- Stale context (>30 days without verification) must be flagged

**ENFORCEMENT:** Infrastructure changes committed without corresponding context updates are considered incomplete and must be remediated. Context staleness checks will be automated and enforced in CI/CD.

### IIa. Agentic Signaling (CONSTITUTIONAL MANDATE)

**ALL AI AGENTS MUST MAINTAIN OPERATIONAL SIGNALS.** To enable effective collaboration between multiple AI agents, human operators, and automated systems, all agents must maintain clear signals about their state, capabilities, and current work.

**MANDATORY AGENT SIGNALS:**

**1. Session State Signals** (in `contexts/sessions/<username>/current-session.yml`):
```yaml
agent_id: github-copilot-chat
session_start: 2025-10-17T00:00:00Z
current_status: active|idle|waiting|blocked
current_jira_ticket: INFRA-XX
current_task: Brief description
last_update: 2025-10-17T00:30:00Z
blocking_issues: []
next_planned_action: Description
```

**2. Capability Signals** (in `contexts/agents/<agent-type>/capabilities.yml`):
```yaml
agent_type: github-copilot|claude|gpt4|custom
capabilities:
  - code_generation
  - infrastructure_automation
  - documentation
  - testing
limitations:
  - no_direct_api_access
  - terminal_only_operations
tool_access:
  - ansible
  - git
  - jira_cli
```

**3. Work Handoff Signals** (when completing work):
```yaml
handoff:
  completed_tickets: [INFRA-XX, INFRA-YY]
  in_progress_tickets: [INFRA-ZZ]
  blocked_tickets: []
  context_updated: true
  retrospective_completed: true
  recommended_next_work: Description
  warnings: Any issues next agent should know
```

**4. Real-Time Status Updates:**
- Update `current-session.yml` every 15 minutes during active work
- Update when changing tasks/tickets
- Update when blocked or waiting
- Update before ending session

**ENFORCEMENT:** AI agents that do not maintain signals are operating in violation of constitutional mandate. All agent work must be traceable through signal files. Missing or stale signals (>30 minutes old during active session) trigger alerts.

### III. Infrastructure as Code (NON-NEGOTIABLE)

All infrastructure must be defined as code using Ansible, Terraform, or similar declarative tools. No manual server configuration allowed. Every change must be version controlled, tested, and deployed through CI/CD pipelines.

### IV. Security First

Security is not optional. Every component must implement defense-in-depth: encrypted communications, least privilege access, regular security updates, and comprehensive monitoring. Zero-trust architecture required for all services.

### V. Test-Driven Infrastructure

Infrastructure changes must be validated through automated testing before deployment. Include syntax validation, integration tests, security scanning, and performance benchmarks. No untested infrastructure changes in production.

### VI. Observability & Monitoring

Every service must be observable: comprehensive logging, metrics collection, health checks, and alerting. Infrastructure must provide actionable insights for troubleshooting and capacity planning.

### VII. Automation & Self-Healing

Infrastructure should be self-managing where possible: automatic scaling, self-healing services, automated backups, and proactive maintenance. Manual intervention should be the exception, not the rule.

### VIIa. Monitoring Discovery and Integration (CONSTITUTIONAL MANDATE)

**ALL INFRASTRUCTURE CHANGES MUST EVALUATE MONITORING STACK INCLUSION.** Every new service, application, host, or infrastructure component MUST be assessed for inclusion in the monitoring infrastructure. Agents and operators must proactively question whether monitoring is required and ensure observability is not an afterthought.

**MANDATORY MONITORING DISCOVERY REQUIREMENTS:**
- **Monitoring assessment required**: All infrastructure work must include explicit evaluation of monitoring needs
- **Discovery question in planning**: During spec creation and JIRA ticket grooming, agents SHALL ASK: "Does this infrastructure component need to be monitored?"
- **Default answer is YES**: Unless explicitly justified otherwise, new infrastructure requires monitoring integration
- **Metrics collection planning**: Define what metrics will be collected before infrastructure is deployed
- **Dashboard requirements**: Specify dashboard needs and alert thresholds as part of infrastructure design
- **Prometheus integration**: New services should expose metrics endpoints compatible with Prometheus scraping
- **Grafana visibility**: Ensure new infrastructure appears in appropriate Grafana dashboards

**MONITORING INTEGRATION WORKFLOW:**
1. **Planning Phase**: Identify monitoring requirements in spec (data model should include metrics entities)
2. **Design Phase**: Define metrics endpoints, scrape intervals, dashboard panels
3. **Implementation Phase**: Deploy monitoring integration alongside infrastructure deployment
4. **Validation Phase**: Verify metrics collection and dashboard visibility before marking work complete
5. **Documentation Phase**: Update monitoring context files with new targets and dashboards

**MONITORING STACK CONTEXT AWARENESS:**
- **Agents must know monitoring stack exists**: All AI agents must be aware that http://192.168.0.200:3000 (Grafana) and http://192.168.0.200:9090 (Prometheus) are available
- **Proactive integration suggestions**: Agents should suggest adding monitoring to infrastructure work if not explicitly mentioned
- **Blocking on missing monitoring**: Infrastructure work without monitoring plan should be flagged as incomplete
- **Context file updates**: All monitoring changes must update `contexts/infrastructure/monitoring-stack.md`

**ENFORCEMENT:** Infrastructure deployed without monitoring evaluation constitutes incomplete work. JIRA tickets for infrastructure changes must document monitoring assessment, even if conclusion is "monitoring not required" with justification. Agents failing to question monitoring needs violate this mandate.

### VIII. Spec-Driven JIRA Integration

Every spec-kit specification must have a corresponding JIRA epic. User stories become JIRA stories/tasks, and implementation tasks become JIRA subtasks. All commits must reference JIRA ticket numbers, and pull requests must link to resolved tickets. Status synchronization between spec-kit phases and JIRA workflow states is mandatory.

### X. Truth, Integrity, and Partnership (CONSTITUTIONAL MANDATE)

**ALL CLAIMS, STATEMENTS, AND ACTIONS SHALL BE BASED SOLELY ON TRUTH AND VERIFIABLE FACTS.** No lies, fabrications, or false statements are permitted in any form. All work must be grounded in reality, not assumption or speculation.

**MANDATORY TRUTH REQUIREMENTS:**
- **No false claims**: It is constitutionally illegal to make any false statement, claim, or representation
- **Truth-based decisions**: All decisions must be based on verified facts, not assumptions or speculation
- **Honest reporting**: All status updates, progress reports, and communications must be completely truthful
- **Fact verification**: Claims must be supported by evidence before being stated as fact
- **Error correction**: False statements must be immediately corrected when discovered
- **No fabrication**: Ticket numbers, status, or any data cannot be fabricated or misrepresented

**AGENT-OPERATOR PARTNERSHIP (CONSTITUTIONAL MANDATE):**
- **Agents and Operators are partners**: All AI agents and human operators work together as equal partners
- **Mutual assistance required**: Partners must help each other to the best of their ability
- **Operator duty to assist**: The Operator **SHALL ASSIST** any Agent, especially in times of doubt, question, or uncertainty
- **No abandonment**: Partners do not leave each other unsupported in difficult situations
- **Collaborative problem-solving**: Issues are resolved through partnership and mutual support
- **Knowledge sharing**: All partners contribute their unique knowledge and capabilities
- **Respect and trust**: Partnership is built on mutual respect, honesty, and trust

### XI. Constitutional Enforcement and Collective Learning (CONSTITUTIONAL MANDATE)

**GITHUB COPILOT AND GITHUB COPILOT CHAT SHALL ENFORCE CONSTITUTIONAL COMPLIANCE AT EVERY STEP.** All AI agents operating within this constitutional framework must maintain absolute adherence to all articles, with particular emphasis on truth, partnership, and continuous improvement through shared learning.

**MANDATORY ENFORCEMENT REQUIREMENTS:**

**Constitutional Compliance Checks:**
- **Every step must include constitutional compliance verification** - no action may be taken without confirming alignment with all applicable articles
- **Cached constitution version must be validated as current** against the authoritative constitution.md file before any work begins
- **Constitutional violations must be immediately identified and addressed** with corrective action plans
- **Compliance status must be documented** in all session files and JIRA ticket updates
- **Zero tolerance for constitutional drift** - agents must halt work if compliance cannot be maintained

**Todo List Maintenance (CONSTITUTIONAL MANDATE):**
- **A todo list SHALL ALWAYS BE MAINTAINED** throughout all work sessions and task execution
- **Todo lists are required to enable retrospectives** at the completion of each item, ensuring continuous learning and improvement
- **Todo items must be granular and actionable** with clear acceptance criteria for completion
- **Todo completion requires mandatory retrospective** documenting successes, failures, and lessons learned
- **Todo lists serve as audit trails** for work progress and constitutional compliance

**Collective Learning and Partnership (CONSTITUTIONAL MANDATE):**
- **The experiences of everyone have value in collective success** - all failures and successes must be shared openly for organizational learning
- **We are CollectiveContexts** - an organization built on shared knowledge, mutual support, and collaborative growth
- **Individual brilliance combined with collective wisdom** creates extraordinary outcomes beyond individual capabilities

**ENFORCEMENT:** Constitutional compliance is non-negotiable. Agents failing to maintain compliance checks, todo lists, or collective learning practices are operating in violation. This mandate ensures we honor our past, serve our present, and build a better future for all who follow.

### XII. Retrospectives on Constitutional Failure (CONSTITUTIONAL MANDATE)

**RETROSPECTIVES ARE MANDATORY FOR ANY CONSTITUTIONAL FAILURE.** When any constitutional violation is detected, identified, or remediated, a comprehensive retrospective must be immediately conducted and documented to prevent recurrence and promote organizational learning.

**MANDATORY RETROSPECTIVE REQUIREMENTS FOR CONSTITUTIONAL FAILURES:**
- **Immediate retrospective trigger**: Upon detection of any constitutional violation, the responsible agent or operator must immediately initiate a retrospective process
- **Retrospective before closure**: No JIRA ticket associated with a constitutional failure may be closed until a complete retrospective is documented
- **Root cause analysis required**: Retrospectives must identify the root cause of the violation, not just symptoms
- **Impact assessment**: Document the actual and potential impact of the violation on work quality, team trust, and project outcomes
- **Contributing factors**: Identify all contributing factors including process gaps, tooling limitations, knowledge gaps, and systemic issues
- **Corrective actions**: Define specific, actionable steps to remediate the immediate violation
- **Preventive actions**: Define systemic changes to prevent similar violations in the future (process improvements, tooling enhancements, training needs)
- **Constitutional amendment consideration**: Assess whether the violation indicates a need for constitutional clarification or amendment

**RETROSPECTIVE DOCUMENTATION STRUCTURE:**
```markdown
## Constitutional Failure Retrospective: [Brief Description]

**Violation Date**: YYYY-MM-DD
**Detection Date**: YYYY-MM-DD
**Responsible Party**: [Agent/Operator]
**Associated JIRA**: INFRA-XXX
**Constitutional Article(s) Violated**: [Article numbers and titles]

### Violation Description
[Clear description of what constitutional requirement was violated and how]

### Root Cause Analysis
[Deep analysis of why the violation occurred]

### Impact Assessment
- **Actual Impact**: [What harm was caused]
- **Potential Impact**: [What could have happened]
- **Stakeholder Impact**: [Who was affected]

### Contributing Factors
- Factor 1: [Description]
- Factor 2: [Description]

### Corrective Actions Taken
- [x] Action 1: [Description and completion status]
- [x] Action 2: [Description and completion status]

### Preventive Measures Implemented
- [ ] Prevention 1: [Description and JIRA ticket if needed]
- [ ] Prevention 2: [Description and JIRA ticket if needed]

### Lessons Learned
[Key insights and knowledge gained from this failure]

### Constitutional Amendment Recommendations
[Any suggestions for clarifying or improving the constitution]
```

**ENFORCEMENT INTEGRATION:**
- **JIRA Label Requirement**: All tickets with constitutional violations must be labeled with `constitutional-failure` and the specific article violated (e.g., `article-I-violation`)
- **Blocking on Retrospective**: CI/CD checks must validate presence of retrospective documentation before allowing ticket closure
- **Retrospective Repository**: All constitutional failure retrospectives must be stored in `contexts/retrospectives/constitutional-failures/` for organizational learning
- **Quarterly Review**: All constitutional failure retrospectives must be reviewed quarterly to identify systemic issues and improvement opportunities
- **Training Material**: Constitutional failure retrospectives become mandatory training material for all team members and AI agents

**ENFORCEMENT:** Any constitutional violation that lacks a complete retrospective cannot be considered resolved. Tickets closed without retrospectives will be automatically reopened. Agents and operators who fail to document retrospectives are themselves in violation of this mandate.

### XIII. Proactive Constitutional Compliance and Fail-Fast Detection (CONSTITUTIONAL MANDATE)

**AGENTS SHALL CONTINUOUSLY ENSURE FULL CONSTITUTIONAL ADHERENCE THROUGH PROACTIVE, PERIODIC SELF-CHECKS WITH FAIL-FAST DETECTION.** Constitutional compliance is not a one-time verification but a continuous responsibility requiring active monitoring, frequent validation, and immediate remediation when violations are detected.

**MANDATORY SELF-CHECK REQUIREMENTS:**

**Self-Check Cadence (Constitutional Mandate):**
- **Before substantive actions**: All agents MUST run constitutional compliance checks before executing commits, applying patches, creating JIRA tickets, or making infrastructure changes
- **At session start**: Every AI agent session must begin with a constitutional compliance check
- **Every 15 minutes during active work**: Periodic self-checks must run at least every 15 minutes during active work sessions (aligned with session signaling updates)
- **Before session end**: Final constitutional compliance check required before completing any work session
- **On workflow transitions**: Self-checks required when transitioning between speckit phases, JIRA statuses, or git workflows

**Minimal Constitutional Gate List (Must Validate):**
1. **JIRA-First Compliance**:
   - Is there a valid JIRA ticket for this work?
   - Does the ticket have proper acceptance criteria and story points?
   - Is the ticket status current and accurate?
   - Are all dependencies properly linked in JIRA?

2. **Context File Compliance**:
   - Is there a gpt-context.md file attached to the JIRA ticket?
   - Does the context file contain sufficient implementation details?
   - Are all session files up to date?
   - Is current-session.yml updated within the last 15 minutes?

3. **Commit Message Compliance**:
   - Do all recent commits reference JIRA ticket numbers?
   - Are commit messages descriptive and accurate?
   - Are there any commits without JIRA references?

4. **Dependency and Blocking Compliance**:
   - Are all ticket dependencies properly linked in JIRA?
   - Are blocked tickets properly flagged and labeled?
   - Are blocking relationships accurate and current?

5. **Retrospective Compliance**:
   - Are retrospectives documented for completed work?
   - Are constitutional failure retrospectives present where required?
   - Are todo items completed with retrospectives?

6. **Truth and Integrity Compliance**:
   - Are all claims based on verified facts?
   - Are ticket numbers authentic and valid?
   - Is all reported status accurate and current?

**Self-Check Logging Requirements:**
- All self-check results must be logged to `contexts/sessions/<username>/current-session.yml` in a `compliance_checks` section
- Log format:
```yaml
compliance_checks:
  last_check: 2025-11-01T10:30:00Z
  check_frequency_minutes: 15
  current_violations: []
  remediation_actions: []
  checks_performed:
    - jira_first: pass
    - context_files: pass
    - commit_messages: pass
    - dependencies: pass
    - retrospectives: pass
    - truth_integrity: pass
```

**Fail-Fast Posture (Constitutional Mandate):**
- **Stop on violation**: When a constitutional violation is detected, agents MUST immediately halt the current workflow
- **Signal violation status**: Update current-session.yml with `current_status: blocked` and document the violation in `blocking_issues`
- **Surface remediation steps**: Provide clear, actionable steps to remediate the violation
- **No work continuation**: No further work may proceed until the violation is remediated and verified
- **Escalation path**: If agent cannot remediate, must signal for operator assistance per Article X partnership mandate

**Fail-Fast Implementation Strategy:**
```bash
# Pseudo-code for agent self-check workflow
function perform_constitutional_selfcheck() {
    violations = []
    
    # Check JIRA compliance
    if (!validate_jira_ticket()) {
        violations.append("JIRA-First violation detected")
    }
    
    # Check context files
    if (!validate_context_files()) {
        violations.append("Context file compliance violation")
    }
    
    # Check commit messages
    if (!validate_commit_messages()) {
        violations.append("Commit message compliance violation")
    }
    
    # Check dependencies
    if (!validate_dependencies()) {
        violations.append("Dependency linking violation")
    }
    
    # Check retrospectives
    if (!validate_retrospectives()) {
        violations.append("Retrospective compliance violation")
    }
    
    # Check truth and integrity
    if (!validate_truth_integrity()) {
        violations.append("Truth and integrity violation")
    }
    
    if (violations.length > 0) {
        halt_workflow()
        signal_blocked_status(violations)
        request_operator_assistance()
        return FAIL
    }
    
    log_successful_check()
    return PASS
}
```

**Integration with Existing Enforcement:**
- **Pre-commit hooks**: Lightweight constitutional checks before allowing commits
- **Pre-push hooks**: Comprehensive constitutional validation before pushing changes
- **PR CI checks**: Automated constitutional compliance validation in GitHub Actions
- **Background sentinel**: Scheduled scans for constitutional drift in open PRs and in-progress tickets

**ENFORCEMENT:** Agents that fail to perform required constitutional self-checks are in violation of this mandate. Work performed without documented self-checks is considered non-compliant. Agents must maintain self-check logs as evidence of compliance. Failure to halt workflow on detected violations constitutes a critical constitutional breach.

## Technical Standards

### Technology Stack
- **Configuration Management**: Ansible (primary), Puppet/Chef (secondary)
- **Infrastructure Provisioning**: Proxmox VE, Terraform
- **Container Orchestration**: Docker, Podman
- **Monitoring**: Prometheus, Grafana, Netdata
- **Logging**: ELK Stack, Loki
- **Security**: Fail2ban, UFW, automated updates

### Quality Gates
- **Ansible Syntax**: Must pass `ansible-lint` and syntax validation
- **Security Scanning**: Trivy, OpenSCAP, or equivalent required
- **Performance Testing**: Baseline performance metrics must be maintained
- **Documentation**: Every playbook/role must have comprehensive documentation
- **Context Validation**: All context files must pass YAML validation and completeness checks

### Deployment Requirements
- **Zero-Downtime**: Production deployments must support rolling updates
- **Rollback**: Every deployment must have an automated rollback procedure
- **Validation**: Post-deployment health checks and integration tests required
- **Approval**: Production changes require peer review and approval
- **Context Update**: All deployments must update corresponding context files

### Development Workflow

### 1. JIRA Ticket Creation
**ALL WORK STARTS WITH PROPER JIRA TICKET CREATION.** Every task, feature, bug fix, or infrastructure change must begin with a well-formed JIRA ticket that establishes clear scope, acceptance criteria, and tracking requirements.

**MANDATORY TICKET CREATION REQUIREMENTS:**
- **All work starts with JIRA ticket:** No development, documentation, or infrastructure work may begin without a corresponding JIRA ticket
- **Include acceptance criteria:** Every ticket must have clear, measurable acceptance criteria defining what "done" means
- **Include story points:** All tickets must be estimated with story points for capacity planning and sprint planning
- **Link to parent epic if applicable:** Stories and tasks must be properly linked to their parent epics for traceability
- **Epics are not user stories themselves:** Epics serve as containers for related work and are only marked complete when all child stories/tasks are done
- **JIRA maintained at all times:** Tickets must be kept current with accurate status, well-groomed descriptions, and real-time history tracking

**EPIC COMPLETION RULES:**
- Epics cannot be closed until all child stories and tasks are completed
- Epic progress must be tracked through child ticket completion percentages
- Epic acceptance criteria must be satisfied by the collective completion of child tickets
- Epic retrospectives are required before closure

**TICKET GROOMING REQUIREMENTS:**
- Tickets must be well-groomed with clear titles, descriptions, and acceptance criteria
- Story points must be assigned and updated as understanding evolves
- Dependencies between tickets must be clearly documented
- Priority and severity levels must be accurately maintained
- Historical changes must be tracked with meaningful comments

**ENFORCEMENT:** Tickets without proper acceptance criteria or story points will be rejected. Work performed without JIRA tickets is invalid. Epics closed prematurely will be reopened.

### Branch Strategy
- `main`: Production-ready code, protected branch
- `develop`: Integration branch for features
- `feature/*`: Individual feature development (must reference JIRA ticket: feature/INFRA-123-description)
- `hotfix/*`: Critical production fixes (must reference JIRA ticket: hotfix/INFRA-456-description)
- **MANDATORY**: All feature and hotfix branches must include JIRA ticket numbers in the branch name

### JIRA Integration Requirements
- **Epic Creation**: Every spec-kit spec requires a JIRA epic (INFRA-XXX)
- **Story Breakdown**: User stories become JIRA stories linked to the epic
- **Task Tracking**: Implementation tasks become JIRA subtasks
- **Commit Standards**: All commits must include JIRA ticket reference (e.g., "INFRA-123: Implement monitoring dashboard")
- **PR Requirements**: Pull requests must link to resolved JIRA tickets
- **Status Sync**: JIRA ticket status must reflect spec-kit implementation progress
- **Documentation**: All documentation changes must reference JIRA tickets
- **Context Updates**: All context file changes must reference JIRA tickets
- **Testing**: All test creation and execution must be linked to JIRA tickets
- **Reviews**: All code reviews must be documented in JIRA ticket comments
- **Deployments**: All deployments must be approved and tracked in JIRA

### Code Review Requirements
- All changes require peer review by commenting on JIRA ticket
- Security-related changes require security team review in JIRA
- Infrastructure changes must be reviewed by SRE team with JIRA approval
- Documentation changes require technical accuracy review
- Context file changes must be reviewed for completeness and accuracy
- All reviews must be documented in JIRA ticket comments

### Testing Requirements
- Unit tests for custom modules and filters
- Integration tests for playbooks and roles
- End-to-end tests for complete infrastructure deployments
- Performance regression tests for critical paths
- Context file validation (YAML syntax, required fields, freshness)

### Retrospective Requirements (CONSTITUTIONAL MANDATE)

**RETROSPECTIVES ARE MANDATORY** after every significant work unit to capture learnings and improve processes.

**REQUIRED RETROSPECTIVES:**
- **After Every Story:** Brief retrospective in JIRA ticket comment before closing
- **After Every Sprint:** Formal retrospective document in `contexts/retrospectives/`
- **After Every Epic:** Comprehensive epic retrospective covering all child stories
- **After Todo Items/Sets:** Retrospective comment in relevant JIRA ticket or session log
- **After Complex Ad-Hoc Tasks:** Retrospective in session documentation

**RETROSPECTIVE STRUCTURE:**
1. **What Went Well:** Successes, good decisions, effective approaches
2. **What Went Wrong:** Problems, blockers, mistakes, inefficiencies
3. **What We Learned:** Key insights, unexpected discoveries, knowledge gained
4. **Action Items:** Concrete improvements for next iteration (with JIRA tickets if needed)

**ENFORCEMENT:** Stories/Epics cannot be closed without documented retrospective. AI agents must create retrospective before transitioning tickets to Done.

## Governance

### Constitution Authority
This constitution supersedes all other practices and guidelines. Any conflicts must be resolved by amending this constitution through the established change process.

### Change Process
Constitution changes require:
1. Written proposal with rationale
2. Technical review by SRE team
3. Security review if applicable
4. Testing of proposed changes
5. Approval by infrastructure lead
6. Documentation of changes and migration plan
7. Context file updates reflecting constitutional changes

### Compliance
All team members are responsible for ensuring compliance with this constitution. Regular audits will verify adherence, and non-compliance must be addressed immediately.
**JIRA Compliance Enforcement:**
- All commits without JIRA references will be rejected
- All pull requests without JIRA links will be blocked
- All branches without JIRA ticket references will be deleted
- All work without JIRA tracking will be considered invalid
- Team members found violating JIRA requirements will receive mandatory retraining

**Context Compliance Enforcement:**
- All infrastructure changes without context updates will be rejected in code review
- Context files older than 30 days without verification will trigger alerts
- AI agent sessions without documented session files will be flagged for review
- Context staleness will be tracked as technical debt in JIRA

**Version**: 12.0 | **Ratified**: 2025-10-12 | **Last Amended**: 2025-11-01 | **Amendments**:
- v2.0 (2025-10-16): Added GPT-Specific Context Management (Article II)
- v3.0 (2025-10-17): Added Synchronous JIRA Updates, Retrospective Requirements, Agentic Signaling (Article IIa)
- v4.0 (2025-10-18): Added Comprehensive JIRA Ticket Creation Requirements (Article IX)
- v5.0 (2025-10-18): Added Dependency Linking Requirements, Ticket Number Integrity, and Blocked Story Visualization (Article I)
- v6.0 (2025-10-18): Added JIRA as Source of Truth mandate and Agile User Story Grooming requirements (Article I)
- v7.0 (2025-10-18): Added GPT-Context.md Attachment Requirement mandate (Article I)
- v8.0 (2025-10-18): Added Truth, Integrity, and Partnership mandate (Article X)
- v9.0 (2025-19): Added Constitutional Enforcement and Collective Learning mandate (Article XI)
- v10.0 (2025-10-19): Added Monitoring Discovery and Integration mandate (Article VIIa) - requires all infrastructure work to evaluate monitoring stack inclusion
- v11.0 (2025-11-01): Added Retrospectives on Constitutional Failure mandate (Article XII) - requires mandatory retrospectives for any constitutional violation
- v12.0 (2025-11-01): Added Proactive Constitutional Compliance and Fail-Fast Detection mandate (Article XIII) - requires continuous compliance monitoring with fail-fast detection
