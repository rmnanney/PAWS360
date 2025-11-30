-- Demo data for E2E testing
-- This file is loaded automatically by Spring Boot after Hibernate schema creation

-- Insert user only if not already present (works for H2 and Postgres)
INSERT INTO users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
SELECT 'Demo', 'Student', '1990-01-01', '123456789', 'demo.student@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'ACTIVE', 'student', 'RESTRICTED', TRUE, TRUE, FALSE, FALSE, FALSE, 0, FALSE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'demo.student@uwm.edu');

INSERT INTO users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
SELECT 'Demo', 'Admin', '1980-01-01', '987654321', 'demo.admin@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'ACTIVE', 'admin', 'RESTRICTED', TRUE, TRUE, FALSE, FALSE, FALSE, 0, FALSE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'demo.admin@uwm.edu');