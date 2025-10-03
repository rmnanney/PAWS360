-- PAWS360 Database Initialization for Docker
-- Simplified version for development environment

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS paws360;

-- Basic user roles enum
CREATE TYPE user_role AS ENUM ('student', 'faculty', 'staff', 'admin', 'super_admin');

-- FERPA compliance levels
CREATE TYPE ferpa_compliance_level AS ENUM ('public', 'directory', 'restricted', 'confidential');

-- Users table
CREATE TABLE IF NOT EXISTS paws360.users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    role user_role NOT NULL DEFAULT 'student',
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    ferpa_consent_given BOOLEAN DEFAULT false,
    session_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students table
CREATE TABLE IF NOT EXISTS paws360.students (
    student_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES paws360.users(user_id),
    student_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    gpa DECIMAL(3,2) CHECK (gpa >= 0.0 AND gpa <= 4.0),
    total_credits_earned DECIMAL(6,2) DEFAULT 0,
    ferpa_level ferpa_compliance_level DEFAULT 'directory',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Courses table
CREATE TABLE IF NOT EXISTS paws360.courses (
    course_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    credit_hours DECIMAL(3,1) NOT NULL CHECK (credit_hours > 0),
    max_enrollment INTEGER CHECK (max_enrollment > 0),
    current_enrollment INTEGER DEFAULT 0,
    academic_year INTEGER NOT NULL,
    term VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Basic indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON paws360.users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON paws360.users(email);
CREATE INDEX IF NOT EXISTS idx_students_user_id ON paws360.students(user_id);
CREATE INDEX IF NOT EXISTS idx_courses_code ON paws360.courses(course_code);

-- Insert sample admin user
INSERT INTO paws360.users (username, email, password_hash, role, is_active, ferpa_consent_given)
VALUES ('admin', 'admin@paws360.uwm.edu', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj8ZJcKvqXu', 'super_admin', true, true)
ON CONFLICT (username) DO NOTHING;

-- Insert sample student
INSERT INTO paws360.students (user_id, student_number, first_name, last_name, gpa)
SELECT user_id, '123456789', 'John', 'Doe', 3.5
FROM paws360.users WHERE username = 'admin'
ON CONFLICT DO NOTHING;