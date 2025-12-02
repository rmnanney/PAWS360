# CI/CD Infrastructure Impact Analysis

This document summarizes the impact, risks, and mitigations for the CI/CD pipeline optimizations introduced in `001-ci-cd-optimization`.

## Key areas impacted

- GitHub Actions minutes and storage
- GitHub Pages (static hosting for dashboard)
- Repository automation (hooks, commit templates)
- GitHub Tokens and permissions scope
- Scheduled workflows and quota impact
- Self-hosted runner considerations

## GitHub Pages (CI/CD Dashboard)

- Hosting: GitHub Pages (static site) — zero hosting cost for public pages; private repo pages require additional configuration (org settings).
- Security: Pages are static and public by default — do not expose secrets or sensitive artifacts. Only non-sensitive aggregated metrics should be published.
- Branch / path: Either publish from a dedicated branch (gh-pages) or the `monitoring/ci-cd-dashboard` directory on the default branch. Documented in `monitoring/ci-cd-dashboard/README.md`.

## GITHUB_TOKEN & Permissions

- Principle: least-privilege. Set `permissions:` per-workflow to only the rights required (read-only for `actions`, `contents: write` only where committing/pushing required, `issues: write` only where creating issues).
- Risk: using a broad scoped PAT is strongly discouraged. Prefer `GITHUB_TOKEN` and minimal `permissions:`.

## Branch Protection & Hooks

- Hooks are developer-side guardrails; they do not bypass branch protection.
- Branch protection rules (e.g., require status checks, require PR reviews) remain the primary enforcement mechanism for gating changes.
- Repository-side audit job still required to detect bypasses (`git push --no-verify`) and create audit issues.

## Self-hosted runners

- Running CI on self-hosted runners transfers execution load off GitHub but introduces new security & maintenance responsibilities.
- Must ensure runners are isolated, updated, and authenticated. Don't use self-hosted runners for untrusted PRs.

## Tokens & Secrets

- Document required secrets in `docs/secrets.md` and ensure minimal access.
- For workflows which commit or create issues, `permissions:` must be set and documented.

## Operational Recommendations

- Add monitoring & alerts for: high scheduled consumption, API rate-limit errors, workflow failure rate spikes
- Run periodic review (monthly) of workflow permissions and token usage
- Use least-privilege PATs for long-running maintenance tasks; prefer GitHub Apps where possible
