# PAWS360 Database Package 📊

**Version:** 1.0.0
**Date:** September 21, 2025
**Compatible with:** PAWS360 Admin API v1.0

---

## 📦 Package Contents

This zip file contains the complete PostgreSQL database schema and data for the PAWS360 Student Success Platform.

### Files Included:

| File | Description | Size |
|------|-------------|------|
| `paws360_database_ddl.sql` | Complete database schema (tables, indexes, triggers, RLS) | ~620 lines |
| `paws360_seed_data.sql` | Sample data (25,000+ students, courses, users) | ~390 lines |
| `paws360_database_schema_docs.md` | Entity relationships and data dictionary | ~273 lines |
| `paws360_migration_scripts.md` | Database migration and upgrade procedures | |
| `paws360_database_testing.md` | Database testing procedures and sample queries | |
| `paws360_deployment_operations.md` | Production deployment and maintenance | |
| `paws360_performance_tuning.md` | Performance optimization guides | |
| `paws360_backup_recovery.md` | Backup and disaster recovery procedures | |
| `paws360_project_summary.md` | Database project overview and architecture | |

---

## 🚀 Quick Start

### Prerequisites
- **PostgreSQL 13+** installed and running
- **Admin privileges** on PostgreSQL instance
- **psql client** or database GUI tool

### 1. Create Database
```bash
# Connect as postgres superuser
sudo -u postgres psql

# Create database and user
CREATE USER paws360_admin WITH PASSWORD 'your_secure_password';
CREATE DATABASE paws360 OWNER paws360_admin;
GRANT ALL PRIVILEGES ON DATABASE paws360 TO paws360_admin;
\q
```

### 2. Run Schema
```bash
# Connect to the database
psql -U paws360_admin -d paws360 -f paws360_database_ddl.sql
```

### 3. Load Sample Data (Optional)
```bash
# Load sample data (takes ~2-3 minutes)
psql -U paws360_admin -d paws360 -f paws360_seed_data.sql
```

### 4. Verify Installation
```bash
# Connect and check tables
psql -U paws360_admin -d paws360 -c "\dt paws360.*"
psql -U paws360_admin -d paws360 -c "SELECT COUNT(*) FROM paws360.students;"
```

---

## 🏗️ Database Architecture

### Core Tables
- **`users`** - Authentication and authorization (AdminLTE integration)
- **`students`** - Student personal/academic data (FERPA protected)
- **`courses`** - Course catalog and metadata
- **`course_sections`** - Specific course instances with scheduling
- **`enrollments`** - Student-course relationships
- **`sessions`** - AdminLTE session management
- **`notifications`** - User notifications
- **`dashboard_widgets`** - AdminLTE dashboard customization

### Security Features
- **Row Level Security (RLS)** - FERPA compliance
- **Audit logging** - Complete change tracking
- **Role-based access** - Student, Faculty, Staff, Admin roles
- **PII protection** - Sensitive data encryption ready

### Performance Features
- **Optimized indexes** - Fast queries on large datasets
- **Materialized views** - Pre-computed dashboard metrics
- **Partitioning ready** - For very large datasets
- **Connection pooling** - High concurrency support

---

## 🔧 Configuration

### Environment Variables
```bash
# Database connection
DB_HOST=localhost
DB_PORT=5432
DB_NAME=paws360
DB_USER=paws360_admin
DB_PASSWORD=your_secure_password

# Application settings
DB_SCHEMA=paws360
DB_MAX_CONNECTIONS=100
DB_STATEMENT_TIMEOUT=30000
```

### Connection String
```
postgresql://paws360_admin:password@localhost:5432/paws360?schema=paws360
```

---

## 📊 Sample Data Overview

The seed data includes realistic UW-Milwaukee enrollment patterns:

- **25,000+ students** with diverse demographics
- **500+ courses** across multiple departments
- **50 faculty members** and staff
- **Realistic enrollment patterns** (GPA distribution, course loads)
- **Complete user accounts** with authentication
- **Sample notifications and dashboard data**

