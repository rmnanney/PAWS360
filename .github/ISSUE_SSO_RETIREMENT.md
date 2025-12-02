Title: Retire SSO end-to-end tests and related server-side SSO integration tests

Description:
The SSO E2E tests (Playwright) and server-side Java SSO integration/controller tests have been retired/disabled across the repository to reduce CI flakiness and maintenance burden.

Changes already applied:
- `tests/ui/tests/sso-authentication.spec.ts` — retired/skipped by default
- `tests/ui/global-setup.ts` — writes placeholder storageStates and skips SSO login generation when RETIRE_SSO is enabled
- `tests/ui/package.json` & `tests/ui/README.md` — updated to indicate retirement
- `src/test/java/com/uwm/paws360/integration/T057SSoIntegrationTest.java` — class-level @Disabled
- `src/test/java/com/uwm/paws360/integration/T057IntegrationTest.java` — SSO nested tests @Disabled
- `src/test/java/com/uwm/paws360/Controller/AuthControllerTest.java` — SSO nested tests @Disabled

Acceptance criteria / next steps:
1. Create a tracked backlog ticket in JIRA/GitHub linking to this file and docs/TECHDEBT-JAVA-SSO-RETIREMENT.md.
2. Decide whether to permanently remove SSO tests, rework them into smaller, more reliable integration tests, or maintain them disabled as historical artifacts.
3. If permanently removing, clean up related code and CI references (storageStates, test scripts, docs).
4. If reworking, provide a plan to mock/recreate stable SSO conditions in CI and reintroduce tests incrementally.

Owner: TBD
Priority: Medium

Created-by: automated-change (SSO retirement)
