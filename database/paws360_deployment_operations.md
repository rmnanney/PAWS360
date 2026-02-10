# PAWS360 Database Deployment & Operations Guide

## 🚀 Deployment Overview

### Deployment Architecture
```
Production Environment
├── Database Server (PostgreSQL 15+)
│   ├── Primary Database: paws360_prod
│   ├── Replica Database: paws360_prod_replica (Read-only)
│   └── Archive Database: paws360_archive (Historical data)
├── Application Servers
│   ├── Backend API (Spring Boot)
│   ├── Frontend SPA (React)
│   └── Admin Dashboard (AdminLTE)
└── Infrastructure
    ├── Load Balancer (HAProxy/Nginx)
    ├── Monitoring (Prometheus + Grafana)
    └── Backup Storage (AWS S3/Azure Blob)
```

### Deployment Prerequisites
- **PostgreSQL 15+** with required extensions
- **Java 21 LTS** for Spring Boot backend
- **Node.js 18+** for React frontend
- **Docker & Docker Compose** for containerized deployment
- **AWS/Azure CLI** for cloud resource management
- **SSL certificates** for secure connections

## 📦 Automated Deployment Scripts

### deploy.sh - Main Deployment Script
```bash
#!/bin/bash
# PAWS360 Production Deployment Script

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-staging}"
VERSION="${2:-latest}"
DEPLOY_DIR="/opt/paws360"
BACKUP_DIR="/opt/paws360/backups"
LOG_FILE="/var/log/paws360/deploy.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Deployment status
DEPLOYMENT_STATUS="unknown"

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$ENVIRONMENT] - $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    DEPLOYMENT_STATUS="failed"
    exit 1
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Validate environment
validate_environment() {
    log "Validating deployment environment..."

    # Check required tools
    command -v docker >/dev/null 2>&1 || error "Docker is not installed"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is not installed"
    command -v psql >/dev/null 2>&1 || error "PostgreSQL client is not installed"

    # Check environment variables
    [ -z "${DB_HOST:-}" ] && error "DB_HOST environment variable not set"
    [ -z "${DB_PASSWORD:-}" ] && error "DB_PASSWORD environment variable not set"

    # Validate database connection
    if ! psql -h "$DB_HOST" -U paws360_admin -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        error "Cannot connect to database server"
    fi

    success "Environment validation completed"
}

# Create backup
create_backup() {
    log "Creating pre-deployment backup..."

    local backup_file="$BACKUP_DIR/pre_deploy_$(date +%Y%m%d_%H%M%S).sql"

    mkdir -p "$BACKUP_DIR"

    if pg_dump -h "$DB_HOST" -U paws360_admin -d paws360_prod -f "$backup_file" --no-password; then
        success "Backup created: $backup_file"
        echo "$backup_file" > "$DEPLOY_DIR/last_backup.txt"
    else
        error "Failed to create backup"
    fi
}

# Deploy database changes
deploy_database() {
    log "Deploying database changes..."

    local db_name="paws360_${ENVIRONMENT}"

    # Create database if it doesn't exist
    psql -h "$DB_HOST" -U paws360_admin -d postgres -c "CREATE DATABASE $db_name;" 2>/dev/null || true

    # Run DDL if this is initial deployment
    if ! psql -h "$DB_HOST" -U paws360_admin -d "$db_name" -c "SELECT 1 FROM paws360.users LIMIT 1;" >/dev/null 2>&1; then
        info "Running initial DDL deployment..."
        psql -h "$DB_HOST" -U paws360_admin -d "$db_name" -f "$DEPLOY_DIR/paws360_database_ddl.sql"
        success "DDL deployed successfully"
    fi

    # Run migrations
    if [ -f "$DEPLOY_DIR/migrations/migrate.sh" ]; then
        info "Running database migrations..."
        cd "$DEPLOY_DIR/migrations"
        ./migrate.sh up
        success "Migrations completed"
    fi

    # Load seed data for staging/non-production
    if [ "$ENVIRONMENT" != "prod" ] && [ ! -f "$DEPLOY_DIR/.seed_loaded" ]; then
        info "Loading seed data..."
        psql -h "$DB_HOST" -U paws360_admin -d "$db_name" -f "$DEPLOY_DIR/paws360_seed_data.sql"
        touch "$DEPLOY_DIR/.seed_loaded"
        success "Seed data loaded"
    fi
}

# Deploy application
deploy_application() {
    log "Deploying application components..."

    cd "$DEPLOY_DIR"

    # Pull latest images
    info "Pulling Docker images..."
    docker-compose pull

    # Stop existing containers gracefully
    info "Stopping existing containers..."
    docker-compose down --timeout 30

    # Start new containers
    info "Starting application containers..."
    if docker-compose up -d; then
        success "Application containers started"
    else
        error "Failed to start application containers"
    fi

    # Wait for services to be healthy
    info "Waiting for services to be healthy..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose ps | grep -q "healthy\|running"; then
            success "All services are healthy"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            error "Services failed to become healthy within timeout"
        fi

        sleep 10
        ((attempt++))
    done
}

# Run post-deployment tests
run_post_deploy_tests() {
    log "Running post-deployment tests..."

    # Wait for application to be ready
    sleep 30

    # Test database connectivity
    if psql -h "$DB_HOST" -U paws360_app -d "paws360_${ENVIRONMENT}" -c "SELECT COUNT(*) FROM paws360.users;" >/dev/null 2>&1; then
        success "Database connectivity test passed"
    else
        error "Database connectivity test failed"
    fi

    # Test API endpoints
    if curl -f -s "http://localhost:8080/api/health" >/dev/null 2>&1; then
        success "API health check passed"
    else
        error "API health check failed"
    fi

    # Test frontend
    if curl -f -s "http://localhost:3000" >/dev/null 2>&1; then
        success "Frontend availability test passed"
    else
        error "Frontend availability test failed"
    fi
}

# Rollback deployment
rollback_deployment() {
    log "Rolling back deployment..."

    # Stop current containers
    docker-compose down

    # Restore from backup if available
    local last_backup
    if [ -f "$DEPLOY_DIR/last_backup.txt" ]; then
        last_backup=$(cat "$DEPLOY_DIR/last_backup.txt")
        if [ -f "$last_backup" ]; then
            info "Restoring from backup: $last_backup"
            psql -h "$DB_HOST" -U paws360_admin -d "paws360_${ENVIRONMENT}" -f "$last_backup"
            success "Database restored from backup"
        fi
    fi

    # Restart previous version
    if [ -f "$DEPLOY_DIR/docker-compose.previous.yml" ]; then
        info "Restarting previous version..."
        mv docker-compose.yml docker-compose.failed.yml
        mv docker-compose.previous.yml docker-compose.yml
        docker-compose up -d
        success "Previous version restarted"
    else
        error "No previous version available for rollback"
    fi
}

# Send notifications
send_notifications() {
    local status=$1
    local message=$2

    # Send email notification (requires mail command)
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "PAWS360 Deployment $status - $ENVIRONMENT" admin@paws360.edu
    fi

    # Send Slack notification (if webhook configured)
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
             --data "{\"text\":\"PAWS360 Deployment $status - $ENVIRONMENT: $message\"}" \
             "$SLACK_WEBHOOK"
    fi
}

# Main deployment flow
main() {
    DEPLOYMENT_STATUS="in_progress"

    log "Starting PAWS360 deployment to $ENVIRONMENT environment (version: $VERSION)"

    # Validate environment
    validate_environment

    # Create backup
    create_backup

    # Deploy database
    deploy_database

    # Deploy application
    deploy_application

    # Run tests
    run_post_deploy_tests

    DEPLOYMENT_STATUS="success"
    success "Deployment completed successfully"

    send_notifications "SUCCESS" "Deployment to $ENVIRONMENT completed successfully"
}

# Error handling
trap 'error "Deployment failed at line $LINENO"' ERR

# Parse command line arguments
case "${1:-help}" in
    "staging"|"prod")
        main
        ;;
    "rollback")
        rollback_deployment
        send_notifications "ROLLBACK" "Deployment rolled back for $ENVIRONMENT"
        ;;
    "status")
        echo "Deployment status: $DEPLOYMENT_STATUS"
        echo "Environment: $ENVIRONMENT"
        echo "Log file: $LOG_FILE"
        ;;
    "help"|"-h"|"--help")
        echo "PAWS360 Deployment Script"
        echo ""
        echo "Usage: $0 <environment> [version]"
        echo ""
        echo "Environments:"
        echo "  staging    Deploy to staging environment"
        echo "  prod       Deploy to production environment"
        echo "  rollback   Rollback to previous version"
        echo "  status     Show deployment status"
        echo ""
        echo "Examples:"
        echo "  $0 staging"
        echo "  $0 prod v1.2.3"
        echo "  $0 rollback"
        ;;
    *)
        echo "Invalid environment. Use 'staging' or 'prod'"
        exit 1
        ;;
esac
```

