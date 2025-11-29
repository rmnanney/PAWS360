# Local Testing & Debugging

Quick guide for running local validation flows and debug workflows.

Steps

1. Install hooks: `make setup-hooks` or follow `.github/hooks/README.md`
2. Run quick checks before push:

```bash
./scripts/local-ci/pre-push-checks.sh
```

3. Run full local CI (placeholder):

```bash
make ci-local
```

4. Run debug workflow via Actions (debug.yml) using `workflow_dispatch` if needed

Notes

- For interactive bypass use `bash .github/hooks/git-push-wrapper --bypass origin main` and provide a justification.
- Use `scripts/local-ci/changed-paths.sh` to scope work when running local tests.
