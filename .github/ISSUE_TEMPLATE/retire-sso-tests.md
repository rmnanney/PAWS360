name: Retire SSO tests
about: Track the retirement and follow-up cleanup or rework of SSO end-to-end and server-side tests
labels: 'tech-debt'
assignees: ''

---

## Summary
We retired SSO end-to-end tests (Playwright) and disabled server-side Java SSO tests to reduce CI flakiness. This issue tracks creating a plan and performing follow-up cleanup or a robust rework.

## Files impacted
- tests/ui/tests/sso-authentication.spec.ts (retired/skipped)
- tests/ui/global-setup.ts (placeholder storageState files when RETIRE_SSO != 'false')
- src/test/java/com/uwm/paws360/integration/T057SSoIntegrationTest.java (disabled)
- src/test/java/com/uwm/paws360/integration/T057IntegrationTest.java (SSO nested tests disabled)
- src/test/java/com/uwm/paws360/Controller/AuthControllerTest.java (SSO nested tests disabled)

## Acceptance criteria
- [ ] Create a formal backlog ticket in GitHub/JIRA referencing this issue and docs/SSO-RETIREMENT.md and docs/TECHDEBT-JAVA-SSO-RETIREMENT.md
- [ ] Decide on an approach: permanently remove tests OR rework them into smaller, deterministic tests
- [ ] If removal selected: delete retired test files and remove SSO-specific artifacts (storageStates, README references)
- [ ] If rework selected: propose an architecture for reliable SSO test coverage (e.g., stable mock SSO server, dedicated integration environment, or contract/unit tests)

## Notes
Temporary re-enable via environment variable: RETIRE_SSO=false (not recommended for CI)
