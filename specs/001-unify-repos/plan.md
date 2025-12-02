# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Unify student portal, admin view, and backend services for a seamless demo. SSO, automation idempotency, and demo data reuse are required. No code changes unless strictly necessary; configuration and orchestration preferred.

## Technical Context

**Language/Version**: Spring Boot 3.5.x (Java 21), Next.js (TypeScript), PostgreSQL  
**Primary Dependencies**: Spring Boot, JPA, BCrypt, Next.js, React, Tailwind, Ansible, Docker Compose  
**Storage**: PostgreSQL  
**Testing**: JUnit (backend), Jest (frontend), Ansible idempotency checks  
**Target Platform**: Linux server (localhost for demo)  
**Project Type**: Web application (frontend + backend)  
**Performance Goals**: Demo flows complete in <30 min, page loads <2s  
**Constraints**: No code changes during demo, config-only adjustments, SSO, idempotent automation  
**Scale/Scope**: 2-3 demo accounts, single host, repeatable demo runs

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Initial Check (Pre-Phase 0)**: ✅ PASSED
- Library-First: Each module should remain independently testable; no deep coupling introduced for demo.
- CLI Interface: Automation scripts must support CLI invocation and human-readable output.
- Test-First: Demo flows must be covered by independent tests (JUnit/Jest/Ansible checks).
- Integration Testing: SSO and data consistency must be validated across modules.
- Observability: Health checks and error reporting must be surfaced in logs/terminal.
- Simplicity: No unnecessary complexity; config/orchestration preferred over code changes.

**Post-Phase 1 Re-check**: ✅ PASSED
- Library-First: ✅ Data model maintains entity separation; API contracts enable independent testing
- CLI Interface: ✅ Quickstart provides CLI commands; Ansible automation supports human-readable output
- Test-First: ✅ API contracts define testable endpoints; integration scenarios documented
- Integration Testing: ✅ SSO and data consistency validation points identified in contracts
- Observability: ✅ Health check endpoints defined; error response schemas specified
- Simplicity: ✅ Configuration-based approach; existing patterns preserved; minimal new complexity

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Backend (Spring Boot)
src/main/java/com/uwm/paws360/
├── auth/                     # SSO authentication controllers
├── Service/                  # Business logic services
├── models/                   # JPA entities
└── config/                   # Configuration classes

src/test/java/com/uwm/paws360/
├── integration/              # Cross-module integration tests
└── unit/                     # Unit tests

# Frontend (Next.js)
app/
├── components/               # Shared UI components
├── login/                    # Authentication pages
├── homepage/                 # Student portal pages
├── admin/                    # Admin view pages (if applicable)
└── hooks/                    # React hooks

# Infrastructure
infrastructure/docker/        # Docker Compose configuration
db/                          # Database schema and seed scripts
.ansible/                    # Ansible automation scripts
```

**Structure Decision**: Web application with separate frontend/backend. Existing directories preserved. Demo orchestration via Docker Compose and Ansible automation.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
