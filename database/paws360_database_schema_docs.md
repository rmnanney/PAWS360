# PAWS360 Database Schema Documentation

## 📊 Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     users       │       │   students      │       │  enrollments    │
│─────────────────│       │─────────────────│       │─────────────────│
│ user_id (PK)    │◄──────┤ user_id (FK)    │       │ enrollment_id   │
│ username        │       │ student_id (PK) │       │ student_id (FK) │
│ email           │       │ student_number  │       │ section_id (FK) │
│ password_hash   │       │ first_name      │       │ enrollment_status│
│ role            │       │ last_name       │       │ grade           │
│ is_active       │       │ date_of_birth   │       │ grade_points    │
│ last_login_at   │       │ gender          │       │ credits_earned  │
│ ...             │       │ gpa             │       │ ...             │
└─────────────────┘       └─────────────────┘       └─────────────────┘
         │                           │                           │
         │                           │                           │
         ▼                           ▼                           ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   sessions      │       │   courses       │       │course_sections  │
│─────────────────│       │─────────────────│       │─────────────────│
│ session_id (PK) │       │ course_id (PK)  │◄──────┤ section_id (PK) │
│ user_id (FK)    │       │ course_code     │       │ course_id (FK)  │
│ session_token   │       │ course_name     │       │ section_number  │
│ expires_at      │       │ credit_hours    │       │ instructor_id   │
│ ...             │       │ max_enrollment  │       │ days_of_week    │
└─────────────────┘       └─────────────────┘       └─────────────────┘
                                                                 │
                                                                 │
                                                                 ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│dashboard_widgets│       │ notifications   │       │  audit_log     │
│─────────────────│       │─────────────────│       │─────────────────│
│ widget_id (PK)  │       │ notification_id │       │ audit_id (PK)   │
│ user_id (FK)    │       │ user_id (FK)    │       │ table_name      │
│ widget_type     │       │ title           │       │ record_id       │
│ position_x/y    │       │ message         │       │ operation       │
│ ...             │       │ is_read         │       │ old_values      │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

## 📋 Data Dictionary

### Core Tables

#### `users` - User Authentication & Authorization
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `user_id` | UUID | PK, Default: uuid_generate_v4() | Unique user identifier |
| `username` | VARCHAR(50) | UNIQUE, NOT NULL | Login username |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | User email address |
| `password_hash` | VARCHAR(255) | | Bcrypt hashed password |
| `role` | user_role ENUM | NOT NULL, Default: 'student' | User role (student, faculty, staff, admin, super_admin) |
| `is_active` | BOOLEAN | NOT NULL, Default: true | Account active status |
| `last_login_at` | TIMESTAMP | | Last login timestamp |
| `failed_login_attempts` | INTEGER | Default: 0 | Failed login counter |
| `account_locked_until` | TIMESTAMP | | Account lock expiration |
| `ferpa_consent_given` | BOOLEAN | Default: false | FERPA consent status |
| `session_token` | VARCHAR(255) | | Current session token |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record update time |

#### `students` - Student Information (FERPA Protected)
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `student_id` | UUID | PK, Default: uuid_generate_v4() | Unique student identifier |
| `user_id` | UUID | FK → users.user_id | Associated user account |
| `student_number` | VARCHAR(20) | UNIQUE, NOT NULL | Student ID number |
| `first_name` | VARCHAR(100) | NOT NULL | Student first name |
| `last_name` | VARCHAR(100) | NOT NULL | Student last name |
| `date_of_birth` | DATE | | Student date of birth |
| `gender` | CHAR(1) | Check: M, F, O | Student gender |
| `ethnicity` | VARCHAR(50) | | Student ethnicity |
| `enrollment_year` | INTEGER | | Year of first enrollment |
| `gpa` | DECIMAL(3,2) | Check: 0.0-4.0 | Student GPA |
| `total_credits_earned` | DECIMAL(6,2) | Default: 0 | Total earned credits |
| `directory_info_restricted` | BOOLEAN | Default: false | FERPA directory restriction |
| `ferpa_level` | ferpa_compliance_level | Default: 'directory' | FERPA compliance level |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record update time |