### docker-compose.prod.yml - Production Configuration
```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: paws360-postgres
    environment:
      POSTGRES_DB: paws360_prod
      POSTGRES_USER: paws360_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./backups:/backups
    ports:
      - "5432:5432"
    networks:
      - paws360_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U paws360_admin -d paws360_prod"]
      interval: 30s
      timeout: 10s
      retries: 3
    command: >
      postgres
      -c max_connections=200
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c maintenance_work_mem=64MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c default_statistics_target=100

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: paws360-redis
    command: redis-server --appendonly yes --maxmemory 512mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - paws360_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backend API
  backend:
    image: paws360/backend:${VERSION:-latest}
    container_name: paws360-backend
    environment:
      SPRING_PROFILES_ACTIVE: prod
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/paws360_prod
      SPRING_DATASOURCE_USERNAME: paws360_app
      SPRING_DATASOURCE_PASSWORD: ${DB_APP_PASSWORD}
      SPRING_REDIS_HOST: redis
      SPRING_REDIS_PORT: 6379
      JWT_SECRET: ${JWT_SECRET}
      SAML_ENTITY_ID: ${SAML_ENTITY_ID}
      SAML_IDP_METADATA_URL: ${SAML_IDP_METADATA_URL}
    ports:
      - "8080:8080"
    networks:
      - paws360_network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend SPA
  frontend:
    image: paws360/frontend:${VERSION:-latest}
    container_name: paws360-frontend
    environment:
      REACT_APP_API_BASE_URL: https://api.paws360.edu
      REACT_APP_SAML_LOGIN_URL: ${SAML_LOGIN_URL}
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./ssl:/etc/ssl/certs
    networks:
      - paws360_network
    depends_on:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Admin Dashboard
  admin:
    image: paws360/admin:${VERSION:-latest}
    container_name: paws360-admin
    environment:
      API_BASE_URL: https://api.paws360.edu
      ADMIN_USERNAME: ${ADMIN_USERNAME}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD}
    ports:
      - "8081:80"
    networks:
      - paws360_network
    depends_on:
      - backend
    restart: unless-stopped

  # Nginx Load Balancer
  nginx:
    image: nginx:alpine
    container_name: paws360-nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/ssl/certs:ro
    ports:
      - "80:80"
      - "443:443"
    networks:
      - paws360_network
    depends_on:
      - frontend
      - backend
      - admin
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  paws360_network:
    driver: bridge
```

