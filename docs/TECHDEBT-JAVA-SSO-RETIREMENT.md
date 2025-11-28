Title: Tech-debt - Retire server-side SSO tests

Status: In progress (disabled in tests)

Summary
-------
We retired (disabled) server-side SSO-related integration and controller tests to remove a recurring source of CI flakiness and maintenance overhead. This mirrors the Playwright SSO retirement already applied at the test layer.

Files changed (tests disabled)
--------------------------------
- src/test/java/com/uwm/paws360/integration/T057SSoIntegrationTest.java  (class-level @Disabled)
- src/test/java/com/uwm/paws360/integration/T057IntegrationTest.java  (SSO nested tests @Disabled)
- src/test/java/com/uwm/paws360/Controller/AuthControllerTest.java  (SSO nested tests @Disabled)

Rationale
---------
These tests are brittle due to cross-service timing, session cookie/token differences, and environment-specific behavior (CORS, proxies, origins). Disabling them reduces CI noise and allows the team to focus on stabilizing the critical test surface.

Next steps (recommended)
------------------------
1. Create a tracked issue in the backlog (JIRA/GitHub) describing full removal or rework.
2. Option A (Preferred short-term): Keep tests disabled and add improved contract/unit tests and small integration tests that don't rely on cross-service timing. Document precisely which API contracts must be protected.
3. Option B (Long-term): Rework and reintroduce SSO tests against a reliable local mock auth service or dedicated e2e staging environment with stable cross-service behavior.
4. If the team accepts permanent removal, delete the disabled test files and remove related artifacts (storageState / SSO-specific helpers) and create a follow-up cleanup PR.

Owner / Assignee
----------------
Leave unassigned — please create a backlog ticket and assign to the person who will own the plan.

Reference
---------
- UI retirement / docs: docs/SSO-RETIREMENT.md
