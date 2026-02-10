#!/usr/bin/env bash
# Resolve merge conflicts between master and SCRUM-54 using blame-based precedence.
# Usage (from /tmp/paws-merge): git merge origin/SCRUM-54-CI-CD-Pipeline-Setup && ./scripts/resolve_merge_selective.sh

set -euo pipefail

# Default: prefer master for most files (ours)
# If a file is authored primarily by a different person than the branch owner (Ryan), prefer that side.
BRANCH_AUTHOR="Ryan"

conflict_files=$(git status --porcelain | awk '{print $2}')
for f in $conflict_files; do
  if [ -z "$f" ]; then
    continue
  fi
  m_author=$(git blame --line-porcelain origin/master -- "$f" 2>/dev/null | sed -n 's/^author //p' | sort | uniq -c | sort -rn | head -n1 | awk '{print $2}') || m_author=""
  b_author=$(git blame --line-porcelain origin/SCRUM-54-CI-CD-Pipeline-Setup -- "$f" 2>/dev/null | sed -n 's/^author //p' | sort | uniq -c | sort -rn | head -n1 | awk '{print $2}') || b_author=""

  printf "Resolving %s (master: '%s', branch: '%s')\n" "$f" "$m_author" "$b_author"
  if [ "$m_author" != "$BRANCH_AUTHOR" ] && [ "$b_author" = "$BRANCH_AUTHOR" ]; then
    git checkout --ours -- "$f"  # keep master
  elif [ "$m_author" = "$BRANCH_AUTHOR" ] && [ "$b_author" != "$BRANCH_AUTHOR" ]; then
    git checkout --theirs -- "$f"  # keep branch
  else
    git checkout --ours -- "$f"  # default to master
  fi
  git add "$f"
done

echo "All conflicts resolved according to selective precedence."

