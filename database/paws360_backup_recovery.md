# PAWS360 Database Backup & Recovery Procedures

## 🎯 Recovery Objectives

| Metric | Target | Description |
|--------|--------|-------------|
| **RTO** | < 4 hours | Recovery Time Objective |
| **RPO** | < 15 minutes | Recovery Point Objective |
| **Data Loss** | < 15 minutes | Maximum acceptable data loss |
| **Availability** | 99.9% | System uptime requirement |

## 📋 Backup Strategy

### Backup Types

#### 1. Full Database Backup (Daily)
```bash
# Full backup script
#!/bin/bash
BACKUP_DIR="/var/backups/paws360"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/paws360_full_$TIMESTAMP.sql"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Perform full backup
pg_dump -h localhost -U paws360_admin -d paws360 \
    --no-password \
    --format=custom \
    --compress=9 \
    --verbose \
    --file="$BACKUP_FILE"

# Verify backup integrity
pg_restore --list "$BACKUP_FILE" > /dev/null

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "paws360_full_*.sql" -mtime +30 -delete

echo "Full backup completed: $BACKUP_FILE"
```

#### 2. Incremental WAL Archives (Continuous)
```bash
# WAL archiving configuration in postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/backups/paws360/wal/%f'
archive_timeout = 60

# Create WAL directory
mkdir -p /var/backups/paws360/wal
chown postgres:postgres /var/backups/paws360/wal
```

#### 3. Configuration Backup (Daily)
```bash
# Backup PostgreSQL configuration
cp /etc/postgresql/15/main/postgresql.conf /var/backups/paws360/config/
cp /etc/postgresql/15/main/pg_hba.conf /var/backups/paws360/config/

# Backup PAWS360 application config
cp /opt/paws360/config/* /var/backups/paws360/app_config/
```

### Backup Schedule

| Backup Type | Frequency | Retention | Location |
|-------------|-----------|-----------|----------|
| Full Database | Daily 02:00 | 30 days | `/var/backups/paws360/full/` |
| WAL Archives | Continuous | 7 days | `/var/backups/paws360/wal/` |
| Configuration | Daily 02:30 | 90 days | `/var/backups/paws360/config/` |
| Application Data | Daily 03:00 | 30 days | `/var/backups/paws360/app/` |

## 🔄 Recovery Procedures

### Scenario 1: Complete Database Recovery

#### Step 1: Stop Application Services
```bash
# Stop all PAWS360 services
sudo systemctl stop paws360-api
sudo systemctl stop paws360-web
sudo systemctl stop paws360-worker
```

#### Step 2: Restore from Full Backup
```bash
# Drop and recreate database
sudo -u postgres psql -c "DROP DATABASE IF EXISTS paws360;"
sudo -u postgres psql -c "CREATE DATABASE paws360 OWNER paws360_admin;"

# Restore from latest full backup
LATEST_BACKUP=$(ls -t /var/backups/paws360/full/paws360_full_*.sql | head -1)
pg_restore -h localhost -U paws360_admin -d paws360 \
    --no-password \
    --verbose \
    "$LATEST_BACKUP"
```

#### Step 3: Apply WAL Archives
```bash
# Recover WAL files
sudo -u postgres psql -d paws360 -c "SELECT pg_wal_replay_resume();"

# Or manually apply WAL files if needed
# pg_waldump /var/backups/paws360/wal/ | tail -20
```

#### Step 4: Verify Data Integrity
```bash
# Run integrity checks
sudo -u postgres psql -d paws360 -c "ANALYZE VERBOSE;"

# Check row counts
sudo -u postgres psql -d paws360 << 'EOF'
SELECT 'users' as table_name, count(*) as row_count FROM paws360.users
UNION ALL
SELECT 'students', count(*) FROM paws360.students
UNION ALL
SELECT 'courses', count(*) FROM paws360.courses
UNION ALL
SELECT 'enrollments', count(*) FROM paws360.enrollments;
EOF
```

