# Data Model: Transform the Student

## Core Entities

### Student
**Purpose**: Unified student record combining PAWS SIS and Navigate360 data
```sql
CREATE TABLE students (
    id BIGSERIAL PRIMARY KEY,
    student_id VARCHAR(20) UNIQUE NOT NULL,  -- University student ID
    peoplesoft_id VARCHAR(20) UNIQUE,        -- PeopleSoft EMPLID
    navigate360_id VARCHAR(50),              -- Navigate360 external ID
    
    -- Personal Information (FERPA protected)
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    preferred_name VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    
    -- Academic Status
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, GRADUATED, WITHDRAWN
    academic_level VARCHAR(20),                   -- UNDERGRADUATE, GRADUATE, DOCTORAL
    classification VARCHAR(20),                   -- FRESHMAN, SOPHOMORE, JUNIOR, SENIOR
    major VARCHAR(100),
    minor VARCHAR(100),
    advisor_id BIGINT REFERENCES staff(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_sync_at TIMESTAMP WITH TIME ZONE,       -- Last PeopleSoft sync
    
    -- Privacy Controls
    ferpa_hold BOOLEAN DEFAULT FALSE,
    directory_hold BOOLEAN DEFAULT FALSE,
    data_consent TIMESTAMP WITH TIME ZONE        -- Consent for Navigate360 features
);
```

**Validation Rules**:
- `student_id` must match university format (regex validation)
- `email` must be valid university email domain
- `status` transitions logged for audit trail
- FERPA hold prevents data sharing with Navigate360

**State Transitions**:
- ACTIVE → INACTIVE (academic suspension)
- ACTIVE → GRADUATED (degree completion)
- ACTIVE → WITHDRAWN (voluntary or involuntary withdrawal)
- INACTIVE → ACTIVE (reinstatement)

### Course
**Purpose**: Course catalog and section information
```sql
CREATE TABLE courses (
    id BIGSERIAL PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE NOT NULL,     -- e.g., "CS101"
    course_title VARCHAR(200) NOT NULL,
    course_description TEXT,
    credit_hours INTEGER NOT NULL DEFAULT 3,
    department VARCHAR(100) NOT NULL,
    prerequisites TEXT,                          -- JSON array of prerequisite course codes
    
    -- Academic Term
    term VARCHAR(20) NOT NULL,                   -- e.g., "FALL2024"
    academic_year INTEGER NOT NULL,
    
    -- Schedule Information
    section_number VARCHAR(10) NOT NULL,
    instructor_id BIGINT REFERENCES staff(id),
    meeting_days VARCHAR(10),                    -- e.g., "MWF"
    meeting_time_start TIME,
    meeting_time_end TIME,
    location VARCHAR(100),
    capacity INTEGER,
    enrolled_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(course_code, term, section_number)
);
```

**Validation Rules**:
- `course_code` follows department standards
- `capacity` must be positive integer
- `enrolled_count` cannot exceed `capacity`
- `meeting_time_start` must be before `meeting_time_end`

### Enrollment
**Purpose**: Student course registration and academic progress
```sql
CREATE TABLE enrollments (
    id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(id),
    course_id BIGINT NOT NULL REFERENCES courses(id),
    
    -- Registration Status
    status VARCHAR(20) NOT NULL DEFAULT 'ENROLLED', -- ENROLLED, DROPPED, WITHDRAWN
    registration_date DATE NOT NULL,
    drop_date DATE,
    
    -- Academic Performance
    midterm_grade VARCHAR(5),                    -- Letter grade or NULL
    final_grade VARCHAR(5),                      -- Letter grade or NULL
    grade_points DECIMAL(3,2),                   -- GPA calculation
    attempted_credits INTEGER NOT NULL,
    earned_credits INTEGER DEFAULT 0,
    
    -- Attendance & Engagement (Navigate360)
    last_attendance_date DATE,
    absence_count INTEGER DEFAULT 0,
    tardiness_count INTEGER DEFAULT 0,
    engagement_score DECIMAL(3,2),               -- 0.00 - 4.00 scale
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(student_id, course_id)
);
```

