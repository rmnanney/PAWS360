FROM openjdk:21-jdk-slim

# Install curl for container healthchecks and diagnostics
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Default working directory
WORKDIR /app
