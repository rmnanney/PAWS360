INSERT INTO students (first_name, last_name, email, date_of_birth)
VALUES 
('Alice', 'Johnson', 'alice.johnson@example.com', '2001-03-15'),
('Bob', 'Smith', 'bob.smith@example.com', '2000-07-22');

INSERT INTO advisors (first_name, last_name, department)
VALUES 
('Dr.', 'Green', 'Computer Science'),
('Prof.', 'Miller', 'Engineering');

INSERT INTO courses (course_name, credits)
VALUES 
('Database Systems', 3),
('Software Engineering', 4);

INSERT INTO enrollments (student_id, course_id, semester, grade)
VALUES 
(1, 1, 'Fall2025', 'A'),
(2, 2, 'Fall2025', 'B');

INSERT INTO billing (student_id, amount, due_date, status)
VALUES 
(1, 1500.00, '2025-10-01', 'Pending'),
(2, 2000.00, '2025-10-05', 'Paid');

INSERT INTO advisor_meetings (advisor_id, student_id, meeting_time, status)
VALUES 
(1, 1, '2025-09-20 14:00:00', 'Scheduled');