## 🔧 Operational Procedures

### Database Maintenance Scripts

#### maintenance.sh - Daily Maintenance
```bash
#!/bin/bash
# PAWS360 Daily Database Maintenance

set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-paws360_prod}"
LOG_FILE="/var/log/paws360/maintenance.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Vacuum and analyze tables
perform_vacuum() {
    log "Starting VACUUM ANALYZE..."

    psql -h "$DB_HOST" -d "$DB_NAME" -c "
        VACUUM ANALYZE paws360.users;
        VACUUM ANALYZE paws360.students;
        VACUUM ANALYZE paws360.enrollments;
        VACUUM ANALYZE paws360.audit_log;
    "

    log "VACUUM ANALYZE completed"
}

# Update table statistics
update_statistics() {
    log "Updating table statistics..."

    psql -h "$DB_HOST" -d "$DB_NAME" -c "ANALYZE;"

    log "Statistics update completed"
}

# Reindex tables if needed
check_reindex() {
    log "Checking for reindex requirements..."

    # Check for bloated indexes
    psql -h "$DB_HOST" -d "$DB_NAME" -c "
        SELECT schemaname, tablename, indexname
        FROM pg_stat_user_indexes
        WHERE idx_scan = 0
          AND schemaname = 'paws360'
        ORDER BY schemaname, tablename;
    " | while read -r schema table index; do
        if [ "$schema" = "paws360" ]; then
            log "Reindexing unused index: $schema.$table.$index"
            psql -h "$DB_HOST" -d "$DB_NAME" -c "REINDEX INDEX $schema.$index;"
        fi
    done

    log "Reindex check completed"
}

# Archive old audit logs
archive_audit_logs() {
    log "Archiving old audit logs..."

    local archive_date=$(date -d '30 days ago' +%Y-%m-%d)

    psql -h "$DB_HOST" -d "$DB_NAME" -c "
        INSERT INTO paws360.audit_log_archive
        SELECT * FROM paws360.audit_log
        WHERE action_timestamp < '$archive_date';

        DELETE FROM paws360.audit_log
        WHERE action_timestamp < '$archive_date';
    "

    log "Audit log archiving completed"
}

# Update materialized views
refresh_materialized_views() {
    log "Refreshing materialized views..."

    psql -h "$DB_HOST" -d "$DB_NAME" -c "
        REFRESH MATERIALIZED VIEW CONCURRENTLY paws360.student_performance_mv;
        REFRESH MATERIALIZED VIEW CONCURRENTLY paws360.course_enrollment_mv;
    "

    log "Materialized view refresh completed"
}

# Main maintenance routine
main() {
    log "Starting daily maintenance routine..."

    perform_vacuum
    update_statistics
    check_reindex
    archive_audit_logs
    refresh_materialized_views

    log "Daily maintenance routine completed successfully"
}

# Run maintenance
main
```

