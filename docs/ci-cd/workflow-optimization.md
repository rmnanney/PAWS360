# Workflow Optimization (overview)

This file captures the baseline strategies for path filters, concurrency groups, caching, and run minimization.

Key points

- Use `paths` / `paths-ignore` triggers to skip non-impactful changes
- Use `concurrency` groups with `cancel-in-progress: true` for build/test runs
- Split cache keys per ecosystem (maven/npm) with hash-based keys and restore-keys fallback
- Detect draft PRs and run a reduced validation set
- Use `changed-paths` helpers to run minimal tests where possible

Implementation notes and examples are provided inside `specs/001-ci-cd-optimization/research.md` and `specs/001-ci-cd-optimization/plan.md`.
