# Local CI (scripts/local-ci)

Purpose: provide reproducible local CI entry points for developers to validate code before pushing and to run full CI pipelines locally.

Available stubs (to be implemented in Phase 2/3):

- `pre-push-checks.sh`  — Fast checks (compile, unit, lint). Runs on pre-push hook and in wrapper.
- `test-all.sh`         — Full test suite locally (unit + integration + quick security checks).
- `build-images.sh`     — Build any local Docker images used by tests.
- `changed-paths.sh`    — Helper to compute which components were changed (used by local & CI flows).
- `verify-parity.sh`    — Compare local run results vs latest cloud run (parity verification)

How to use

1. Install hooks (`make setup-hooks`)
2. Run quick checks:

```bash
DEBUG=1 ./scripts/local-ci/pre-push-checks.sh
```

3. Run full local CI (placeholder):

```bash
make ci-local
```

Notes

- Stubs intentionally small so they can be implemented and validated iteratively in subsequent phases.