**Validation Rules**:
- `final_grade` must be valid institutional grade (A, B, C, D, F, W, I, P, NP)
- `grade_points` calculated based on institutional grading scale
- `earned_credits` equals `attempted_credits` for passing grades
- `engagement_score` between 0.00 and 4.00

### Grade
**Purpose**: Individual assignment and exam grades
```sql
CREATE TABLE grades (
    id BIGSERIAL PRIMARY KEY,
    enrollment_id BIGINT NOT NULL REFERENCES enrollments(id),
    assignment_type VARCHAR(50) NOT NULL,        -- HOMEWORK, QUIZ, EXAM, PROJECT, PARTICIPATION
    assignment_name VARCHAR(200) NOT NULL,
    
    -- Grade Information
    points_earned DECIMAL(6,2),
    points_possible DECIMAL(6,2) NOT NULL,
    percentage DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN points_possible > 0 
        THEN (points_earned / points_possible) * 100 
        ELSE NULL END
    ) STORED,
    letter_grade VARCHAR(5),
    
    -- Metadata
    due_date TIMESTAMP WITH TIME ZONE,
    submitted_date TIMESTAMP WITH TIME ZONE,
    graded_date TIMESTAMP WITH TIME ZONE,
    feedback TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Validation Rules**:
- `points_earned` cannot exceed `points_possible`
- `points_possible` must be positive
- `submitted_date` should not be before `due_date` (late submission tracking)
- `graded_date` should not be before `submitted_date`

### Alert
**Purpose**: Academic and behavioral alerts from Navigate360
```sql
CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(id),
    created_by_id BIGINT NOT NULL REFERENCES staff(id),
    
    -- Alert Classification
    alert_type VARCHAR(50) NOT NULL,             -- ACADEMIC, ATTENDANCE, FINANCIAL, PERSONAL, TECHNICAL
    severity VARCHAR(20) NOT NULL DEFAULT 'MEDIUM', -- LOW, MEDIUM, HIGH, CRITICAL
    category VARCHAR(100),                       -- More specific categorization
    
    -- Alert Content
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    recommended_actions TEXT,
    
    -- Status & Resolution
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',  -- OPEN, IN_PROGRESS, RESOLVED, DISMISSED
    assigned_to_id BIGINT REFERENCES staff(id),
    resolution_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    parent_alert_id BIGINT REFERENCES alerts(id),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Validation Rules**:
- `severity` must be valid level
- `status` transitions logged for workflow tracking
- `resolved_at` required when `status` = 'RESOLVED'
- `assigned_to_id` required when `status` = 'IN_PROGRESS'

