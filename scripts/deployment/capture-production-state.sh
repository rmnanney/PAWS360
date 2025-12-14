#!/usr/bin/env bash
# Pre-Deployment State Capture Script
# JIRA: INFRA-472, INFRA-475 (US3-T069)
#
# Captures current production state before deployment for rollback reference.
# Outputs JSON to stdout for consumption by deployment automation.
#
# Usage:
#   ./capture-production-state.sh --host prod.example.com --output /tmp/state.json
#
# Environment variables:
#   PRODUCTION_HOST: Target production host (required if --host not provided)
#   OUTPUT_FILE: Optional file to write state (default: stdout)

set -euo pipefail

# Configuration
PRODUCTION_HOST="${PRODUCTION_HOST:-}"
OUTPUT_FILE="${OUTPUT_FILE:-}"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --host)
      PRODUCTION_HOST="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --host HOST        Production host (required if PRODUCTION_HOST not set)"
      echo "  --output FILE      Output file (default: stdout)"
      echo "  --help             Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${PRODUCTION_HOST}" ]]; then
  echo "ERROR: PRODUCTION_HOST is required (set env or pass --host)" >&2
  exit 1
fi

# Logging function (to stderr to not interfere with JSON output)
log() {
  echo -e "$1" >&2
}

log "${GREEN}Capturing production state from: $PRODUCTION_HOST${NC}"

# ============================================================================
# Capture backend version
# ============================================================================
log "Capturing backend version..."
if BACKEND_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/backend/version.txt 2>/dev/null'); then
  log "  ✓ Backend version: $BACKEND_VERSION"
else
  log "${YELLOW}  ⚠ Backend version unavailable (file not found)${NC}"
  BACKEND_VERSION="unknown"
fi

# ============================================================================
# Capture frontend version
# ============================================================================
log "Capturing frontend version..."
if FRONTEND_VERSION=$(ssh "$PRODUCTION_HOST" 'cat /opt/paws360/frontend/version.txt 2>/dev/null'); then
  log "  ✓ Frontend version: $FRONTEND_VERSION"
else
  log "${YELLOW}  ⚠ Frontend version unavailable (file not found)${NC}"
  FRONTEND_VERSION="unknown"
fi

# ============================================================================
# Capture database schema version
# ============================================================================
log "Capturing database schema version..."
if DATABASE_VERSION=$(ssh "$PRODUCTION_HOST" 'psql -U paws360 -d paws360 -t -c "SELECT version FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 1;" 2>/dev/null' | tr -d ' '); then
  if [ -n "$DATABASE_VERSION" ]; then
    log "  ✓ Database version: $DATABASE_VERSION"
  else
    log "${YELLOW}  ⚠ Database version empty${NC}"
    DATABASE_VERSION="unknown"
  fi
else
  log "${YELLOW}  ⚠ Database version unavailable${NC}"
  DATABASE_VERSION="unknown"
fi

# ============================================================================
# Capture service status
# ============================================================================
log "Capturing service status..."

if BACKEND_STATUS=$(ssh "$PRODUCTION_HOST" 'systemctl is-active paws360-backend 2>/dev/null'); then
  log "  ✓ Backend service: $BACKEND_STATUS"
else
  log "${YELLOW}  ⚠ Backend service status unavailable${NC}"
  BACKEND_STATUS="unknown"
fi

if FRONTEND_STATUS=$(ssh "$PRODUCTION_HOST" 'systemctl is-active paws360-frontend 2>/dev/null'); then
  log "  ✓ Frontend service: $FRONTEND_STATUS"
else
  log "${YELLOW}  ⚠ Frontend service status unavailable${NC}"
  FRONTEND_STATUS="unknown"
fi

if DATABASE_STATUS=$(ssh "$PRODUCTION_HOST" 'systemctl is-active postgresql 2>/dev/null'); then
  log "  ✓ Database service: $DATABASE_STATUS"
else
  log "${YELLOW}  ⚠ Database service status unavailable${NC}"
  DATABASE_STATUS="unknown"
fi

# ============================================================================
# Capture system metrics
# ============================================================================
log "Capturing system metrics..."

if UPTIME=$(ssh "$PRODUCTION_HOST" 'uptime -s 2>/dev/null'); then
  log "  ✓ System uptime since: $UPTIME"
else
  log "${YELLOW}  ⚠ Uptime unavailable${NC}"
  UPTIME="unknown"
fi

if LOAD_AVG=$(ssh "$PRODUCTION_HOST" 'cat /proc/loadavg 2>/dev/null' | awk '{print $1,$2,$3}'); then
  log "  ✓ Load average: $LOAD_AVG"
