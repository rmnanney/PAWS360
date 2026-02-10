# Tasks: JIRA MCP Server for PGB Project Management

**Input**: Design documents from `/specs/002-let-s-create/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/` or `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup
- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize Python 3.11+ project with MCP SDK dependencies
- [ ] T003 [P] Configure linting and formatting tools (black, flake8, mypy)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [ ] T004 [P] Contract test GET /rest/api/3/project/PGB in tests/contract/test_project_get.py
- [ ] T005 [P] Contract test POST /rest/api/3/issue/bulk in tests/contract/test_workitems_bulk_post.py
- [ ] T006 [P] Contract test GET /rest/api/3/search in tests/contract/test_search_get.py
- [ ] T007 [P] Contract test PUT /rest/api/3/issue/{issueIdOrKey} in tests/contract/test_workitem_put.py
- [ ] T008 [P] Contract test POST /rest/api/3/issue in tests/contract/test_workitem_post.py
- [ ] T009 [P] Contract test MCP tool definitions in tests/contract/test_mcp_tools.py
- [ ] T010 [P] Integration test PGB project import scenario in tests/integration/test_pgb_import.py
- [ ] T011 [P] Integration test work items export scenario in tests/integration/test_workitems_export.py
- [ ] T012 [P] Integration test new work item creation in tests/integration/test_workitem_create.py
- [ ] T013 [P] Integration test real-time status query in tests/integration/test_status_query.py

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T014 [P] JIRA Project model in src/jira_mcp_server/models.py
- [ ] T015 [P] Work Item model in src/jira_mcp_server/models.py
- [ ] T016 [P] User model in src/jira_mcp_server/models.py
- [ ] T017 [P] Sprint model in src/jira_mcp_server/models.py
- [ ] T018 [P] Comment model in src/jira_mcp_server/models.py
- [ ] T019 [P] Attachment model in src/jira_mcp_server/models.py
- [ ] T020 JIRA API client in src/jira_mcp_server/jira_client.py
- [ ] T021 Configuration management in src/jira_mcp_server/config.py
- [ ] T022 MCP server implementation in src/jira_mcp_server/server.py
- [ ] T023 Import project data MCP tool in src/jira_mcp_server/tools.py
- [ ] T024 Export work items MCP tool in src/jira_mcp_server/tools.py
- [ ] T025 Search work items MCP tool in src/jira_mcp_server/tools.py
- [ ] T026 Update work item MCP tool in src/jira_mcp_server/tools.py
- [ ] T027 Create work item MCP tool in src/jira_mcp_server/tools.py
- [ ] T028 CLI entry point in src/cli/__main__.py
- [ ] T029 Utility functions in src/lib/utils.py

## Phase 3.4: Integration
- [ ] T030 Connect JIRA client to MCP server
- [ ] T031 Authentication middleware for API key handling
- [ ] T032 Request/response logging
- [ ] T033 Rate limiting and error handling
- [ ] T034 Secure credential management

## Phase 3.5: Polish
- [ ] T035 [P] Unit tests for models in tests/unit/test_models.py
- [ ] T036 [P] Unit tests for utilities in tests/unit/test_utils.py
- [ ] T037 Performance tests (<500ms individual, <2s bulk)
- [ ] T038 [P] Update docs/api.md
- [ ] T039 Remove code duplication
- [ ] T040 Run quickstart.md validation scenarios
- [ ] T041 Package and distribution setup

## Dependencies
- Tests (T004-T013) before implementation (T014-T029)
- T014-T019 blocks T020 (models before client)
- T020 blocks T023-T027 (client before tools)
- T022 blocks T030 (server before integration)
- Implementation before polish (T035-T041)

## Parallel Example
```
# Launch T004-T009 together:
Task: "Contract test GET /rest/api/3/project/PGB in tests/contract/test_project_get.py"
Task: "Contract test POST /rest/api/3/issue/bulk in tests/contract/test_workitems_bulk_post.py"
Task: "Contract test GET /rest/api/3/search in tests/contract/test_search_get.py"
Task: "Contract test PUT /rest/api/3/issue/{issueIdOrKey} in tests/contract/test_workitem_put.py"
Task: "Contract test POST /rest/api/3/issue in tests/contract/test_workitem_post.py"
Task: "Contract test MCP tool definitions in tests/contract/test_mcp_tools.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task

2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks

3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding tests
- [x] All entities have model tasks
- [x] All tests come before implementation
- [x] Parallel tasks truly independent
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/specs/002-let-s-create/tasks.md