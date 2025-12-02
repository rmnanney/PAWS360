-- Students
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    date_of_birth DATE,
   
);

-- Advisors
CREATE TABLE advisors (
    advisor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(100)
);

-- Courses
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL
);

-- Enrollments
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    semester VARCHAR(20),
    grade VARCHAR(2)
);

-- Billing
CREATE TABLE billing (
    billing_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    amount NUMERIC(10,2),
    due_date DATE,
    status VARCHAR(20)
);

-- Advisor Scheduling
CREATE TABLE advisor_meetings (
    meeting_id SERIAL PRIMARY KEY,
    advisor_id INT REFERENCES advisors(advisor_id),
    student_id INT REFERENCES students(student_id),
    meeting_time TIMESTAMP,
    status VARCHAR(20)
);