#### backup.sh - Automated Backup
```bash
#!/bin/bash
# PAWS360 Database Backup Script

set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-paws360_prod}"
BACKUP_DIR="${BACKUP_DIR:-/opt/paws360/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
LOG_FILE="/var/log/paws360/backup.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

# Create backup directory
setup_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
}

# Perform full backup
full_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/full_backup_$timestamp.sql"
    local compressed_file="$backup_file.gz"

    log "Starting full backup: $backup_file"

    # Create backup
    if pg_dump -h "$DB_HOST" -U paws360_admin -d "$DB_NAME" \
               --no-password --format=custom --compress=9 \
               --file="$backup_file" --verbose; then

        # Compress backup
        gzip "$backup_file"
        success "Full backup completed: $compressed_file"

        # Verify backup
        if pg_restore --list "$compressed_file" >/dev/null 2>&1; then
            success "Backup verification passed"
        else
            error "Backup verification failed"
        fi

    else
        error "Full backup failed"
    fi
}

# Perform incremental backup (WAL archiving)
incremental_backup() {
    log "Starting incremental backup..."

    # Switch WAL file
    psql -h "$DB_HOST" -U paws360_admin -d "$DB_NAME" -c "SELECT pg_switch_wal();"

    # Archive current WAL files
    local wal_dir="/var/lib/postgresql/data/pg_wal"
    local archive_dir="$BACKUP_DIR/wal"

    mkdir -p "$archive_dir"

    # Copy WAL files (simplified - requires WAL archiving setup)
    find "$wal_dir" -name "*.ready" -exec mv {} "$archive_dir" \;

    success "Incremental backup completed"
}

# Upload to cloud storage
upload_to_cloud() {
    local backup_file=$1

    if [ -n "${AWS_S3_BUCKET:-}" ]; then
        log "Uploading to AWS S3: $AWS_S3_BUCKET"
        aws s3 cp "$backup_file" "s3://$AWS_S3_BUCKET/backups/$(basename "$backup_file")"
        success "Backup uploaded to S3"
    elif [ -n "${AZURE_STORAGE_ACCOUNT:-}" ]; then
        log "Uploading to Azure Blob Storage"
        az storage blob upload --account-name "$AZURE_STORAGE_ACCOUNT" \
                               --container-name backups \
                               --name "$(basename "$backup_file")" \
                               --file "$backup_file"
        success "Backup uploaded to Azure"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."

    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$RETENTION_DAYS" -delete
    find "$BACKUP_DIR" -name "*.backup" -mtime +"$RETENTION_DAYS" -delete

    success "Old backup cleanup completed"
}

# Send backup report
send_backup_report() {
    local status=$1
    local backup_file=$2
    local backup_size

    if [ -f "$backup_file" ]; then
        backup_size=$(du -h "$backup_file" | cut -f1)
    else
        backup_size="N/A"
    fi

    local message="PAWS360 Backup $status
Date: $(date)
File: $(basename "$backup_file")
Size: $backup_size
Retention: $RETENTION_DAYS days"

    # Send email
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "PAWS360 Backup $status" dba@paws360.edu
    fi
}

# Main backup routine
main() {
    local backup_type="${1:-full}"
    local backup_file=""

    log "Starting $backup_type backup routine..."

    setup_backup_dir

    case "$backup_type" in
        "full")
            full_backup
            backup_file=$(ls -t "$BACKUP_DIR"/full_backup_*.sql.gz | head -1)
            ;;
        "incremental")
            incremental_backup
            ;;
        *)
            error "Invalid backup type: $backup_type"
            ;;
    esac

    # Upload to cloud if configured
    if [ -n "$backup_file" ]; then
        upload_to_cloud "$backup_file"
    fi

    # Cleanup old backups
    cleanup_old_backups

    # Send report
    send_backup_report "SUCCESS" "${backup_file:-N/A}"

    log "$backup_type backup routine completed successfully"
}

# Run backup
main "$@"
```

