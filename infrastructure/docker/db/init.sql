-- PAWS360 Database Initialization for Docker
-- Create tables matching the JPA Users entity

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create users table matching JPA entity
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    firstname VARCHAR(100) NOT NULL,
    middlename VARCHAR(100),
    lastname VARCHAR(30) NOT NULL,
    dob DATE NOT NULL,
    ssn VARCHAR(9) NOT NULL UNIQUE,
    ethnicity VARCHAR(255),
    gender VARCHAR(255),
    nationality VARCHAR(255),
    email VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(120) NOT NULL,
    preferred_name VARCHAR(100),
    country_code VARCHAR(255),
    phone VARCHAR(10),
    status VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    date_created DATE NOT NULL DEFAULT CURRENT_DATE,
    account_updated DATE NOT NULL DEFAULT CURRENT_DATE,
    last_login TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_password DATE NOT NULL DEFAULT CURRENT_DATE,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    account_locked BOOLEAN NOT NULL DEFAULT false,
    account_locked_duration TIMESTAMP,
    ferpa_compliance VARCHAR(255) NOT NULL DEFAULT 'RESTRICTED',
    contact_by_phone BOOLEAN NOT NULL DEFAULT true,
    contact_by_email BOOLEAN NOT NULL DEFAULT true,
    contact_by_mail BOOLEAN NOT NULL DEFAULT false,
    ferpa_directory_opt_in BOOLEAN NOT NULL DEFAULT false,
    photo_release_opt_in BOOLEAN NOT NULL DEFAULT false,
    session_token VARCHAR(255),
    session_expiration TIMESTAMP
);

-- Insert demo users for E2E testing (using BCrypt hashed passwords)
-- BCrypt hash for 'password': $2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi. 
INSERT INTO users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
VALUES ('Demo', 'Student', '1990-01-01', '123456789', 'demo.student@uwm.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.', 'ACTIVE', 'STUDENT', 'RESTRICTED', true, true, false, false, false, 0, false)
ON CONFLICT (email) DO UPDATE SET 
    failed_attempts = 0, 
    account_locked = false, 
    account_locked_duration = null;

INSERT INTO users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
VALUES ('Demo', 'Admin', '1980-01-01', '987654321', 'demo.admin@uwm.edu', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.', 'ACTIVE', 'Administrator', 'RESTRICTED', true, true, false, false, false, 0, false)
ON CONFLICT (email) DO UPDATE SET 
    failed_attempts = 0, 
    account_locked = false, 
    account_locked_duration = null;