else
  log "${YELLOW}  ⚠ Load average unavailable${NC}"
  LOAD_AVG="unknown unknown unknown"
fi

if DISK_USAGE=$(ssh "$PRODUCTION_HOST" 'df -h /opt/paws360 2>/dev/null' | awk 'NR==2 {print $5}'); then
  log "  ✓ Disk usage: $DISK_USAGE"
else
  log "${YELLOW}  ⚠ Disk usage unavailable${NC}"
  DISK_USAGE="unknown"
fi

# ============================================================================
# Capture deployment history (last 3 deployments)
# ============================================================================
log "Capturing deployment history..."

if DEPLOY_HISTORY=$(ssh "$PRODUCTION_HOST" 'ls -t /var/backups/paws360-deploy-states/state-*.json 2>/dev/null | head -3'); then
  DEPLOY_COUNT=$(echo "$DEPLOY_HISTORY" | wc -l)
  log "  ✓ Found $DEPLOY_COUNT recent deployment(s)"
else
  log "${YELLOW}  ⚠ Deployment history unavailable${NC}"
  DEPLOY_HISTORY=""
fi

# ============================================================================
# Build JSON state document
# ============================================================================
log ""
log "${GREEN}Building state document...${NC}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CAPTURE_HOST=$(hostname)

# Parse load average components
LOAD_1MIN=$(echo "$LOAD_AVG" | awk '{print $1}')
LOAD_5MIN=$(echo "$LOAD_AVG" | awk '{print $2}')
LOAD_15MIN=$(echo "$LOAD_AVG" | awk '{print $3}')

# Build JSON (using jq if available, otherwise manual construction)
if command -v jq &> /dev/null; then
  STATE_JSON=$(jq -n \
    --arg timestamp "$TIMESTAMP" \
    --arg host "$PRODUCTION_HOST" \
    --arg captured_by "$CAPTURE_HOST" \
    --arg backend_version "$BACKEND_VERSION" \
    --arg frontend_version "$FRONTEND_VERSION" \
    --arg database_version "$DATABASE_VERSION" \
    --arg backend_status "$BACKEND_STATUS" \
    --arg frontend_status "$FRONTEND_STATUS" \
    --arg database_status "$DATABASE_STATUS" \
    --arg uptime "$UPTIME" \
    --arg load_1min "$LOAD_1MIN" \
    --arg load_5min "$LOAD_5MIN" \
    --arg load_15min "$LOAD_15MIN" \
    --arg disk_usage "$DISK_USAGE" \
    '{
      "timestamp": $timestamp,
      "host": $host,
      "captured_by": $captured_by,
      "versions": {
        "backend": $backend_version,
        "frontend": $frontend_version,
        "database": $database_version
      },
      "services": {
        "backend": $backend_status,
        "frontend": $frontend_status,
        "database": $database_status
      },
      "system": {
        "uptime_since": $uptime,
        "load_average": {
          "1min": $load_1min,
          "5min": $load_5min,
          "15min": $load_15min
        },
        "disk_usage": $disk_usage
      },
      "metadata": {
        "capture_method": "ssh-remote",
        "schema_version": "1.0"
      }
    }')
else
  # Manual JSON construction (fallback if jq not available)
  STATE_JSON=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "host": "$PRODUCTION_HOST",
  "captured_by": "$CAPTURE_HOST",
  "versions": {
    "backend": "$BACKEND_VERSION",
    "frontend": "$FRONTEND_VERSION",
    "database": "$DATABASE_VERSION"
  },
  "services": {
    "backend": "$BACKEND_STATUS",
    "frontend": "$FRONTEND_STATUS",
    "database": "$DATABASE_STATUS"
  },
  "system": {
    "uptime_since": "$UPTIME",
    "load_average": {
      "1min": "$LOAD_1MIN",
      "5min": "$LOAD_5MIN",
      "15min": "$LOAD_15MIN"
    },
    "disk_usage": "$DISK_USAGE"
  },
  "metadata": {
    "capture_method": "ssh-remote",
    "schema_version": "1.0"
  }
}
EOF
)
fi

# ============================================================================
# Output JSON
# ============================================================================
if [ -n "$OUTPUT_FILE" ]; then
  echo "$STATE_JSON" > "$OUTPUT_FILE"
  log "${GREEN}✓ State captured and saved to: $OUTPUT_FILE${NC}"
  log ""
  log "Summary:"
  log "  Backend:  $BACKEND_VERSION ($BACKEND_STATUS)"
  log "  Frontend: $FRONTEND_VERSION ($FRONTEND_STATUS)"
  log "  Database: $DATABASE_VERSION ($DATABASE_STATUS)"
else
  # Output to stdout (no logging)
  echo "$STATE_JSON"
fi

exit 0
