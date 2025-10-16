-- Create the paws360 schema for the Courses table
CREATE SCHEMA IF NOT EXISTS paws360;

-- Simple test schema for CI/CD testing
-- This creates minimal tables needed for the application to start

-- Create a simple users table for testing
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create a simple roles table
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

-- Create user_roles junction table
CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER REFERENCES users(id),
    role_id INTEGER REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- Insert some test data
INSERT INTO roles (name, description) VALUES
    ('ADMIN', 'Administrator role'),
    ('USER', 'Regular user role')
ON CONFLICT (name) DO NOTHING;

INSERT INTO users (username, email, password_hash) VALUES
    ('testuser', 'test@example.com', '$2a$10$test.hash.for.ci.testing')
ON CONFLICT (username) DO NOTHING;