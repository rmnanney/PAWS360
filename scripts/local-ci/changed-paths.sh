#!/usr/bin/env bash
set -euo pipefail

# Returns list of changed paths between HEAD and origin/main (or default branch)
base=${1:-origin/main}
git fetch --no-tags --depth=1 origin ${base} >/dev/null 2>&1 || true
git diff --name-only --diff-filter=ACMRT "${base}"..HEAD || true