#### `courses` - Course Catalog
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `course_id` | UUID | PK, Default: uuid_generate_v4() | Unique course identifier |
| `course_code` | VARCHAR(20) | UNIQUE, NOT NULL | Course code (e.g., CS101) |
| `course_name` | VARCHAR(200) | NOT NULL | Full course name |
| `department_code` | VARCHAR(10) | NOT NULL | Department code (e.g., CS, MATH) |
| `credit_hours` | DECIMAL(3,1) | NOT NULL, Check: > 0 | Course credit hours |
| `max_enrollment` | INTEGER | Check: > 0 | Maximum enrollment capacity |
| `current_enrollment` | INTEGER | Default: 0 | Current enrollment count |
| `academic_year` | INTEGER | NOT NULL | Academic year |
| `term` | VARCHAR(20) | NOT NULL | Academic term |
| `delivery_method` | delivery_method | Default: 'in_person' | Course delivery method |
| `is_active` | BOOLEAN | Default: true | Course active status |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record update time |

#### `course_sections` - Course Instances
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `section_id` | UUID | PK, Default: uuid_generate_v4() | Unique section identifier |
| `course_id` | UUID | FK → courses.course_id | Parent course |
| `section_number` | VARCHAR(10) | NOT NULL | Section number (e.g., 001, 002) |
| `instructor_id` | UUID | FK → users.user_id | Section instructor |
| `days_of_week` | VARCHAR(20) | | Meeting days (MWF, TR, etc.) |
| `start_time` | TIME | | Class start time |
| `end_time` | TIME | | Class end time |
| `location` | VARCHAR(100) | | Class location |
| `max_enrollment` | INTEGER | Check: > 0 | Section capacity |
| `current_enrollment` | INTEGER | Default: 0 | Current section enrollment |
| `is_active` | BOOLEAN | Default: true | Section active status |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record update time |

#### `enrollments` - Student-Course Relationships
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `enrollment_id` | UUID | PK, Default: uuid_generate_v4() | Unique enrollment identifier |
| `student_id` | UUID | FK → students.student_id | Enrolled student |
| `section_id` | UUID | FK → course_sections.section_id | Course section |
| `enrollment_status` | enrollment_status | Default: 'enrolled' | Enrollment status |
| `grade` | VARCHAR(5) | | Letter grade |
| `grade_points` | DECIMAL(3,2) | | Grade points (4.0, 3.0, etc.) |
| `credits_earned` | DECIMAL(3,1) | | Credits earned for course |
| `enrollment_date` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Enrollment date |
| `dropped_date` | TIMESTAMP | | Date dropped (if applicable) |
| `waitlist_position` | INTEGER | | Waitlist position |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record update time |

### AdminLTE Integration Tables

#### `sessions` - User Session Management
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `session_id` | UUID | PK, Default: uuid_generate_v4() | Unique session identifier |
| `user_id` | UUID | FK → users.user_id | Session user |
| `session_token` | VARCHAR(255) | UNIQUE, NOT NULL | Session token |
| `ip_address` | INET | | Client IP address |
| `user_agent` | TEXT | | Client user agent |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Session creation time |
| `expires_at` | TIMESTAMP | NOT NULL | Session expiration time |
| `is_active` | BOOLEAN | Default: true | Session active status |

