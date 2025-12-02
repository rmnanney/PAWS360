# Backup & Recovery Playbook

Complete guide for backing up and restoring PostgreSQL data in the PAWS360 development environment.

## Table of Contents

- [Overview](#overview)
- [Backup Strategies](#backup-strategies)
- [Backup Procedures](#backup-procedures)
- [Restore Procedures](#restore-procedures)
- [Snapshot Procedures](#snapshot-procedures)
- [Common Recovery Scenarios](#common-recovery-scenarios)
- [Disaster Recovery](#disaster-recovery)
- [Point-in-Time Recovery (PITR)](#point-in-time-recovery-pitr)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

PAWS360 provides multiple backup and recovery mechanisms:

| Method | Use Case | Speed | Granularity | Downtime Required |
|--------|----------|-------|-------------|-------------------|
| **Logical Backup** (`dev-backup`) | Quick snapshots, migrations, schema changes | Fast (seconds) | Database-level | No |
| **Volume Snapshot** (`dev-snapshot`) | Full system state, disaster recovery | Medium (1-2 min) | Cluster-level | Yes (brief pause) |
| **Auto-Backup Hooks** | Automatic protection before risky operations | Fast | Database-level | No |

### Automatic Backup Protection

The following operations automatically create backups before execution:

- `make dev-reset` - Before destroying all data/volumes
- `make dev-migrate` - Before running database migrations
- `make test-failover` - Before simulating leader failure

These backups are stored in `backups/backup_YYYYMMDD_HHMMSS.sql` with automatic cleanup (keeps last 10).

---

## Backup Strategies

### 1. Logical Backups (pg_dumpall)

**What it backs up:**
- All databases, schemas, tables, data
- User accounts, roles, permissions
- Database configuration settings

**What it DOESN'T back up:**
- PostgreSQL server configuration files (postgresql.conf, pg_hba.conf)
- Patroni cluster state
- Write-Ahead Logs (WAL)

**When to use:**
- Before schema migrations
- Before major data modifications
- Daily development snapshots
- Cross-environment data transfers

### 2. Volume Snapshots (tar.gz)

**What it backs up:**
- Complete PostgreSQL data directory
- WAL files for point-in-time recovery
- All cluster state (replication slots, statistics)
- Patroni metadata

**What it DOESN'T back up:**
- Running transactions (requires cluster stop)
- Network connections and sessions

**When to use:**
- Before major infrastructure changes
- Before upgrading PostgreSQL versions
- Full disaster recovery scenarios
- Replicating exact cluster state

---

## Backup Procedures

### Quick Logical Backup

```bash
# Create a timestamped backup
make dev-backup

# Output: backups/backup_20251127_143022.sql
# Retention: Keeps last 10 backups automatically
```

**What happens:**
1. Creates `backups/` directory if missing
2. Generates timestamp: `YYYYMMDD_HHMMSS`
3. Executes `pg_dumpall` via PostgreSQL leader
4. Stores SQL file in `backups/backup_YYYYMMDD_HHMMSS.sql`
5. Cleans up old backups (keeps last 10)

**Verification:**
```bash
# List all backups (newest first)
ls -lht backups/*.sql | head -10

# Check backup file size (should be >1MB for seeded data)
du -h backups/backup_*.sql

# Verify SQL file integrity
head -20 backups/backup_20251127_143022.sql
# Should show: "-- PostgreSQL database cluster dump"
```

### Volume Snapshot (Offline Backup)

```bash
# Create a complete volume snapshot
make dev-snapshot

# Output: backups/snapshots/{timestamp}_patroni{1,2,3}.tar.gz
```

**What happens:**
1. Stops Patroni cluster gracefully (`docker-compose stop`)
2. Creates `backups/snapshots/` directory
3. Mounts each Patroni volume (`patroni1-data`, `patroni2-data`, `patroni3-data`)
4. Creates compressed tar.gz for each volume
5. Restarts Patroni cluster (`docker-compose up -d`)

**Typical snapshot sizes:**
- Fresh install: ~50-100 MB per volume
- With demo data: ~150-300 MB per volume
- After heavy usage: ~500 MB - 2 GB per volume

**Verification:**
```bash
# List all snapshots
ls -lh backups/snapshots/

# Check snapshot integrity
tar -tzf backups/snapshots/20251127_143022_patroni1.tar.gz | head -20
# Should show: base/, global/, pg_wal/, etc.
```

---

## Restore Procedures

### Restore from Logical Backup

```bash
# Interactive restore with backup selection
make dev-restore
```

**Interactive prompts:**
```
📂 Available backups (last 10, newest first):
-rw-r--r-- 1 user user 2.3M Nov 27 14:30 backup_20251127_143022.sql
-rw-r--r-- 1 user user 2.1M Nov 27 12:15 backup_20251127_121500.sql
...

📥 Enter backup filename to restore: backup_20251127_143022.sql

⚠️  WARNING: This will REPLACE all current data!
Type 'yes' to confirm: yes
```

**What happens:**
1. Lists last 10 backups (newest first)
2. Prompts for filename selection
3. Requires 'yes' confirmation
4. Stops backend and frontend services
5. Drops all existing databases
6. Restores from SQL file via `psql`
7. Restarts backend and frontend services

**Common errors:**
```
❌ Backup file not found
→ Check filename spelling, run: ls -lh backups/

❌ psql: FATAL: database "postgres" does not exist
→ Patroni cluster not running, run: make dev-up

❌ ERROR: must be owner of database
→ Expected during restore (non-fatal), database will be recreated
```

### Restore from Volume Snapshot

```bash
# DESTRUCTIVE: Replaces all volumes with snapshot data
make dev-restore-snapshot
```

**Interactive prompts:**
```
📂 Available snapshots:
20251127_143022_patroni1.tar.gz (157 MB)
20251126_090000_patroni1.tar.gz (142 MB)

📥 Enter snapshot basename (without _patroniX.tar.gz): 20251127_143022

⚠️  WARNING: This will DESTROY all current volumes!
Type 'DESTROY' to confirm: DESTROY
```

**What happens:**
1. Lists available snapshots (grouped by timestamp)
2. Prompts for timestamp basename
3. Requires 'DESTROY' confirmation (case-sensitive)
4. Stops and removes all containers
5. Deletes existing volumes (`patroni1-data`, `patroni2-data`, `patroni3-data`)
6. Creates new empty volumes
7. Extracts tar.gz files into new volumes
8. Runs `make dev-up` to start cluster with restored data

**Recovery time:**
- Small snapshots (<500 MB): ~30-60 seconds
- Large snapshots (2-5 GB): ~2-5 minutes

---

## Snapshot Procedures

### Creating Consistent Snapshots

For production-grade snapshots with zero data loss:

```bash
# 1. Create logical backup first (no downtime)
make dev-backup

# 2. Create volume snapshot (brief downtime)
make dev-snapshot

# 3. Verify both backups exist
ls -lh backups/backup_*.sql backups/snapshots/*.tar.gz
```

### Snapshot Naming Convention

```
backups/snapshots/YYYYMMDD_HHMMSS_patroniX.tar.gz
                  └─ Timestamp ─┘  └─ Node ─┘

Example: 20251127_143022_patroni1.tar.gz
```

### Off-Site Backup Storage

```bash
# Copy backups to external storage
rsync -avz backups/ /mnt/external-drive/paws360-backups/

# Upload to cloud storage (example)
aws s3 sync backups/ s3://paws360-backups/dev/

# Verify backup integrity after transfer
cd /mnt/external-drive/paws360-backups/
md5sum -c checksums.md5
```

---

## Common Recovery Scenarios

### Scenario 1: Undo a Failed Migration

**Problem:** Migration script introduced data corruption or schema errors.

**Solution:**
```bash
# Automatic backup was created before migration
# Find the pre-migration backup
ls -lht backups/*.sql | head -3

# Restore from backup immediately before migration
make dev-restore
# Select: backup_20251127_141500.sql (timestamp before migration)

# Verify data integrity
make dev-shell-db
# Run: SELECT COUNT(*) FROM students;
```

**Recovery time:** 30-60 seconds

---

### Scenario 2: Revert to Known Good State

**Problem:** Uncertain when corruption occurred, need to restore yesterday's data.

**Solution:**
```bash
# List backups with timestamps
ls -lht backups/*.sql

# Identify known good backup (e.g., from yesterday morning)
# Restore that specific backup
make dev-restore
# Select: backup_20251126_090000.sql

# Test application functionality
curl -s http://localhost:8080/api/health | jq
```

**Recovery time:** 30-60 seconds

---

### Scenario 3: Recover from Accidental DELETE

**Problem:** Ran `DELETE FROM grades WHERE student_id = 123` without `WHERE` clause by mistake.

**Solution:**
```bash
# Option A: Restore entire database (if recent backup exists)
make dev-restore
# Select most recent backup before DELETE

# Option B: Extract specific table from backup
cat backups/backup_20251127_143022.sql | \
  grep -A 10000 "COPY public.grades" | \
  head -n +$(grep -n "\\." - | head -1 | cut -d: -f1) | \
  docker exec -i paws360-patroni1 psql -U postgres -d paws360
```

**Recovery time:** 
- Option A (full restore): 30-60 seconds
- Option B (table extraction): 5-15 seconds

---

### Scenario 4: Disaster Recovery - Complete Cluster Failure

**Problem:** All Patroni nodes corrupted, volumes unrecoverable.

**Solution:**
```bash
# 1. Verify backup files exist
ls -lh backups/snapshots/20251127_*.tar.gz
# Should show 3 files (patroni1, patroni2, patroni3)

# 2. Restore from volume snapshots
make dev-restore-snapshot
# Select: 20251127_143022
# Type: DESTROY

# 3. Wait for cluster recovery (~2-3 minutes)
make wait-healthy

# 4. Verify data integrity
make dev-shell-db
# Run: SELECT COUNT(*) FROM students;

# 5. Verify replication status
curl -s http://localhost:8008/patroni | jq '.replication'
```

**Recovery time:** 3-5 minutes (including health checks)

---

### Scenario 5: Restore Specific Table to Different Environment

**Problem:** Need to copy `courses` table from production backup to local dev.

**Solution:**
```bash
# 1. Extract table schema and data from backup
grep -A 1000 "CREATE TABLE public.courses" backups/backup_prod_20251127.sql > courses_schema.sql
grep -A 10000 "COPY public.courses" backups/backup_prod_20251127.sql | \
  head -n +$(grep -n "\\." - | head -1 | cut -d: -f1) > courses_data.sql

# 2. Import into local dev
cat courses_schema.sql courses_data.sql | \
  docker exec -i paws360-patroni1 psql -U postgres -d paws360

# 3. Verify import
make dev-shell-db
# Run: SELECT COUNT(*) FROM courses;
```

**Recovery time:** 10-30 seconds

---

## Disaster Recovery

### Full Disaster Recovery Procedure

**Scenario:** Complete infrastructure failure (laptop crash, corrupted Docker volumes, etc.)

**Prerequisites:**
- ✅ Backup files stored off-site (external drive, cloud storage, Git LFS)
- ✅ PAWS360 repository cloned
- ✅ Docker/Podman installed

**Recovery steps:**

```bash
# 1. Clone repository (if needed)
git clone https://github.com/your-org/PAWS360.git
cd PAWS360

# 2. Restore backup files from off-site storage
rsync -avz /mnt/external-drive/paws360-backups/ backups/
# OR: aws s3 sync s3://paws360-backups/dev/ backups/

# 3. Verify backup integrity
ls -lh backups/snapshots/
# Should show 3 files per snapshot timestamp

# 4. Bootstrap environment
make dev-setup  # Install dependencies, validate system

# 5. Restore from snapshots
make dev-restore-snapshot
# Select latest snapshot timestamp

# 6. Verify full recovery
make wait-healthy
make dev-shell-db
# Run comprehensive data validation queries

# 7. Test application functionality
curl http://localhost:3000  # Frontend
curl http://localhost:8080/api/health  # Backend
```

**Total recovery time:** 10-20 minutes (depending on backup size and network speed)

### Disaster Recovery Checklist

- [ ] Backup files stored in ≥2 locations (local + off-site)
- [ ] Backup retention policy documented (keep last 30 days)
- [ ] Recovery procedure tested monthly
- [ ] Recovery Time Objective (RTO): <30 minutes
- [ ] Recovery Point Objective (RPO): <24 hours (daily backups)
- [ ] Off-site backup verification automated (weekly integrity checks)

---

## Point-in-Time Recovery (PITR)

PostgreSQL Write-Ahead Logs (WAL) enable recovery to any point in time. This requires volume snapshots (logical backups don't include WAL).

### Enable WAL Archiving (Future Enhancement)

**Current limitation:** PAWS360 dev environment doesn't enable WAL archiving by default (performance trade-off).

**To enable PITR:**

```yaml
# infrastructure/compose/docker-compose.patroni.yml
patroni1:
  environment:
    - PATRONI_POSTGRESQL_PARAMETERS_ARCHIVE_MODE=on
    - PATRONI_POSTGRESQL_PARAMETERS_ARCHIVE_COMMAND=test ! -f /wal_archive/%f && cp %p /wal_archive/%f
  volumes:
    - patroni1-wal:/wal_archive
```

### PITR Recovery Example

```bash
# 1. Restore base volume snapshot (e.g., from yesterday)
make dev-restore-snapshot
# Select: 20251126_090000

# 2. Configure recovery target time
docker exec -it paws360-patroni1 bash
cat > /var/lib/postgresql/data/recovery.conf <<EOF
restore_command = 'cp /wal_archive/%f %p'
recovery_target_time = '2025-11-27 14:30:00'
recovery_target_action = 'promote'
EOF

# 3. Restart PostgreSQL to trigger recovery
docker-compose restart patroni1

# 4. Monitor recovery progress
docker logs -f paws360-patroni1
# Look for: "recovery stopping before commit of transaction"
```

**Use cases:**
- Recover to state immediately before erroneous DELETE/UPDATE
- Investigate historical data at specific timestamp
- Forensic analysis of data changes

---

## Best Practices

### Backup Frequency

| Environment | Logical Backups | Volume Snapshots |
|-------------|-----------------|------------------|
| **Development** | Before migrations, major changes | Weekly or before infrastructure changes |
| **Staging** | Daily (automated cron) | Weekly |
| **Production** | Hourly (continuous backup) | Daily + WAL archiving for PITR |

### Retention Policies

```bash
# Development: Keep last 10 backups (automatic)
# - Configured in Makefile.dev (ls -t | tail -n +11 | xargs -r rm)

# Staging/Production: Keep last 30 days + monthly archives
find backups/ -name "backup_*.sql" -mtime +30 -delete
find backups/snapshots/ -name "*.tar.gz" -mtime +30 -delete

# Monthly archival (first Sunday of each month)
if [ $(date +%u) -eq 7 ] && [ $(date +%d) -le 7 ]; then
  cp backups/backup_*.sql /archives/monthly/backup_$(date +%Y%m).sql
fi
```

### Backup Validation

```bash
#!/bin/bash
# scripts/validate-backup.sh

BACKUP_FILE="$1"

echo "🔍 Validating backup: $BACKUP_FILE"

# 1. Check file exists and is readable
if [ ! -r "$BACKUP_FILE" ]; then
  echo "❌ Backup file not found or not readable"
  exit 1
fi

# 2. Check file size (should be >1KB)
SIZE=$(stat -f%z "$BACKUP_FILE" 2>/dev/null || stat -c%s "$BACKUP_FILE")
if [ "$SIZE" -lt 1024 ]; then
  echo "❌ Backup file too small ($SIZE bytes)"
  exit 1
fi

# 3. Check SQL header
if ! head -1 "$BACKUP_FILE" | grep -q "PostgreSQL database cluster dump"; then
  echo "❌ Invalid SQL backup header"
  exit 1
fi

# 4. Check for COPY statements (data content)
if ! grep -q "^COPY " "$BACKUP_FILE"; then
  echo "⚠️  Warning: No COPY statements found (empty database?)"
fi

# 5. Test restore in temporary database (optional, slow)
# docker exec -i paws360-patroni1 psql -U postgres -c "CREATE DATABASE test_restore"
# cat "$BACKUP_FILE" | docker exec -i paws360-patroni1 psql -U postgres -d test_restore
# docker exec -i paws360-patroni1 psql -U postgres -c "DROP DATABASE test_restore"

echo "✅ Backup validation passed"
```

### Automated Backup Testing

```bash
# .github/workflows/backup-test.yml (weekly validation)
name: Backup & Recovery Test
on:
  schedule:
    - cron: '0 3 * * 0'  # Every Sunday at 3 AM

jobs:
  test-backup-recovery:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Start environment
        run: make dev-up && make wait-healthy
      - name: Seed test data
        run: make dev-seed
      - name: Create backup
        run: make dev-backup
      - name: Destroy environment
        run: make dev-reset
      - name: Restore from backup
        run: |
          make dev-up && make wait-healthy
          echo "backup_$(date +%Y%m%d)_*.sql" | make dev-restore
      - name: Validate data integrity
        run: |
          make dev-shell-db <<EOF
          SELECT COUNT(*) FROM students;
          SELECT COUNT(*) FROM courses;
          \q
          EOF
```

---

## Troubleshooting

### "Backup file not found"

**Symptoms:**
```
❌ Error: backups/backup_20251127_143022.sql not found
```

**Causes:**
1. Incorrect filename (check spelling)
2. Backup directory missing
3. Insufficient permissions

**Solutions:**
```bash
# List all available backups
ls -lh backups/*.sql

# Check directory permissions
ls -ld backups/

# Recreate backups directory
mkdir -p backups && chmod 755 backups

# Verify backup file permissions
chmod 644 backups/*.sql
```

---

### "psql: FATAL: database does not exist"

**Symptoms:**
```
psql: FATAL: database "paws360" does not exist
```

**Causes:**
1. Patroni cluster not running
2. Database not initialized
3. Connection to wrong node

**Solutions:**
```bash
# Check Patroni cluster status
docker-compose -f infrastructure/compose/docker-compose.patroni.yml ps

# Verify leader node
curl -s http://localhost:8008/patroni | jq '.role'
# Should return: "master"

# Restart Patroni if needed
make dev-restart

# Wait for cluster readiness
make wait-healthy
```

---

### "Restore hangs indefinitely"

**Symptoms:**
- `make dev-restore` runs for >5 minutes without completing
- No error messages displayed

**Causes:**
1. Large backup file (>1 GB)
2. Slow disk I/O
3. PostgreSQL locked by active connections

**Solutions:**
```bash
# 1. Check backup file size
du -h backups/backup_*.sql
# If >1 GB, expect 2-5 minute restore time

# 2. Kill active database connections
docker exec paws360-patroni1 psql -U postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'paws360';"

# 3. Monitor restore progress
docker logs -f paws360-patroni1
# Look for: "CREATE TABLE", "COPY public.X", "ALTER TABLE"

# 4. Increase Docker memory limit (if seeing OOM errors)
# Docker Desktop > Settings > Resources > Memory: 8 GB+
```

---

### "ERROR: must be owner of database"

**Symptoms:**
```
ERROR: must be owner of database paws360 to REASSIGN
ERROR: must be owner of database paws360 to DROP
```

**Status:** ⚠️ **Expected behavior** (non-fatal)

**Explanation:**
- `pg_dumpall` includes ownership changes that fail on restore
- Database is recreated successfully despite errors
- Data integrity is preserved

**Verification:**
```bash
# Confirm database exists and is accessible
docker exec paws360-patroni1 psql -U postgres -l
# Should list: paws360 database

# Verify data restored correctly
docker exec paws360-patroni1 psql -U postgres -d paws360 -c \
  "SELECT COUNT(*) FROM students;"
# Should return: student count from backup
```

---

### "Volume snapshot restore fails"

**Symptoms:**
```
tar: Error is not recoverable: exiting now
❌ Snapshot restoration failed
```

**Causes:**
1. Corrupted tar.gz file
2. Insufficient disk space
3. Docker volume already exists

**Solutions:**
```bash
# 1. Verify snapshot integrity
tar -tzf backups/snapshots/20251127_143022_patroni1.tar.gz > /dev/null
echo $?  # Should return 0 (success)

# 2. Check available disk space
df -h | grep docker
# Ensure >5 GB available

# 3. Manually remove existing volumes
docker volume rm paws360-patroni1-data paws360-patroni2-data paws360-patroni3-data

# 4. Retry restoration
make dev-restore-snapshot
```

---

### "Replication lag after restore"

**Symptoms:**
```
curl http://localhost:8008/patroni | jq '.replication[0].lag'
# Returns: 1024000 (1 MB lag)
```

**Causes:**
- Normal behavior after restore (replicas catching up)
- Slow disk I/O on replica nodes

**Solutions:**
```bash
# 1. Wait for replicas to catch up (1-3 minutes)
watch -n 5 "curl -s http://localhost:8008/patroni | jq '.replication[0].lag'"

# 2. Monitor replication status
docker exec paws360-patroni1 psql -U postgres -c \
  "SELECT client_addr, state, sync_state, replay_lag FROM pg_stat_replication;"

# 3. Force replication sync (if lag persists >5 minutes)
docker exec paws360-patroni2 bash -c "rm -rf /var/lib/postgresql/data/*"
docker-compose restart patroni2
# Patroni will rebuild replica from leader
```

---

## Related Documentation

- [Makefile Development Targets](../reference/makefile-targets.md) - All `dev-*` command reference
- [PostgreSQL Patroni HA Architecture](../architecture/ha-architecture.md) - Cluster design and replication
- [Database Migration Guide](../guides/database-migrations.md) - Schema change procedures
- [Disaster Recovery Plan](../operations/disaster-recovery.md) - Production recovery procedures
- [Monitoring & Alerting](../operations/monitoring.md) - Backup failure detection

---

## Quick Reference Card

```bash
# === Backup Commands ===
make dev-backup                # Create timestamped SQL backup (keeps last 10)
make dev-snapshot              # Create offline volume snapshots (all 3 nodes)

# === Restore Commands ===
make dev-restore               # Interactive restore from SQL backup
make dev-restore-snapshot      # Interactive restore from volume snapshots

# === Verification ===
ls -lht backups/*.sql | head   # List recent SQL backups
ls -lh backups/snapshots/      # List volume snapshots
du -h backups/                 # Check total backup size

# === Manual Backup (Emergency) ===
docker exec paws360-patroni1 pg_dumpall -U postgres > emergency_backup.sql

# === Manual Restore (Emergency) ===
docker exec -i paws360-patroni1 psql -U postgres < emergency_backup.sql
```

**Backup file locations:**
- SQL dumps: `backups/backup_YYYYMMDD_HHMMSS.sql`
- Volume snapshots: `backups/snapshots/YYYYMMDD_HHMMSS_patroniX.tar.gz`

**Auto-backup triggers:**
- `make dev-reset` (before destroying volumes)
- `make dev-migrate` (before schema changes)
- `make test-failover` (before failover test)

**Emergency contacts:**
- Database corruption: Check `docker logs paws360-patroni1`
- Backup failures: Check disk space `df -h`
- Recovery questions: See [Troubleshooting](#troubleshooting)
