#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run GitHub Super-Linter on self-hosted runner with configurable environment
# Usage: ENVIRONMENT=runner ./ci/superlinter-run.sh

IMAGE=${SUPERLINTER_IMAGE:-ghcr.io/github/super-linter:v4.10.0}
ENVIRONMENT=${ENVIRONMENT:-runner}

echo "[superlinter] Environment: ${ENVIRONMENT}"

echo "[superlinter] Pulling image ${IMAGE}..."
docker pull "${IMAGE}" || true

DOCKER_RUN_FLAGS=(
  --rm
  -v "/var/run/docker.sock:/var/run/docker.sock"
  -v "${PWD}:/github/workspace"
  -e "GITHUB_WORKSPACE=/github/workspace"
  -e "RUN_LOCAL=true"
  -e "VALIDATE_YAML=true"
  -e "VALIDATE_WORKFLOWS_ONLY=false"
  -e "DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}"
)

echo "[superlinter] Running container..."
set +e
docker run "${DOCKER_RUN_FLAGS[@]}" "${IMAGE}" || LRCODE=$?
RC=$?
set -e

if [ ${RC:-0} -ne 0 ]; then
  echo "[superlinter] docker run failed with exit ${RC}."
  if [ -n "${LRCODE:-}" ]; then
    echo "[superlinter] last run code: ${LRCODE}"
  fi
  # If container couldn't start (runc error), try pulling and retry once
  echo "[superlinter] Retrying: pulling latest and retrying..."
  docker pull "${IMAGE}" || true
  docker run "${DOCKER_RUN_FLAGS[@]}" "${IMAGE}"
fi

echo "[superlinter] Completed"