### Communication
**Purpose**: Messages, notifications, and communication logs
```sql
CREATE TABLE communications (
    id BIGSERIAL PRIMARY KEY,
    
    -- Participants
    sender_id BIGINT REFERENCES users(id),       -- Can be student or staff
    recipient_id BIGINT NOT NULL REFERENCES users(id),
    
    -- Message Content
    communication_type VARCHAR(20) NOT NULL,     -- MESSAGE, NOTIFICATION, ALERT, APPOINTMENT
    subject VARCHAR(200),
    body TEXT NOT NULL,
    priority VARCHAR(10) DEFAULT 'NORMAL',       -- LOW, NORMAL, HIGH, URGENT
    
    -- Delivery & Status
    delivery_method VARCHAR(20) DEFAULT 'IN_APP', -- IN_APP, EMAIL, SMS, PUSH
    status VARCHAR(20) DEFAULT 'SENT',           -- SENT, DELIVERED, READ, FAILED
    read_at TIMESTAMP WITH TIME ZONE,
    delivery_attempts INTEGER DEFAULT 0,
    
    -- Context & Threading
    thread_id VARCHAR(50),                       -- Groups related messages
    reference_type VARCHAR(50),                  -- ALERT, ENROLLMENT, APPOINTMENT
    reference_id BIGINT,                         -- ID of referenced entity
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Validation Rules**:
- `delivery_method` must match user preferences
- `read_at` cannot be before message creation
- `priority` affects delivery and notification behavior

### Staff
**Purpose**: Faculty, advisors, and administrative staff with role-based access control
```sql
CREATE TABLE staff (
    id BIGSERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    peoplesoft_id VARCHAR(20) UNIQUE,
    
    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    office_location VARCHAR(100),
    
    -- Role & Department
    job_title VARCHAR(200),
    department VARCHAR(100) NOT NULL,
    role_type VARCHAR(50) NOT NULL,              -- FACULTY, ADVISOR, ADMIN, SUPPORT
    staff_role VARCHAR(20) NOT NULL DEFAULT 'ADVISOR', -- SUPER_ADMIN, DEAN, ADVISOR, REGISTRAR, FINANCIAL_AID
    
    -- Access Control
    is_active BOOLEAN DEFAULT TRUE,
    can_access_ferpa BOOLEAN DEFAULT FALSE,
    can_create_alerts BOOLEAN DEFAULT TRUE,
    can_view_analytics BOOLEAN DEFAULT FALSE,
    admin_dashboard_access BOOLEAN DEFAULT FALSE, -- Access to AdminLTE dashboard
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE admin_permissions (
    id BIGSERIAL PRIMARY KEY,
    permission_code VARCHAR(50) UNIQUE NOT NULL, -- STUDENT_READ, STUDENT_WRITE, etc.
    permission_name VARCHAR(200) NOT NULL,
    permission_description TEXT,
    category VARCHAR(50) NOT NULL,               -- STUDENT, COURSE, SYSTEM, AUDIT
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE staff_permissions (
    id BIGSERIAL PRIMARY KEY,
    staff_id BIGINT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES admin_permissions(id),
    
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by_id BIGINT REFERENCES staff(id),
    
    UNIQUE(staff_id, permission_id)
);

-- Insert default permissions
INSERT INTO admin_permissions (permission_code, permission_name, permission_description, category) VALUES
-- Student Management
('STUDENT_READ', 'View Student Data', 'View student profiles, grades, and academic history', 'STUDENT'),
('STUDENT_WRITE', 'Modify Student Data', 'Edit student information and academic records', 'STUDENT'),
('STUDENT_DELETE', 'Delete Student Records', 'Remove students from system (archive)', 'STUDENT'),

-- Course Management  
('COURSE_READ', 'View Course Data', 'View course catalog, sections, and enrollments', 'COURSE'),
('COURSE_WRITE', 'Modify Course Data', 'Edit courses, sections, and manage enrollments', 'COURSE'),
('COURSE_DELETE', 'Delete Course Data', 'Remove courses and sections', 'COURSE'),

-- Transcript & Academic Records
('TRANSCRIPT_READ', 'View Transcripts', 'Access student academic transcripts', 'TRANSCRIPT'),
('TRANSCRIPT_WRITE', 'Modify Transcripts', 'Edit grades and academic history', 'TRANSCRIPT'),

-- Communication & Alerts
('COMMUNICATION_READ', 'View Communications', 'Read messages and notifications', 'COMMUNICATION'),
('COMMUNICATION_WRITE', 'Send Communications', 'Create messages and alerts', 'COMMUNICATION'),
('ALERT_MANAGE', 'Manage Alerts', 'Create, assign, and resolve academic alerts', 'COMMUNICATION'),

-- System Administration
('SYSTEM_CONFIG', 'System Configuration', 'Access system settings and configuration', 'SYSTEM'),
('USER_MANAGE', 'User Management', 'Manage staff accounts and permissions', 'SYSTEM'),
('AUDIT_LOGS', 'Audit Log Access', 'View system audit logs and reports', 'AUDIT'),
('ANALYTICS_VIEW', 'Analytics Dashboard', 'Access enrollment and performance analytics', 'ANALYTICS');

-- Create role-based permission templates
CREATE TABLE staff_role_permissions (
    id BIGSERIAL PRIMARY KEY,
    staff_role VARCHAR(20) NOT NULL,
    permission_code VARCHAR(50) NOT NULL REFERENCES admin_permissions(permission_code),
    
    UNIQUE(staff_role, permission_code)
);

-- Define default permissions for each role
INSERT INTO staff_role_permissions (staff_role, permission_code) VALUES
-- SUPER_ADMIN has all permissions
('SUPER_ADMIN', 'STUDENT_READ'), ('SUPER_ADMIN', 'STUDENT_WRITE'), ('SUPER_ADMIN', 'STUDENT_DELETE'),
('SUPER_ADMIN', 'COURSE_READ'), ('SUPER_ADMIN', 'COURSE_WRITE'), ('SUPER_ADMIN', 'COURSE_DELETE'),
('SUPER_ADMIN', 'TRANSCRIPT_READ'), ('SUPER_ADMIN', 'TRANSCRIPT_WRITE'),
('SUPER_ADMIN', 'COMMUNICATION_READ'), ('SUPER_ADMIN', 'COMMUNICATION_WRITE'), ('SUPER_ADMIN', 'ALERT_MANAGE'),
('SUPER_ADMIN', 'SYSTEM_CONFIG'), ('SUPER_ADMIN', 'USER_MANAGE'), ('SUPER_ADMIN', 'AUDIT_LOGS'), ('SUPER_ADMIN', 'ANALYTICS_VIEW'),

-- DEAN has college-level administration
('DEAN', 'STUDENT_READ'), ('DEAN', 'STUDENT_WRITE'),
('DEAN', 'COURSE_READ'), ('DEAN', 'COURSE_WRITE'),
('DEAN', 'TRANSCRIPT_READ'),
('DEAN', 'COMMUNICATION_READ'), ('DEAN', 'COMMUNICATION_WRITE'), ('DEAN', 'ALERT_MANAGE'),
('DEAN', 'ANALYTICS_VIEW'),

-- REGISTRAR has academic record management
('REGISTRAR', 'STUDENT_READ'), ('REGISTRAR', 'STUDENT_WRITE'),
('REGISTRAR', 'COURSE_READ'), ('REGISTRAR', 'COURSE_WRITE'),
('REGISTRAR', 'TRANSCRIPT_READ'), ('REGISTRAR', 'TRANSCRIPT_WRITE'),
('REGISTRAR', 'COMMUNICATION_READ'),

-- ADVISOR has student advising access
('ADVISOR', 'STUDENT_READ'),
('ADVISOR', 'COURSE_READ'),
('ADVISOR', 'TRANSCRIPT_READ'),
('ADVISOR', 'COMMUNICATION_READ'), ('ADVISOR', 'COMMUNICATION_WRITE'), ('ADVISOR', 'ALERT_MANAGE'),

-- FINANCIAL_AID has financial assistance access
('FINANCIAL_AID', 'STUDENT_READ'),
('FINANCIAL_AID', 'COMMUNICATION_READ'), ('FINANCIAL_AID', 'COMMUNICATION_WRITE');
```

**Validation Rules**:
- `staff_role` must be one of predefined roles
- `admin_dashboard_access` requires at least one admin permission
- Permission changes logged for audit trail
- FERPA access requires additional training verification

### Authentication
**Purpose**: User sessions and authentication state with role-based access
```sql
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    session_id VARCHAR(128) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id),
    user_type VARCHAR(20) NOT NULL,              -- STUDENT, STAFF
    
    -- Session Management
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    
    -- Access Context
    access_type VARCHAR(20) DEFAULT 'STUDENT_PORTAL', -- STUDENT_PORTAL, ADMIN_DASHBOARD
    staff_role VARCHAR(20),                      -- Cached role for staff sessions
    permissions JSONB,                           -- Cached permissions for performance
    
    -- Security
    is_active BOOLEAN DEFAULT TRUE,
    logout_reason VARCHAR(50),                   -- MANUAL, TIMEOUT, ADMIN_REVOKE, ROLE_CHANGED
    
    -- SAML Integration
    saml_session_id VARCHAR(200),
    saml_name_id VARCHAR(200),
    saml_attributes JSONB
);

CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    operation VARCHAR(20) NOT NULL,              -- INSERT, UPDATE, DELETE
    
    -- User Context
    user_id BIGINT REFERENCES users(id),
    user_type VARCHAR(20),
    session_id VARCHAR(128),
    staff_role VARCHAR(20),
    
    -- Change Tracking
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    
    -- Context
    request_ip INET,
    request_path VARCHAR(500),
    request_method VARCHAR(10),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Admin Session Management**:
- Staff sessions cache role and permissions for performance
- Admin dashboard access tracked separately from student portal
- Role changes invalidate existing sessions
- Audit logging includes role context for compliance

## Relationships & Constraints

### Primary Relationships
- Student → Staff (advisor relationship)
- Staff → AdminPermission (many-to-many via staff_permissions)
- Staff → StaffRolePermissions (role-based permission templates)
- Student → Enrollment (one-to-many)
- Enrollment → Course (many-to-one)
- Enrollment → Grade (one-to-many)
- Student → Alert (one-to-many)
- Staff → Alert (created_by, assigned_to)
- Communication → Users (sender/recipient polymorphic)
- UserSession → Staff (role and permission caching)
- AuditLog → Users (comprehensive change tracking with role context)

### Database Indexes
```sql
-- Performance indexes
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_enrollments_student_term ON enrollments(student_id, term);
CREATE INDEX idx_alerts_student_status ON alerts(student_id, status);
CREATE INDEX idx_communications_recipient_unread ON communications(recipient_id, read_at) WHERE read_at IS NULL;

-- Admin system indexes
CREATE INDEX idx_staff_role ON staff(staff_role, is_active) WHERE is_active = TRUE;
CREATE INDEX idx_staff_permissions_lookup ON staff_permissions(staff_id);
CREATE INDEX idx_admin_permissions_category ON admin_permissions(category);
CREATE INDEX idx_user_sessions_staff_role ON user_sessions(user_id, staff_role) WHERE user_type = 'STAFF';
CREATE INDEX idx_audit_log_staff_context ON audit_log(user_id, staff_role, created_at);

-- FERPA compliance indexes
CREATE INDEX idx_students_ferpa_hold ON students(ferpa_hold) WHERE ferpa_hold = TRUE;
CREATE INDEX idx_audit_log_student_data ON audit_log(table_name, record_id) WHERE table_name = 'students';
CREATE INDEX idx_staff_ferpa_access ON staff(can_access_ferpa, is_active) WHERE can_access_ferpa = TRUE AND is_active = TRUE;
```

### Data Integrity Rules
- Cascade delete: Student deletion cascades to enrollments, grades, alerts
- Soft delete: Staff records marked inactive rather than deleted
- Permission cascade: Staff role changes update staff_permissions automatically via triggers
- Audit logging: All changes to student data and admin actions logged for FERPA compliance
- Encryption: PII fields encrypted at application layer using AES-256
- Role validation: Staff roles must exist in staff_role_permissions template
- Session invalidation: Role changes invalidate existing admin sessions

## Data Synchronization

### PeopleSoft Integration Points
- Student demographic data (daily sync)
- Course catalog and sections (term-based sync)
- Enrollment status (real-time)
- Final grades (real-time)

### Navigate360 Integration Points
- Alert creation and updates (real-time)
- Communication logs (real-time)
- Engagement metrics (daily aggregation)
- Attendance tracking (real-time)

### Conflict Resolution
- PeopleSoft is source of truth for academic records
- Navigate360 is source of truth for engagement data
- Last-write-wins for non-critical updates
- Manual resolution required for grade conflicts