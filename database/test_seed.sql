-- Minimal CI seed for test_schema.sql
-- Keeps only simple roles and a couple of users the app expects for tests

-- Create a sample admin and test user
INSERT INTO paws360.roles (name, description) VALUES
  ('ADMIN', 'Administrator role'),
  ('USER', 'Regular user role')
ON CONFLICT (name) DO NOTHING;

-- Demo accounts used by Playwright and integration tests
INSERT INTO paws360.users (firstname, lastname, dob, ssn, email, password, status, role, ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail, ferpa_directory_opt_in, photo_release_opt_in, failed_attempts, account_locked)
VALUES
  ('Demo', 'Student', '1990-01-01', '123456789', 'demo.student@uwm.edu', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj8ZJcKvqXu', 'ACTIVE', 'STUDENT', 'RESTRICTED', TRUE, TRUE, FALSE, FALSE, FALSE, 0, FALSE),
  ('Demo', 'Admin', '1980-01-01', '987654321', 'demo.admin@uwm.edu', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj8ZJcKvqXu', 'ACTIVE', 'ADMIN', 'RESTRICTED', TRUE, TRUE, FALSE, FALSE, FALSE, 0, FALSE)
ON CONFLICT (email) DO NOTHING;

-- Assign the admin role to admin user
DO $$
DECLARE
  admin_id_val INTEGER;
  role_id_val INTEGER;
BEGIN
  SELECT user_id INTO admin_id_val FROM paws360.users WHERE email = 'demo.admin@uwm.edu';
  SELECT id INTO role_id_val FROM paws360.roles WHERE name = 'ADMIN';
  IF admin_id_val IS NOT NULL AND role_id_val IS NOT NULL THEN
    INSERT INTO paws360.user_roles (user_id, role_id) VALUES (admin_id_val, role_id_val)
    ON CONFLICT (user_id, role_id) DO NOTHING;
  END IF;
END $$;