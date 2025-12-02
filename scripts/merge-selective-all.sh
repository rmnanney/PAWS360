#!/usr/bin/env bash
# Helper for reproducing the multi-branch merge decisions in the repo (committed to merge branch)
set -euo pipefail
BRANCH_AUTHOR="Ryan"

git merge --no-edit origin/SCRUM-59-Personal-Info-Module || true
./scripts/resolve_merge_selective.sh || true

git merge --no-edit origin/SCRUM-60-Resources-Module || true
./scripts/resolve_merge_selective.sh || true

git merge --no-edit origin/SCRUM-79-AdminLTE-Dashboard || true
./scripts/resolve_merge_selective.sh || true

git merge --no-edit origin/SCRUM-54-CI-CD-Pipeline-Setup || true
./scripts/resolve_merge_selective.sh || true

echo "Merge done"