### Monitoring & Alerting

#### monitoring.sh - Health Checks
```bash
#!/bin/bash
# PAWS360 System Monitoring Script

set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-paws360_prod}"
API_URL="${API_URL:-http://localhost:8080}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:80}"
ALERT_EMAIL="${ALERT_EMAIL:-admin@paws360.edu}"
LOG_FILE="/var/log/paws360/monitoring.log"

# Thresholds
DB_CONNECTION_THRESHOLD=5
API_RESPONSE_THRESHOLD=3000  # ms
DISK_USAGE_THRESHOLD=85      # %
MEMORY_USAGE_THRESHOLD=85    # %

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

alert() {
    local message=$1
    echo -e "${RED}ALERT:${NC} $message" >&2

    # Send email alert
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "PAWS360 System Alert" "$ALERT_EMAIL"
    fi

    # Send Slack alert
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
             --data "{\"text\":\"🚨 PAWS360 Alert: $message\"}" \
             "$SLACK_WEBHOOK"
    fi
}

warning() {
    local message=$1
    echo -e "${YELLOW}WARNING:${NC} $message"
}

success() {
    echo -e "${GREEN}OK:${NC} $1"
}

# Database health check
check_database() {
    local start_time=$(date +%s%3N)
    local db_status=""

    if psql -h "$DB_HOST" -U paws360_app -d "$DB_NAME" \
            -c "SELECT 1;" >/dev/null 2>&1; then
        local end_time=$(date +%s%3N)
        local response_time=$((end_time - start_time))
        db_status="OK (${response_time}ms)"
        success "Database connection: $db_status"
    else
        db_status="FAILED"
        alert "Database connection failed"
        return 1
    fi
}

# API health check
check_api() {
    local start_time=$(date +%s%3N)
    local http_code

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
                     --max-time 10 "$API_URL/api/health")

    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))

    if [ "$http_code" = "200" ]; then
        if [ "$response_time" -gt "$API_RESPONSE_THRESHOLD" ]; then
            warning "API response slow: ${response_time}ms"
        else
            success "API health: OK (${response_time}ms)"
        fi
    else
        alert "API health check failed (HTTP $http_code)"
        return 1
    fi
}

# Frontend health check
check_frontend() {
    local http_code

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
                     --max-time 10 "$FRONTEND_URL")

    if [ "$http_code" = "200" ]; then
        success "Frontend availability: OK"
    else
        alert "Frontend check failed (HTTP $http_code)"
        return 1
    fi
}

# Database performance check
check_db_performance() {
    local active_connections
    local slow_queries

    # Check active connections
    active_connections=$(psql -h "$DB_HOST" -U paws360_app -d "$DB_NAME" \
                          -t -c "SELECT count(*) FROM pg_stat_activity;")

    if [ "$active_connections" -gt "$DB_CONNECTION_THRESHOLD" ]; then
        warning "High database connections: $active_connections"
    else
        success "Database connections: $active_connections"
    fi

    # Check for slow queries
    slow_queries=$(psql -h "$DB_HOST" -U paws360_app -d "$DB_NAME" \
                    -t -c "
                        SELECT count(*)
                        FROM pg_stat_activity
                        WHERE state = 'active'
                          AND now() - query_start > interval '30 seconds';
                    ")

    if [ "$slow_queries" -gt 0 ]; then
        warning "Slow queries detected: $slow_queries"
    fi
}

# System resource check
check_system_resources() {
    local disk_usage
    local memory_usage

    # Check disk usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt "$DISK_USAGE_THRESHOLD" ]; then
        alert "High disk usage: ${disk_usage}%"
    else
        success "Disk usage: ${disk_usage}%"
    fi

    # Check memory usage
    memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

    if [ "$memory_usage" -gt "$MEMORY_USAGE_THRESHOLD" ]; then
        alert "High memory usage: ${memory_usage}%"
    else
        success "Memory usage: ${memory_usage}%"
    fi
}

# Replication lag check (if replica exists)
check_replication_lag() {
    if psql -h "$DB_HOST" -U paws360_app -d "$DB_NAME" \
            -c "SELECT 1;" >/dev/null 2>&1; then

        local lag_seconds

        lag_seconds=$(psql -h "$DB_HOST" -U paws360_app -d "$DB_NAME" \
                      -t -c "
                          SELECT extract(epoch from now() - pg_last_xact_replay_timestamp())::integer
                          FROM pg_stat_replication
                          WHERE application_name = 'paws360_replica';
                      " 2>/dev/null || echo "0")

        if [ "$lag_seconds" -gt 300 ]; then  # 5 minutes
            warning "Replication lag: ${lag_seconds}s"
        else
            success "Replication lag: ${lag_seconds}s"
        fi
    fi
}

# Main monitoring routine
main() {
    local failures=0

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting system health check..."

    check_database || ((failures++))
    check_api || ((failures++))
    check_frontend || ((failures++))
    check_db_performance
    check_system_resources
    check_replication_lag

    echo "$(date '+%Y-%m-%d %H:%M:%S') - Health check completed with $failures failures"

    # Exit with failure if critical checks failed
    if [ $failures -gt 0 ]; then
        exit 1
    fi
}

# Run monitoring
main
```

