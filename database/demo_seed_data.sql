-- PAWS360 Demo Data for SSO Integration Testing
-- Compatible with Spring Boot backend entities
-- BCrypt passwords for testing: password

-- Insert demo admin user
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role, 
                  ethnicity, gender, nationality, country_code, preferred_name,
                  account_updated, last_login, changed_password, failed_attempts, account_locked,
                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                  ferpa_directory_opt_in, photo_release_opt_in) VALUES
('Admin', 'User', '1980-01-01', '123456789', 'admin@uwm.edu', 
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 
 '4149999999', 'ACTIVE', 'Administrator', 
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Administrator',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'RESTRICTED', true, true, false, false, false);

-- Insert demo student users
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name,
                  account_updated, last_login, changed_password, failed_attempts, account_locked,
                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                  ferpa_directory_opt_in, photo_release_opt_in) VALUES
('John', 'Smith', '2002-05-15', '111223333', 'john.smith@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4141234567', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Johnny',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, true, true),

('Emily', 'Johnson', '2001-08-22', '222334444', 'emily.johnson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4142345678', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Em',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, true, false),

('Michael', 'Davis', '2003-02-10', '333445555', 'michael.davis@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4143456789', 'ACTIVE', 'STUDENT',
 'BLACK_OR_AFRICAN_AMERICAN', 'MALE', 'UNITED_STATES', 'US', 'Mike',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, true, true),

('Sarah', 'Wilson', '2002-11-30', '444556666', 'sarah.wilson@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4144567890', 'ACTIVE', 'STUDENT',
 'ASIAN', 'FEMALE', 'UNITED_STATES', 'US', 'Sarah',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, true, false),

('David', 'Brown', '2001-07-18', '555667777', 'david.brown@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4145678901', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'CANADA', 'CA', null,
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, false, true);

-- Insert demo faculty
INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name,
                  account_updated, last_login, changed_password, failed_attempts, account_locked,
                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                  ferpa_directory_opt_in, photo_release_opt_in) VALUES
('Dr. Jane', 'Professor', '1975-03-20', '666778888', 'jane.professor@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4146789012', 'ACTIVE', 'PROFESSOR',
 'WHITE', 'FEMALE', 'UNITED_STATES', 'US', 'Dr. Jane',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'RESTRICTED', true, true, false, false, false);

-- Insert student details for the demo students
INSERT INTO student (user_id, campus_id, department, standing, enrollement_status, gpa, expected_graduation)
SELECT u.user_id, 
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN 'S0123456'
           WHEN u.email = 'emily.johnson@uwm.edu' THEN 'S0234567' 
           WHEN u.email = 'michael.davis@uwm.edu' THEN 'S0345678'
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'S0456789'
           WHEN u.email = 'david.brown@uwm.edu' THEN 'S0567890'
       END as campus_id,
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN 'COMPUTER_SCIENCE'
           WHEN u.email = 'emily.johnson@uwm.edu' THEN 'PSYCHOLOGY'
           WHEN u.email = 'michael.davis@uwm.edu' THEN 'MECHANICAL_ENGINEERING'  
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN 'NURSING'
           WHEN u.email = 'david.brown@uwm.edu' THEN 'MARKETING'
       END as department,
       CASE 
           WHEN u.email IN ('john.smith@uwm.edu', 'emily.johnson@uwm.edu') THEN 'JUNIOR'
           WHEN u.email = 'michael.davis@uwm.edu' THEN 'SOPHOMORE'
           WHEN u.email IN ('sarah.wilson@uwm.edu', 'david.brown@uwm.edu') THEN 'SENIOR'
       END as standing,
       'ENROLLED' as enrollement_status,
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN 3.75
           WHEN u.email = 'emily.johnson@uwm.edu' THEN 3.45
           WHEN u.email = 'michael.davis@uwm.edu' THEN 3.20
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN 3.90
           WHEN u.email = 'david.brown@uwm.edu' THEN 3.65
       END as gpa,
       CASE 
           WHEN u.email = 'john.smith@uwm.edu' THEN '2025-05-15'
           WHEN u.email = 'emily.johnson@uwm.edu' THEN '2025-05-15'
           WHEN u.email = 'michael.davis@uwm.edu' THEN '2026-05-15'
           WHEN u.email = 'sarah.wilson@uwm.edu' THEN '2024-12-15'
           WHEN u.email = 'david.brown@uwm.edu' THEN '2024-12-15'
       END::DATE as expected_graduation
FROM users u 
WHERE u.role = 'STUDENT';

-- Create sample demo accounts for easy testing
-- Demo credentials:
-- Email: test.student@uwm.edu, Password: password
-- Email: demo.student@uwm.edu, Password: password  
-- Email: admin@uwm.edu, Password: password

INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                  ethnicity, gender, nationality, country_code, preferred_name,
                  account_updated, last_login, changed_password, failed_attempts, account_locked,
                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                  ferpa_directory_opt_in, photo_release_opt_in) VALUES
('Demo', 'Student', '2002-01-01', '999888777', 'demo.student@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4149999998', 'ACTIVE', 'STUDENT',
 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Demo',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, true, true),

('Test', 'Student', '2001-06-15', '888777666', 'test.student@uwm.edu',
 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 '4149999997', 'ACTIVE', 'STUDENT',
 'HISPANIC_OR_LATINO', 'FEMALE', 'UNITED_STATES', 'US', 'Testy',
 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
 'DIRECTORY', true, true, false, true, false);

-- Insert student details for demo accounts
INSERT INTO student (user_id, campus_id, department, standing, enrollement_status, gpa, expected_graduation)
SELECT u.user_id,
       CASE 
           WHEN u.email = 'demo.student@uwm.edu' THEN 'S1000001'
           WHEN u.email = 'test.student@uwm.edu' THEN 'S1000002'
       END as campus_id,
       CASE 
           WHEN u.email = 'demo.student@uwm.edu' THEN 'COMPUTER_SCIENCE'
           WHEN u.email = 'test.student@uwm.edu' THEN 'BUSINESS_ADMINISTRATION'
       END as department,
       'JUNIOR' as standing,
       'ENROLLED' as enrollement_status,
       CASE 
           WHEN u.email = 'demo.student@uwm.edu' THEN 3.50
           WHEN u.email = 'test.student@uwm.edu' THEN 3.25
       END as gpa,
       '2025-12-15'::DATE as expected_graduation
FROM users u 
WHERE u.email IN ('demo.student@uwm.edu', 'test.student@uwm.edu');

COMMIT;

-- Display demo accounts summary
SELECT 'Demo Accounts Created Successfully!' as message;
SELECT 
    u.firstname || ' ' || u.lastname as full_name,
    u.email,
    u.role,
    s.campus_id,
    s.department,
    s.standing,
    s.gpa
FROM users u
LEFT JOIN student s ON u.user_id = s.user_id
ORDER BY u.role DESC, u.email;