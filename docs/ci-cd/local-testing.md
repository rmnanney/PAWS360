# Local Testing & Debugging

Quick guide for running local validation flows and debug workflows.

Steps

1. Install hooks: `make setup-hooks` or follow `.github/hooks/README.md`
2. Run quick checks before push:

```bash
./scripts/local-ci/pre-push-checks.sh
```

3. Run full local CI

```bash
make ci-local
```

4. Run debug workflow via Actions (debug.yml) using `workflow_dispatch` if needed

Notes

- For interactive bypass use `bash .github/hooks/git-push-wrapper --bypass origin main` and provide a justification.
- Use `scripts/local-ci/changed-paths.sh` to scope work when running local tests.

Component filters and timing

```bash
# Run backend only
./scripts/local-ci/test-all.sh backend

# Run frontend only
./scripts/local-ci/test-all.sh frontend

# Run all (default)
./scripts/local-ci/test-all.sh all
```

Expected runtime: full local CI should complete in under 5 minutes on reference hardware (8-core CPU, 16GB RAM) when cached.