#### `dashboard_widgets` - Dashboard Customization
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `widget_id` | UUID | PK, Default: uuid_generate_v4() | Unique widget identifier |
| `user_id` | UUID | FK → users.user_id | Widget owner |
| `widget_type` | VARCHAR(50) | NOT NULL | Widget type (chart, table, etc.) |
| `widget_config` | JSONB | | Widget configuration |
| `position_x` | INTEGER | | Widget X position |
| `position_y` | INTEGER | | Widget Y position |
| `width` | INTEGER | | Widget width |
| `height` | INTEGER | | Widget height |
| `is_visible` | BOOLEAN | Default: true | Widget visibility |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record creation time |
| `updated_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Record update time |

#### `notifications` - User Notifications
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `notification_id` | UUID | PK, Default: uuid_generate_v4() | Unique notification identifier |
| `user_id` | UUID | FK → users.user_id | Notification recipient |
| `title` | VARCHAR(200) | NOT NULL | Notification title |
| `message` | TEXT | | Notification message |
| `notification_type` | VARCHAR(50) | | Notification type |
| `is_read` | BOOLEAN | Default: false | Read status |
| `priority` | VARCHAR(20) | Default: 'normal' | Notification priority |
| `created_at` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Creation time |
| `read_at` | TIMESTAMP | | Read timestamp |

### Audit & Compliance

#### `audit.audit_log` - FERPA Compliance Audit Trail
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `audit_id` | UUID | PK, Default: uuid_generate_v4() | Unique audit entry identifier |
| `table_name` | VARCHAR(100) | NOT NULL | Audited table name |
| `record_id` | UUID | NOT NULL | Audited record identifier |
| `operation` | VARCHAR(10) | Check: INSERT, UPDATE, DELETE | Database operation |
| `old_values` | JSONB | | Previous record values |
| `new_values` | JSONB | | New record values |
| `user_id` | UUID | FK → users.user_id | User who performed operation |
| `ip_address` | INET | | Client IP address |
| `user_agent` | TEXT | | Client user agent |
| `timestamp` | TIMESTAMP | Default: CURRENT_TIMESTAMP | Audit timestamp |

## 🔗 Relationships

### Primary Relationships
- **users** → **students** (1:1, user can be a student)
- **users** → **sessions** (1:many, user can have multiple sessions)
- **users** → **dashboard_widgets** (1:many)
- **users** → **notifications** (1:many)
- **courses** → **course_sections** (1:many)
- **students** → **enrollments** (1:many)
- **course_sections** → **enrollments** (1:many)
- **users** → **course_sections** (1:many, as instructors)

### Foreign Key Constraints
- All foreign keys have CASCADE delete behavior for referential integrity
- Unique constraints prevent duplicate enrollments
- Check constraints validate data ranges and formats

## 📊 Views

### `student_enrollment_summary`
Provides a comprehensive view of student enrollment data including:
- Student information
- Current enrollment count
- Credit load
- Academic standing

### `course_enrollment_summary`
Shows course utilization metrics:
- Enrollment percentages
- Section counts
- Capacity vs. current enrollment

### `dashboard_metrics`
Pre-calculated metrics for AdminLTE dashboard:
- Total students
- Total courses
- Total enrollments
- Average GPA

## 🔐 Security & Compliance

### FERPA Compliance
- Row-level security policies restrict data access
- Audit logging captures all data access
- Data masking for sensitive information
- Consent tracking for FERPA compliance

### Data Protection
- PII fields encrypted where appropriate
- Access logging for compliance reporting
- Data retention policies implemented
- Role-based access control

## ⚡ Performance Optimizations

### Indexing Strategy
- Primary keys automatically indexed
- Foreign keys indexed for join performance
- Composite indexes for common query patterns
- Partial indexes for active records
- Full-text search indexes where applicable

### Query Optimization
- Views pre-calculate common aggregations
- Materialized views for complex reports
- Partitioning strategy for large tables
- Connection pooling configuration

## 📈 Scalability Considerations

### Current Scale
- 25,000+ students supported
- 1,000+ courses per term
- 100,000+ enrollments
- Multi-year historical data

### Future Growth
- Partitioning strategy for enrollment history
- Read replicas for reporting queries
- Caching layer for dashboard metrics
- Horizontal scaling capabilities</content>
<parameter name="filePath">/home/ryan/repos/PAWS360ProjectPlan/paws360_database_schema_docs.md