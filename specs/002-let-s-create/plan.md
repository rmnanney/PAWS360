# Implementation Plan: JIRA MCP Server for PGB Project Management

**Branch**: `002-let-s-create` | **Date**: 2025-09-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-let-s-create/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
4. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
5. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, or `GEMINI.md` for Gemini CLI).
6. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
7. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
8. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Create a Model Context Protocol (MCP) server that enables seamless import and export of project data between local systems and JIRA, specifically for managing all aspects of the PGB project. The server will use the official MCP Python SDK and JIRA REST API v3 for secure, authenticated communication with the PGB project at https://paw360.atlassian.net/jira/software/projects/PGB/list.

## Technical Context
**Language/Version**: Python 3.11+  
**Primary Dependencies**: MCP Python SDK, requests, pydantic, python-jose  
**Storage**: N/A (stateless MCP server)  
**Testing**: pytest with MCP testing utilities  
**Target Platform**: Linux/macOS/Windows (cross-platform MCP server)  
**Project Type**: Single project (MCP server library)  
**Performance Goals**: <500ms response time for individual operations, <2s for bulk operations  
**Constraints**: Secure API key handling, JIRA rate limit compliance (<50 requests/minute), <100MB memory usage  
**Scale/Scope**: Support 1000+ work items, 50+ concurrent users, 10MB+ project data

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simplicity**:
- Projects: 1 (single MCP server library)
- Using framework directly? (yes - MCP SDK directly)
- Single data model? (yes - JIRA entities mapped to MCP types)
- Avoiding patterns? (yes - no unnecessary abstractions)

**Architecture**:
- EVERY feature as library? (yes - MCP server as library)
- Libraries listed: jira-mcp-server (MCP server for JIRA integration)
- CLI per library: jira-mcp-server --help/--version/--config
- Library docs: llms.txt format planned? (yes)

**Testing (NON-NEGOTIABLE)**:
- RED-GREEN-Refactor cycle enforced? (yes)
- Git commits show tests before implementation? (yes)
- Order: Contract→Integration→E2E→Unit strictly followed? (yes)
- Real dependencies used? (yes - actual JIRA API, not mocks)
- Integration tests for: new libraries, contract changes, shared schemas? (yes)
- FORBIDDEN: Implementation before test, skipping RED phase (enforced)

**Observability**:
- Structured logging included? (yes - MCP server logging)
- Frontend logs → backend? (N/A - server-only)
- Error context sufficient? (yes - JIRA error details included)

**Versioning**:
- Version number assigned? (1.0.0)
- BUILD increments on every change? (yes)
- Breaking changes handled? (yes - semantic versioning)

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

## Project Structure

### Documentation (this feature)
```
specs/002-let-s-create/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (SELECTED for MCP server)
src/
├── jira_mcp_server/
│   ├── __init__.py
│   ├── server.py         # Main MCP server implementation
│   ├── jira_client.py    # JIRA API client
│   ├── models.py         # JIRA entity models
│   ├── tools.py          # MCP tool definitions
│   └── config.py         # Configuration management
├── cli/
│   └── __main__.py       # CLI entry point
└── lib/
    └── utils.py          # Utility functions

tests/
├── contract/
│   ├── test_jira_api.py
│   └── test_mcp_tools.py
├── integration/
│   ├── test_import_export.py
│   └── test_authentication.py
└── unit/
    ├── test_models.py
    └── test_utils.py
```

**Structure Decision**: Option 1 (Single project) - MCP server as a standalone library with CLI interface

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - Research JIRA REST API v3 authentication patterns
   - Research MCP Python SDK best practices for tool definitions
   - Research JIRA rate limiting and error handling patterns
   - Research secure API key storage and management

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research JIRA REST API v3 authentication for MCP server integration"
     Task: "Research MCP Python SDK patterns for external API integrations"
     Task: "Research JIRA rate limiting and bulk operation optimization"
     Task: "Research secure credential management for MCP servers"
   For each technology choice:
     Task: "Find best practices for Python MCP servers with external APIs"
     Task: "Find error handling patterns for unreliable external services"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all technical decisions documented

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - JIRA Project: key, name, description, issue types
   - Work Item: key, summary, description, status, assignee, reporter
   - User: accountId, displayName, emailAddress, avatarUrls
   - Sprint: id, name, startDate, endDate, state
   - Comment: id, body, author, created, updated
   - Attachment: id, filename, content, mimeType, size

2. **Generate API contracts** from functional requirements:
   - Import project data: GET /rest/api/3/project/PGB
   - Export work items: POST /rest/api/3/issue/bulk
   - Search work items: GET /rest/api/3/search
   - Update work item: PUT /rest/api/3/issue/{issueIdOrKey}
   - Create work item: POST /rest/api/3/issue
   - Output OpenAPI schema to `/contracts/jira-api.yaml`

3. **Generate contract tests** from contracts:
   - test_import_project_contract.py - validates project import API
   - test_export_workitems_contract.py - validates bulk export API
   - test_search_contract.py - validates search API
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Import PGB project data scenario
   - Export modified work items scenario
   - Create new work item scenario
   - Real-time status query scenario

5. **Update agent file incrementally** (O(1) operation):
   - Run `/scripts/update-agent-context.sh copilot` for GitHub Copilot
   - Add JIRA MCP server context
   - Preserve existing PAWS360 context
   - Update recent changes

**Output**: data-model.md, /contracts/jira-api.yaml, failing contract tests, quickstart.md, .github/copilot-instructions.md updates

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (JIRA API contracts, data model, quickstart)
- Each JIRA API contract → contract test task [P]
- Each JIRA entity → model creation task [P] 
- Each MCP tool → tool implementation task
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Contract tests before implementation 
- Dependency order: Models → JIRA client → MCP tools → CLI
- Mark [P] for parallel execution (independent files)
- Sequential for integration tests

**Estimated Output**: 20-25 numbered, ordered tasks in tasks.md

**Task Categories**:
1. Contract Tests (5-7 tasks) - JIRA API validation
2. Data Models (4-5 tasks) - JIRA entity definitions  
3. JIRA Client (3-4 tasks) - API communication layer
4. MCP Tools (6-8 tasks) - Import/export/search operations
5. CLI Interface (2-3 tasks) - Command-line interface
6. Integration Tests (4-5 tasks) - End-to-end validation

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [x] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*