### Default Admin Account
- **Username:** admin
- **Email:** admin@paws360.uwm.edu
- **Password:** admin123 (hashed in seed data)
- **Role:** super_admin

---

## 🧪 Testing the Database

### Basic Health Check
```sql
-- Check table counts
SELECT schemaname, tablename, n_tup_ins AS rows
FROM pg_stat_user_tables
WHERE schemaname = 'paws360'
ORDER BY n_tup_ins DESC;

-- Check indexes
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'paws360'
ORDER BY tablename, indexname;
```

### API-Compatible Queries
```sql
-- Get student dashboard data
SELECT s.student_id, s.first_name, s.last_name, s.gpa,
       COUNT(e.enrollment_id) as current_courses
FROM paws360.students s
LEFT JOIN paws360.enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_status = 'enrolled'
GROUP BY s.student_id, s.first_name, s.last_name, s.gpa;

-- Get course enrollment summary
SELECT c.course_code, c.course_name,
       c.current_enrollment, c.max_enrollment
FROM paws360.courses c
WHERE c.is_active = true;
```

---

## 🔄 Migrations & Updates

### Flyway Integration
The schema is designed for Flyway migrations:

```sql
-- Migration file naming: V1.0.0__initial_schema.sql
-- Place in: src/main/resources/db/migration/
```

### Backup Before Changes
```bash
# Create backup
pg_dump -U paws360_admin -d paws360 > paws360_backup_$(date +%Y%m%d).sql

# Restore if needed
psql -U paws360_admin -d paws360 < paws360_backup_20250921.sql
```

---

## 🚨 Production Considerations

### Security
- [ ] Change default passwords
- [ ] Configure SSL connections
- [ ] Set up proper firewall rules
- [ ] Enable audit logging
- [ ] Configure backup encryption

### Performance
- [ ] Adjust PostgreSQL configuration for your hardware
- [ ] Set up connection pooling (PgBouncer)
- [ ] Configure monitoring (pg_stat_statements)
- [ ] Set up automated backups
- [ ] Plan for scaling (read replicas)

### Monitoring
- [ ] Set up database monitoring
- [ ] Configure alert thresholds
- [ ] Monitor slow queries
- [ ] Track disk usage
- [ ] Set up log rotation

---

## 🆘 Troubleshooting

### Common Issues

**Connection Refused**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check listening ports
sudo netstat -tlnp | grep 5432
```

**Permission Denied**
```bash
# Grant proper permissions
GRANT ALL PRIVILEGES ON DATABASE paws360 TO paws360_admin;
GRANT ALL ON SCHEMA paws360 TO paws360_admin;
```

**Slow Queries**
```sql
-- Find slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

---

## 📞 Support

### Documentation
- `paws360_database_schema_docs.md` - Complete data dictionary
- `paws360_deployment_operations.md` - Production deployment
- `paws360_performance_tuning.md` - Optimization guides

### API Integration
This database is designed to work with the PAWS360 Admin API:
- **Postman Collection:** `PAWS360_Admin_API.postman_collection.json`
- **API Documentation:** Available in Postman collection
- **Authentication:** JWT Bearer tokens with SAML2 integration

---

## 📈 Database Metrics

| Metric | Development | Production Expected |
|--------|-------------|---------------------|
| **Students** | 25,000+ | 50,000+ |
| **Courses** | 500+ | 2,000+ |
| **Enrollments** | 100,000+ | 500,000+ |
| **Daily Queries** | 1,000+ | 100,000+ |
| **Response Time** | <100ms | <50ms |
| **Uptime** | 99.9% | 99.99% |

---

## 🎯 Next Steps

1. **Install PostgreSQL** if not already installed
2. **Run the DDL script** to create schema
3. **Load seed data** for testing
4. **Import Postman collection** for API testing
5. **Configure your application** to connect
6. **Test basic CRUD operations** via API

---

*This database package provides everything needed to run the PAWS360 Student Success Platform locally or in production.*