# CI/CD Dashboard (monitoring/ci-cd-dashboard)

Purpose: Static site assets and pre-computed metrics (metrics.json) for the GitHub Pages dashboard. This README documents verification steps for GitHub Pages and how the hourly update workflow operates.

Verification checklist

1. Repository Settings → Pages: Branch = `gh-pages` or `main`/`docs` (confirm where site is published)
2. Confirm `monitoring/ci-cd-dashboard/data/metrics.json` is updated by `.github/workflows/update-dashboard.yml` on a schedule
3. Confirm the `index.html` at `monitoring/ci-cd-dashboard/index.html` loads without runtime errors

Notes

- The update workflow should use ETag/If-Modified-Since and paginate API responses efficiently.
- Keep fetches capped and backoff on rate limit responses (`Retry-After` header).
