-- PAWS360 Demo Data Reset Script
-- Quick script to reset demo environment to baseline state
-- This script is called by DemoDataService for programmatic resets

BEGIN;

-- =============================================================================
-- DEMO DATA CLEANUP (Idempotent Reset)
-- =============================================================================

-- Remove authentication sessions for demo accounts
DELETE FROM authentication_sessions WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

-- Remove emergency contacts
DELETE FROM emergency_contacts WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

-- Remove addresses
DELETE FROM addresses WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

-- Remove role-specific records in dependency order
DELETE FROM ta WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM student WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM professor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM mentor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM instructor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM faculty WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM counselor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

DELETE FROM advisor WHERE user_id IN (
    SELECT user_id FROM users WHERE email LIKE '%@uwm.edu'
);

-- Finally, remove all demo users
DELETE FROM users WHERE email LIKE '%@uwm.edu';

-- Reset auto-increment sequences to ensure consistent IDs
SELECT setval('users_id_seq', COALESCE((SELECT MAX(user_id) FROM users), 0) + 1, false);
SELECT setval('student_id_seq', COALESCE((SELECT MAX(id) FROM student), 0) + 1, false);
SELECT setval('professor_id_seq', COALESCE((SELECT MAX(id) FROM professor), 0) + 1, false);
SELECT setval('addresses_id_seq', COALESCE((SELECT MAX(id) FROM addresses), 0) + 1, false);
SELECT setval('emergency_contacts_id_seq', COALESCE((SELECT MAX(id) FROM emergency_contacts), 0) + 1, false);
SELECT setval('authentication_sessions_id_seq', COALESCE((SELECT MAX(id) FROM authentication_sessions), 0) + 1, false);

COMMIT;

-- Confirmation
SELECT 
    'Demo data reset completed successfully' as status,
    CURRENT_TIMESTAMP as reset_time,
    'Environment ready for fresh demo data initialization' as next_step;