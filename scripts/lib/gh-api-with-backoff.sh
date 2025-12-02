#!/usr/bin/env bash
set -euo pipefail

# Usage: gh-api-with-backoff.sh <api_path> [max_retries]
# Example: gh-api-with-backoff.sh /repos/owner/repo

API_PATH="$1"
MAX_RETRIES="${2:-5}"
TOKEN="${GITHUB_TOKEN:-}"

if [ -z "$API_PATH" ]; then
  echo "Usage: $0 <api_path> [max_retries]" >&2
  exit 2
fi

BASE_URL="https://api.github.com"
retry=0
sleep_time=1
while [ "$retry" -lt "$MAX_RETRIES" ]; do
  headers_file=$(mktemp)
  body_file=$(mktemp)
  http_status=$(curl -s -D "$headers_file" -o "$body_file" -w '%{http_code}' -H "Accept: application/vnd.github+json" -H "Authorization: token $TOKEN" "$BASE_URL$API_PATH" || true)

  # Read Retry-After header if present
  retry_after=$(awk 'BEGIN{IGNORECASE=1} /^Retry-After:/ {print $2}' "$headers_file" | tr -d '\r') || true

  if [ "$http_status" -ge 200 ] && [ "$http_status" -lt 300 ]; then
    cat "$body_file"
    rm -f "$headers_file" "$body_file"
    exit 0
  fi

  if [ -n "$retry_after" ]; then
    echo "Rate limited - Retry-After header present: $retry_after" >&2
    sleep_seconds=$retry_after
  else
    # exponential backoff
    sleep_seconds=$sleep_time
    sleep_time=$((sleep_time * 2))
  fi

  echo "Request returned HTTP $http_status. Retrying in ${sleep_seconds}s... (attempt $((retry+1))/$MAX_RETRIES)" >&2
  sleep "$sleep_seconds"
  retry=$((retry+1))
done

echo "Failed to fetch $API_PATH after $MAX_RETRIES attempts" >&2
cat "$body_file" >&2 || true
rm -f "$headers_file" "$body_file"
exit 1