## 📊 Monitoring Dashboard Setup

### Grafana Dashboard Configuration
```json
{
  "dashboard": {
    "title": "PAWS360 System Monitoring",
    "tags": ["paws360", "production"],
    "timezone": "America/Chicago",
    "panels": [
      {
        "title": "Database Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "pg_stat_activity_count{datname=\"paws360_prod\"}",
            "legendFormat": "Active Connections"
          }
        ]
      },
      {
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "http_request_duration_seconds{quantile=\"0.95\", service=\"paws360-api\"}",
            "legendFormat": "95th Percentile"
          }
        ]
      },
      {
        "title": "System Resources",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          },
          {
            "expr": "(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100",
            "legendFormat": "Memory Usage %"
          }
        ]
      },
      {
        "title": "Database Performance",
        "type": "table",
        "targets": [
          {
            "expr": "pg_stat_user_tables_n_tup_ins",
            "legendFormat": "Inserts"
          },
          {
            "expr": "pg_stat_user_tables_n_tup_upd",
            "legendFormat": "Updates"
          },
          {
            "expr": "pg_stat_user_tables_n_tup_del",
            "legendFormat": "Deletes"
          }
        ]
      }
    ]
  }
}
```

### Prometheus Configuration
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'paws360-postgres'
    static_configs:
      - targets: ['postgres:9187']
    scrape_interval: 30s

  - job_name: 'paws360-backend'
    static_configs:
      - targets: ['backend:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 15s

  - job_name: 'paws360-frontend'
    static_configs:
      - targets: ['frontend:80']
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s
```

## 🚨 Incident Response Procedures

### Critical Incident Response
```bash
#!/bin/bash
# PAWS360 Critical Incident Response Script

set -euo pipefail

# Configuration
INCIDENT_LOG="/var/log/paws360/incidents.log"
BACKUP_DIR="/opt/paws360/emergency_backups"

log_incident() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - CRITICAL INCIDENT: $1" >> "$INCIDENT_LOG"
}

# Step 1: Assess the situation
assess_situation() {
    log_incident "Starting incident assessment"

    # Check database connectivity
    if ! psql -h "$DB_HOST" -U paws360_admin -d paws360_prod -c "SELECT 1;" >/dev/null 2>&1; then
        log_incident "Database connectivity failed"
        return 1
    fi

    # Check application status
    if ! curl -f -s "http://localhost:8080/api/health" >/dev/null 2>&1; then
        log_incident "Application health check failed"
        return 1
    fi

    log_incident "System appears operational"
    return 0
}

