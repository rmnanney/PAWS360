-- Create the paws360 schema for the Courses table
CREATE SCHEMA IF NOT EXISTS paws360;
-- Ensure the CI DB user uses the paws360 schema by default
-- If the role exists (Postgres user created by Docker env), set its search_path
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'paws360') THEN
        EXECUTE 'ALTER ROLE paws360 SET search_path = paws360, public';
    END IF;
END
$$;

-- Simple test schema for CI/CD testing
-- This creates minimal tables needed for the application to start

-- Create a simple users table for testing under the `paws360` schema
CREATE TABLE IF NOT EXISTS paws360.users (
    user_id SERIAL PRIMARY KEY,
    firstname VARCHAR(100) NOT NULL,
    middlename VARCHAR(100),
    lastname VARCHAR(30) NOT NULL,
    dob DATE NOT NULL,
    ssn VARCHAR(9),
    ethnicity VARCHAR(50),
    gender VARCHAR(50),
    nationality VARCHAR(50),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    preferred_name VARCHAR(100),
    country_code VARCHAR(20),
    phone VARCHAR(20),
    status VARCHAR(30) NOT NULL,
    role VARCHAR(30) NOT NULL,
    date_created DATE NOT NULL DEFAULT CURRENT_DATE,
    account_updated DATE NOT NULL DEFAULT CURRENT_DATE,
    last_login TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_password DATE NOT NULL DEFAULT CURRENT_DATE,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    account_locked BOOLEAN NOT NULL DEFAULT false,
    account_locked_duration TIMESTAMP,
    ferpa_compliance VARCHAR(20) NOT NULL DEFAULT 'RESTRICTED',
    contact_by_phone BOOLEAN NOT NULL DEFAULT true,
    contact_by_email BOOLEAN NOT NULL DEFAULT true,
    contact_by_mail BOOLEAN NOT NULL DEFAULT false,
    ferpa_directory_opt_in BOOLEAN NOT NULL DEFAULT false,
    photo_release_opt_in BOOLEAN NOT NULL DEFAULT false,
    session_token VARCHAR(255),
    session_expiration TIMESTAMP
);

-- Create a simple roles table in the `paws360` schema
CREATE TABLE IF NOT EXISTS paws360.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

-- Create user_roles junction table in the `paws360` schema
CREATE TABLE IF NOT EXISTS paws360.user_roles (
    user_id INTEGER REFERENCES paws360.users(user_id),
    role_id INTEGER REFERENCES paws360.roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- Insert some test data
INSERT INTO paws360.roles (name, description) VALUES
    ('ADMIN', 'Administrator role'),
    ('USER', 'Regular user role')
ON CONFLICT (name) DO NOTHING;

-- No default users seeded here; `test_seed.sql` handles inserting demo users

-- Minimal authentication_sessions table for session management logic
CREATE TABLE IF NOT EXISTS paws360.authentication_sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id INTEGER REFERENCES paws360.users(user_id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    last_accessed TIMESTAMP NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    service_origin VARCHAR(100),
    logout_reason VARCHAR(50)
);