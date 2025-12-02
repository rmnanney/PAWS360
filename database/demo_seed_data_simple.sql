-- Demo Data for PAWS360 - Simple Version
-- This script inserts demo users and students for testing SSO authentication

BEGIN;

-- Insert demo admin user (only essential fields)
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role, 
                  ethnicity, gender, nationality, country_code, preferred_name, failed_attempts) VALUES
('Admin', 'User', '1980-01-01', '123456789', 'admin@uwm.edu', 
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 
 '4149999999', 'ACTIVE', 'Administrator', 
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Administrator', 0);

-- Insert demo student users
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name, failed_attempts) VALUES
('John', 'Smith', '2002-05-15', '111223333', 'john.smith@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141234567', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Johnny', 0),

('Emily', 'Johnson', '2003-08-22', '222334444', 'emily.johnson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4142345678', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Em', 0),

('Michael', 'Davis', '2003-02-10', '333445555', 'michael.davis@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4143456789', 'ACTIVE', 'STUDENT',
 'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', 'US', 'Mike', 0),

('Sarah', 'Wilson', '2002-11-30', '444556666', 'sarah.wilson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4144567890', 'ACTIVE', 'STUDENT',
 'ASIAN', 'FEMALE', 'UNITED_STATES', 'US', 'Sarah', 0),

('David', 'Brown', '2001-07-18', '555667777', 'david.brown@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4145678901', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'CANADA', 'CA', null, 0);

-- Insert demo faculty
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name, failed_attempts) VALUES
('Dr. Jane', 'Professor', '1975-03-20', '666778888', 'jane.professor@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4146789012', 'ACTIVE', 'PROFESSOR',
 'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Dr. Jane', 0);

-- Insert special test accounts for authentication testing
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name, failed_attempts) VALUES
('Demo', 'Student', '2002-01-01', '999888777', 'demo.student@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4149999998', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Demo', 0),

('Test', 'Student', '2001-06-15', '888777666', 'test.student@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4149999997', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Testy', 0);

-- Insert student details for demo accounts
INSERT INTO student (user_id, campus_id, department, standing, enrollement_status, gpa, expected_graduation)
SELECT u.user_id,
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN 'STU001'
           WHEN u.email = 'emily.johnson@uwm.edu' THEN 'STU002'
           WHEN u.email = 'michael.davis@uwm.edu' THEN 'STU003'
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'STU004'
           WHEN u.email = 'david.brown@uwm.edu' THEN 'STU005'
           WHEN u.email = 'demo.student@uwm.edu' THEN 'DEMO001'
           WHEN u.email = 'test.student@uwm.edu' THEN 'TEST001'
       END as campus_id,
       CASE 
           WHEN u.email IN ('john.smith@uwm.edu', 'michael.davis@uwm.edu', 'demo.student@uwm.edu') THEN 'COMPUTER_SCIENCE'
           WHEN u.email IN ('emily.johnson@uwm.edu', 'test.student@uwm.edu') THEN 'PSYCHOLOGY'
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'MATHEMATICS'
           WHEN u.email = 'david.brown@uwm.edu' THEN 'ENGLISH'
       END as department,
       CASE 
           WHEN u.email IN ('john.smith@uwm.edu', 'emily.johnson@uwm.edu') THEN 'JUNIOR'
           WHEN u.email IN ('michael.davis@uwm.edu', 'sarah.wilson@uwm.edu') THEN 'SOPHOMORE'
           WHEN u.email = 'david.brown@uwm.edu' THEN 'SENIOR'
           WHEN u.email IN ('demo.student@uwm.edu', 'test.student@uwm.edu') THEN 'FRESHMAN'
       END as standing,
       'ENROLLED' as enrollement_status,
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN 3.75
           WHEN u.email = 'emily.johnson@uwm.edu' THEN 3.25
           WHEN u.email = 'michael.davis@uwm.edu' THEN 3.50
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN 3.80
           WHEN u.email = 'david.brown@uwm.edu' THEN 3.95
           WHEN u.email = 'demo.student@uwm.edu' THEN 3.00
           WHEN u.email = 'test.student@uwm.edu' THEN 2.75
       END as gpa,
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN '2025-05-15'::date
           WHEN u.email = 'emily.johnson@uwm.edu' THEN '2026-05-15'::date
           WHEN u.email = 'michael.davis@uwm.edu' THEN '2026-12-15'::date
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN '2025-12-15'::date
           WHEN u.email = 'david.brown@uwm.edu' THEN '2025-05-15'::date
           WHEN u.email = 'demo.student@uwm.edu' THEN '2027-05-15'::date
           WHEN u.email = 'test.student@uwm.edu' THEN '2027-12-15'::date
       END as expected_graduation
FROM users u
WHERE u.role = 'STUDENT';

COMMIT;

-- Verification queries
SELECT 'Demo Accounts Created Successfully!' as message;

SELECT CONCAT(u.firstname, ' ', u.lastname) as full_name, 
       u.email, 
       u.role, 
       s.campus_id, 
       s.department, 
       s.standing, 
       s.gpa
FROM users u
LEFT JOIN student s ON u.user_id = s.user_id
WHERE u.email IN ('admin@uwm.edu', 'demo.student@uwm.edu', 'test.student@uwm.edu', 'john.smith@uwm.edu')
ORDER BY u.role, u.email;