# Step 2: Isolate the problem
isolate_problem() {
    log_incident "Isolating problem area"

    # Check database locks
    psql -h "$DB_HOST" -U paws360_admin -d paws360_prod -c "
        SELECT pid, usename, pg_blocking_pids(pid) as blocked_by,
               query_start, now() - query_start as duration, query
        FROM pg_stat_activity
        WHERE state = 'active' AND now() - query_start > interval '5 minutes';
    " >> "$INCIDENT_LOG"

    # Check system resources
    echo "=== System Resources ===" >> "$INCIDENT_LOG"
    top -b -n1 | head -20 >> "$INCIDENT_LOG"
    df -h >> "$INCIDENT_LOG"
    free -h >> "$INCIDENT_LOG"
}

# Step 3: Implement temporary fix
temporary_fix() {
    log_incident "Implementing temporary fix"

    # Kill long-running queries
    psql -h "$DB_HOST" -U paws360_admin -d paws360_prod -c "
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE state = 'active'
          AND now() - query_start > interval '10 minutes'
          AND usename != 'paws360_admin';
    "

    # Restart services if needed
    if ! curl -f -s "http://localhost:8080/api/health" >/dev/null 2>&1; then
        log_incident "Restarting backend service"
        docker-compose restart backend
    fi
}

# Step 4: Create emergency backup
emergency_backup() {
    log_incident "Creating emergency backup"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/emergency_$timestamp.sql"

    mkdir -p "$BACKUP_DIR"

    pg_dump -h "$DB_HOST" -U paws360_admin -d paws360_prod \
            --no-password --format=custom --compress=9 \
            --file="$backup_file"

    log_incident "Emergency backup created: $backup_file"
}

# Step 5: Escalate if needed
escalate_incident() {
    log_incident "Escalating incident to on-call team"

    local message="CRITICAL INCIDENT: PAWS360 system issue detected
Time: $(date)
Logs: $INCIDENT_LOG
Backup: $BACKUP_DIR/emergency_$(date +%Y%m%d_%H%M%S).sql

Immediate action required!"

    # Send to escalation contacts
    echo "$message" | mail -s "CRITICAL: PAWS360 Incident" escalation@paws360.edu
}

# Main incident response
main() {
    log_incident "Critical incident detected - initiating response protocol"

    if ! assess_situation; then
        isolate_problem
        emergency_backup
        temporary_fix

        # Re-assess after temporary fix
        if ! assess_situation; then
            escalate_incident
        else
            log_incident "Issue resolved with temporary fix"
        fi
    fi

    log_incident "Incident response completed"
}

# Run incident response
main
```

## 📋 Operational Checklists

### Daily Operations Checklist
- [ ] **Review system logs** for errors and warnings
- [ ] **Check database performance** metrics
- [ ] **Verify backup completion** and integrity
- [ ] **Monitor disk space** usage
- [ ] **Review security alerts** and access logs
- [ ] **Check application health** endpoints
- [ ] **Verify data synchronization** between systems
- [ ] **Review user support tickets** for trends

### Weekly Operations Checklist
- [ ] **Run database maintenance** (VACUUM, ANALYZE, REINDEX)
- [ ] **Review and rotate logs** older than 30 days
- [ ] **Test backup restoration** procedures
- [ ] **Update security patches** and dependencies
- [ ] **Review performance metrics** and trends
- [ ] **Audit user access** and permissions
- [ ] **Check certificate expiration** dates
- [ ] **Review monitoring alerts** configuration

### Monthly Operations Checklist
- [ ] **Full system backup** verification
- [ ] **Database statistics** update and review
- [ ] **Security vulnerability** assessment
- [ ] **Performance optimization** review
- [ ] **Documentation updates** and reviews
- [ ] **Disaster recovery** test execution
- [ ] **Compliance audit** preparation
- [ ] **Capacity planning** assessment

### Quarterly Operations Checklist
- [ ] **Major version updates** planning and testing
- [ ] **Infrastructure scaling** assessment
- [ ] **Business continuity** plan review
- [ ] **Vendor security assessments** review
- [ ] **Data retention policy** compliance check
- [ ] **User training** and awareness updates
- [ ] **Incident response** procedure testing

---

**Deployment & Operations Guide Version**: 1.0
**Last Updated**: September 18, 2025
**Operations Team**: PAWS360 DevOps Team</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_deployment_operations.md