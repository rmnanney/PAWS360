-- Test-specific demo data for H2 (no Postgres-only ON CONFLICT syntax)

INSERT INTO users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
VALUES ('Demo', 'Student', '1990-01-01', '123456789', 'demo.student@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'ACTIVE', 'student', 'RESTRICTED', true, true, false, false, false, 0, false);

INSERT INTO users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
VALUES ('Demo', 'Admin', '1980-01-01', '987654321', 'demo.admin@uwm.edu', '$2b$12$aSb5KDjeHRz/nEc7Wg6yBeMKzrFybT7wU3CV7FGePrajKCa6Uu87i', 'ACTIVE', 'admin', 'RESTRICTED', true, true, false, false, false, 0, false);