#### Step 5: Restart Application Services
```bash
# Start services in order
sudo systemctl start paws360-api
sudo systemctl start paws360-web
sudo systemctl start paws360-worker

# Verify services are running
curl -s http://localhost:8081/health
curl -s http://localhost:8080/
```

### Scenario 2: Point-in-Time Recovery (PITR)

#### Step 1: Stop PostgreSQL
```bash
sudo systemctl stop postgresql
```

#### Step 2: Restore Base Backup
```bash
# Remove old cluster data
sudo rm -rf /var/lib/postgresql/15/main/*

# Restore base backup
sudo -u postgres pg_restore -C /var/backups/paws360/full/paws360_full_20231201_020000.sql
```

#### Step 3: Configure Recovery
```bash
# Create recovery.conf
sudo -u postgres tee /var/lib/postgresql/15/main/recovery.conf << EOF
restore_command = 'cp /var/backups/paws360/wal/%f %p'
recovery_target_time = '2023-12-01 14:30:00'
recovery_target_action = 'promote'
EOF
```

#### Step 4: Start PostgreSQL
```bash
sudo systemctl start postgresql
```

#### Step 5: Monitor Recovery
```bash
# Check recovery progress
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
sudo -u postgres psql -c "SELECT pg_last_wal_replay_lsn();"
```

### Scenario 3: Single Table Recovery

#### Step 1: Identify Backup
```bash
# Find backup containing the table
ls -la /var/backups/paws360/full/
```

#### Step 2: Extract Table from Backup
```bash
# Create temporary database
sudo -u postgres createdb temp_recovery

# Restore only the specific table
pg_restore -d temp_recovery \
    --table=paws360.students \
    --data-only \
    /var/backups/paws360/full/paws360_full_20231201_020000.sql
```

#### Step 3: Export and Import Data
```bash
# Export data from temporary database
sudo -u postgres pg_dump -d temp_recovery \
    --table=paws360.students \
    --data-only \
    --column-inserts > /tmp/students_recovery.sql

# Import into production database
sudo -u postgres psql -d paws360 < /tmp/students_recovery.sql
```

#### Step 4: Cleanup
```bash
sudo -u postgres dropdb temp_recovery
rm /tmp/students_recovery.sql
```

## 🔧 Maintenance Procedures

### Regular Maintenance Tasks

#### Daily Maintenance
```bash
#!/bin/bash
# Daily maintenance script

# Update statistics
sudo -u postgres psql -d paws360 -c "ANALYZE;"

# Clean up expired sessions
sudo -u postgres psql -d paws360 -c "
DELETE FROM paws360.sessions
WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
"

# Archive old notifications
sudo -u postgres psql -d paws360 -c "
UPDATE paws360.notifications
SET is_read = true
WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
"
```

#### Weekly Maintenance
```bash
#!/bin/bash
# Weekly maintenance script

# Vacuum analyze for space reclamation
sudo -u postgres psql -d paws360 -c "VACUUM ANALYZE;"

# Reindex heavily used tables
sudo -u postgres psql -d paws360 -c "
REINDEX TABLE paws360.enrollments;
REINDEX TABLE paws360.students;
REINDEX TABLE paws360.users;
"

# Check for table bloat
sudo -u postgres psql -d paws360 -c "
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'paws360'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"
```

#### Monthly Maintenance
```bash
#!/bin/bash
# Monthly maintenance script

# Full database reindex
sudo -u postgres psql -d paws360 -c "REINDEX DATABASE paws360;"

# Check for unused indexes
sudo -u postgres psql -d paws360 -c "
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'paws360' AND idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
"

# Archive old audit logs (keep 2 years)
sudo -u postgres psql -d paws360 -c "
CREATE TABLE IF NOT EXISTS audit.audit_log_archive AS
SELECT * FROM audit.audit_log
WHERE timestamp < CURRENT_TIMESTAMP - INTERVAL '2 years';

DELETE FROM audit.audit_log
WHERE timestamp < CURRENT_TIMESTAMP - INTERVAL '2 years';
"
```

## 📊 Monitoring & Alerting

