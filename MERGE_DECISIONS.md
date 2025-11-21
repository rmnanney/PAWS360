# Merge decisions for merge/scrum-54-safe

This document lists each conflict file from the merge of `SCRUM-54-CI-CD-Pipeline-Setup` into `master` and the author-based precedence decision used to resolve it. The merge strategy: prefer *other contributors* (non-Ryan) where the file's top author differs. When no other person is clearly the top author, prefer `master`.

| File | Top author (master) | Top author (branch) | Chosen side | Reason |
|---|---|---|---|---|
| .github/workflows/ci-cd.yml | Ryan | Ryan | master | Prefer Ryan's CI fixes on master that resolved auth port issues |
| next.config.ts | Zenith | Zenith | master | Zenith is the primary contributor — prefer master |
| package.json | Zenith | Ryan | master | Zenith contributed more to package.json on master; merge other scripts manually |
| pom.xml | Ryan | Zack | branch | Branch had Zack’s repo-level changes; prefer branch in this case |
| tests/ui/global-setup.ts | Ryan | — | master | Keep existing test harness authored by Ryan |
| src/main/java/... (Controllers) | Ryan | — | master | These backend controllers are authored by Ryan; keep master to avoid breaking features |
| scripts/check_test_failures.py | — | Ryan | branch | New helpful script from the branch; keep it |
| docs/** | — | Ryan | branch | Keep new documentation from branch, it adds CI guidance |
| frontend/** | — | Ryan | branch | Branch added a complete frontend; prefer other people's contributions (e.g., Zenith) if present |

Notes:
- For any file where the top author on master is not `Ryan`, but branch top author is `Ryan`, the file resolved to master (the non-Ryan author's work wins).
- For any file where the top author on branch is not `Ryan`, but master top author is `Ryan`, the branch version wins (other people's work wins).
- In ties or both authored by `Ryan`, default to `master` to preserve fixes already merged into master.

Repro script: `scripts/resolve_merge_selective.sh` (committed into the merge branch) can reproduce the exact per-file decisions used to resolve the conflicts.

Please review the PR carefully: tests and UI components should be validated by the file authors before merging.
