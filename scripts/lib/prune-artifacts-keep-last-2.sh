#!/usr/bin/env bash
set -euo pipefail

# Prune GitHub Actions artifacts, keeping only artifacts created for the N most recent workflow runs
# By default this keeps the last 5 runs; you can override via KEEP_LAST env var (e.g. KEEP_LAST=3)
# Usage: runs in a repository that has `gh` installed and GITHUB_REPOSITORY/GITHUB_TOKEN available

REPO=${GITHUB_REPOSITORY:-}
if [ -z "$REPO" ]; then
  echo "GITHUB_REPOSITORY not set. Please run inside a GitHub Actions job or pass REPO as env."
  exit 0
fi

echo "Prune artifacts for repo: $REPO — keeping current and the previous workflow run"

KEEP_LAST=${KEEP_LAST:-5}
if ! [[ "$KEEP_LAST" =~ ^[0-9]+$ ]] || [ "$KEEP_LAST" -lt 1 ]; then
  echo "KEEP_LAST must be a positive integer (received: '$KEEP_LAST')" >&2
  exit 1
fi

# Fetch the most recent workflow runs and pick the KEEP_LAST-th most recent run's created_at as cutoff
# We fetch up to KEEP_LAST+2 runs to be safe, but at least KEEP_LAST
per_page=$(( KEEP_LAST + 2 ))
runs_json=$(gh api -H "Accept: application/vnd.github+json" "/repos/$REPO/actions/runs?per_page=$per_page") || true
index=$(( KEEP_LAST - 1 ))
prev_created=$(echo "$runs_json" | jq -r --argjson idx "$index" '.workflow_runs | sort_by(.created_at) | reverse | .[$idx].created_at // empty') || true

if [ -z "$prev_created" ]; then
  echo "Not enough workflow runs to compute a cutoff for KEEP_LAST=$KEEP_LAST; nothing to prune."
  exit 0
fi

cutoff="$prev_created"
echo "Artifacts created before $cutoff will be deleted (keeps current + previous run)"

page=1
while :; do
  resp=$(gh api -H "Accept: application/vnd.github+json" "/repos/$REPO/actions/artifacts?per_page=100&page=$page") || true
  artifacts_count=$(echo "$resp" | jq '.artifacts | length')
  if [ "$artifacts_count" -eq 0 ]; then
    echo "No more artifacts on page $page; done."
    break
  fi

  echo "Processing $artifacts_count artifacts on page $page"

  echo "$resp" | jq -c '.artifacts[]' | while read -r art; do
    art_id=$(echo "$art" | jq -r '.id')
    art_name=$(echo "$art" | jq -r '.name')
    art_created=$(echo "$art" | jq -r '.created_at')

    # if artifact created earlier than cutoff, delete it
    if [[ "$art_created" < "$cutoff" ]]; then
      echo "Deleting artifact id=$art_id name=\"$art_name\" created=$art_created"
      gh api -X DELETE "/repos/$REPO/actions/artifacts/$art_id" || true
    else
      echo "Keeping artifact id=$art_id name=\"$art_name\" created=$art_created"
    fi
  done

  page=$((page+1))
done

echo "Prune run complete."
