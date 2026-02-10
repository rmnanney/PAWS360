#!/bin/bash
set -e

echo "🧪 Testing CI pipeline locally..."

# Clean up any existing containers
echo "🧹 Cleaning up existing test containers..."
cd infrastructure/docker
docker compose -f docker-compose.test.yml down 2>/dev/null || true

# Start the test stack
echo "🚀 Starting test environment..."
docker compose -f docker-compose.test.yml up -d

# Wait for backend health check (exactly like CI)
echo "⏳ Waiting for backend (port 8091)..."
timeout 300 bash -c \
  'until curl -f http://localhost:8091/actuator/health; do sleep 5; done'

# Wait for frontend readiness path (match CI's /healthz)
echo "⏳ Waiting for frontend (port 8095) readiness (/healthz)..."
timeout 300 bash -c \
  'until curl -f http://localhost:8095/healthz; do sleep 5; done'

echo "✅ Both services are responding!"
echo "🔍 Backend: http://localhost:8091/actuator/health"
echo "🔍 Frontend: http://localhost:8095"

# Cleanup
echo "🧹 Cleaning up..."
docker compose -f docker-compose.test.yml down

echo "✅ Local CI simulation completed successfully!"