#!/usr/bin/env bash
set -euo pipefail

# Populate a Docker volume with Maven dependencies so Docker builds can use it
# Usage: ./ci/populate-m2.sh [volume-name]

VOLUME_NAME=${1:-paws360-m2-cache}
IMAGE=${MAVEN_IMAGE:-maven:3.9-eclipse-temurin-21-alpine}

echo "[populate-m2] Using volume: ${VOLUME_NAME}"
docker volume create "${VOLUME_NAME}" >/dev/null || true

echo "[populate-m2] Populating volume with mvn dependency:go-offline"
docker run --rm -v "${VOLUME_NAME}:/root/.m2" -v "${PWD}:/workspace" -w /workspace "${IMAGE}" \
  mvn -B -DskipTests dependency:go-offline || {
    echo "[populate-m2] mvn failed - exiting" >&2
    exit 1
  }

echo "[populate-m2] Completed"
