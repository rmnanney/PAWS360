# Workflow Audit — .github/workflows

Summary: Quick inventory of existing workflows and recommended owners/permissions review (T005).

Workflows found (2025-11-28):
- artifact-cleanup.yml
- artifact-report-schedule.yml
- bootstrap-staging.yml
- ci-cd.yml
- ci.yml
- deploy-prod-check.yml
- deploy-stage-check.yml
- local-dev-ci.yml
- provision-staging.yml
- workflow-lint.yml

Findings
- Many workflows exist; recommend setting `permissions:` minimally and ensuring CODEOWNERS review on workflow changes.
- `ci-cd.yml` is present and should be updated in later phases with path filters and concurrency groups.

Action items:
- Assign CODEOWNERS to `.github/workflows/` (T010).
- Add `permissions:` where appropriate (T042/T069).
