# Post-deployment verification playbook

This playbook contains a set of concise, repeatable checks to run immediately after a deploy to staging or production. The goal is to provide fast, objective verification that the deployment completed successfully and that critical user journeys are functional.

## Quick checklist (run within first 5 minutes)
- Confirm the deployment pipeline completed without errors in GitHub Actions.
- Check the deployment job artifacts and release notes for expected changes (new artifact IDs, image tags).
- Confirm health endpoints report OK:
  - Admin/UI: https://<host>/actuator/health
  - Frontend: https://<host>/health or check static assets
- Verify service instances are running and scaled as expected (k8s pods / container instances / App Service status).

## Smoke tests (5–10 minutes)
- Run the smoke test suite (fast tests covering critical flows):
  - Login / authentication
  - Core API health (GET /api/status, GET /api/students/1)
  - Sample end-to-end flow (create, read, update, delete minimal sample)

## Artifact verification
- Confirm artifacts were published where expected (container registry, artifacts storage).
- Validate that digest/tag of deployed image matches pipeline output (avoid image drift).

## Observability & Logging
- Confirm metrics ingestion is functioning and dashboards show incoming metrics for the new deploy.
- Check recent errors in logs and APM (Sentry, NewRelic, Grafana). Ensure no new high-severity spikes.

## Post-checks and Rollback
- If critical tests fail, follow rollback procedures in `Makefile` or deployment runbook (see `rollback-staging` / `rollback-prod` targets).
- Open a post-deploy incident if external systems are impacted.

## Automation & CI Integration
- Add a workflow `post-deploy-checks.yml` with a `workflow_run` trigger to automatically execute smoke tests after deploy jobs finish.
- Configure runbooks to update the incident channel (Slack) and tag on-call engineers automatically when failures are detected.

## On-call & Ownership
- Assign the deployment owner to observe the deployment for the next 30 minutes.
- Record a short note in the deployment ticket with time-to-ready and any anomalies.

## Troubleshooting tips
- Check service level agreements and retry policies for dependent services.
- If transient errors appear, collect logs, dump thread stacks if applicable, and escalate to a subject matter expert.