### Backup Monitoring
```bash
#!/bin/bash
# Backup monitoring script

BACKUP_DIR="/var/backups/paws360"
LOG_FILE="/var/log/paws360/backup_monitor.log"

# Check latest backup age
LATEST_BACKUP=$(find "$BACKUP_DIR/full" -name "*.sql" -mtime -1 | wc -l)

if [ "$LATEST_BACKUP" -eq 0 ]; then
    echo "$(date): WARNING - No recent full backup found" >> "$LOG_FILE"
    # Send alert
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"PAWS360: No recent database backup found!"}' \
        $SLACK_WEBHOOK_URL
fi

# Check backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "$(date): Backup directory size: $BACKUP_SIZE" >> "$LOG_FILE"

# Check WAL archive status
WAL_COUNT=$(find "$BACKUP_DIR/wal" -name "*.gz" -mtime -1 | wc -l)
echo "$(date): Recent WAL files: $WAL_COUNT" >> "$LOG_FILE"
```

### Recovery Testing
```bash
#!/bin/bash
# Recovery testing script

TEST_DB="paws360_recovery_test"
BACKUP_FILE="/var/backups/paws360/full/$(ls -t /var/backups/paws360/full/ | head -1)"

# Create test database
sudo -u postgres createdb "$TEST_DB"

# Test restore
pg_restore -d "$TEST_DB" --no-password "$BACKUP_FILE"

# Verify data integrity
sudo -u postgres psql -d "$TEST_DB" -c "
SELECT 'users' as table, count(*) as count FROM paws360.users
UNION ALL
SELECT 'students', count(*) FROM paws360.students
UNION ALL
SELECT 'courses', count(*) FROM paws360.courses;
"

# Cleanup
sudo -u postgres dropdb "$TEST_DB"

echo "$(date): Recovery test completed successfully" >> /var/log/paws360/recovery_test.log
```

## 🚨 Emergency Procedures

### Data Corruption Incident
1. **Isolate the Issue**: Stop application writes immediately
2. **Assess Damage**: Check affected tables and data volume
3. **Choose Recovery Method**: Full restore vs. table-level recovery
4. **Execute Recovery**: Follow appropriate recovery procedure
5. **Verify Integrity**: Run data validation checks
6. **Resume Operations**: Gradually bring services back online

### Storage Failure
1. **Stop Database**: `sudo systemctl stop postgresql`
2. **Replace Storage**: Mount new storage device
3. **Restore from Backup**: Use latest full backup + WAL files
4. **Verify Configuration**: Ensure PostgreSQL config is correct
5. **Start Database**: `sudo systemctl start postgresql`

### Security Breach
1. **Isolate System**: Disconnect from network
2. **Change Credentials**: Update all database passwords
3. **Audit Access**: Review recent database activity
4. **Restore from Clean Backup**: Use backup from before breach
5. **Update Security**: Apply security patches and updates

## 📋 Documentation Requirements

### Backup Documentation
- [ ] Backup schedule and retention policies
- [ ] Backup verification procedures
- [ ] Offsite backup storage locations
- [ ] Encryption methods for backups
- [ ] Backup testing frequency

### Recovery Documentation
- [ ] Step-by-step recovery procedures
- [ ] Contact information for team members
- [ ] Recovery time objectives (RTO)
- [ ] Recovery point objectives (RPO)
- [ ] Communication plan during outages

### Maintenance Documentation
- [ ] Regular maintenance schedules
- [ ] Performance monitoring procedures
- [ ] Capacity planning guidelines
- [ ] Upgrade procedures for PostgreSQL

## 🔗 Related Documentation

- **Database Schema Documentation**: `paws360_database_schema_docs.md`
- **Performance Tuning Guide**: `paws360_performance_tuning.md`
- **Security Procedures**: FERPA compliance documentation
- **Monitoring Setup**: Application monitoring configuration

---

**Last Updated**: September 18, 2025
**Review Frequency**: Quarterly
**Document Owner**: PAWS360 Database Administration Team</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_backup_recovery.md