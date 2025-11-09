package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Service for managing student profile data and operations.
 * Supports unified backend data access for student portal and admin views.
 */
@Service
@Transactional
public class StudentProfileService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;

    public StudentProfileService(UserRepository userRepository, StudentRepository studentRepository) {
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
    }

    /*------------------------- Student Profile Access -------------------------*/

    /**
     * Get complete student profile by user ID
     */
    public Optional<StudentProfileData> getStudentProfile(int userId) {
        Optional<Users> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return Optional.empty();
        }

        Users user = userOpt.get();
        Optional<Student> studentOpt = studentRepository.findByUser(user);
        
        if (studentOpt.isEmpty()) {
            return Optional.empty();
        }

        return Optional.of(new StudentProfileData(user, studentOpt.get()));
    }

    /**
     * Get student profile by email
     */
    public Optional<StudentProfileData> getStudentProfileByEmail(String email) {
        Users user = userRepository.findUsersByEmailIgnoreCase(email);
        if (user == null) {
            return Optional.empty();
        }

        Optional<Student> studentOpt = studentRepository.findByUser(user);
        if (studentOpt.isEmpty()) {
            return Optional.empty();
        }

        return Optional.of(new StudentProfileData(user, studentOpt.get()));
    }

    /**
     * Get student profile by campus ID
     */
    public Optional<StudentProfileData> getStudentProfileByCampusId(String campusId) {
        List<Student> students = studentRepository.findAll();
        Optional<Student> studentOpt = students.stream()
            .filter(s -> campusId.equals(s.getCampusId()))
            .findFirst();
            
        if (studentOpt.isEmpty()) {
            return Optional.empty();
        }

        Student student = studentOpt.get();
        return Optional.of(new StudentProfileData(student.getUser(), student));
    }

    /**
     * Get basic student information for dashboard
     */
    public Optional<StudentDashboardData> getStudentDashboard(int userId) {
        Optional<StudentProfileData> profileOpt = getStudentProfile(userId);
        if (profileOpt.isEmpty()) {
            return Optional.empty();
        }

        StudentProfileData profile = profileOpt.get();
        return Optional.of(new StudentDashboardData(
            profile.getUser().getId(),
            profile.getUser().getFirstname(),
            profile.getUser().getLastname(),
            profile.getUser().getPreferred_name(),
            profile.getUser().getEmail(),
            profile.getStudent().getCampusId(),
            profile.getStudent().getDepartment(),
            profile.getStudent().getStanding(),
            profile.getStudent().getGpa(),
            profile.getStudent().getExpectedGraduation(),
            profile.getStudent().getEnrollementStatus()
        ));
    }

    /*------------------------- Student Search and Listing -------------------------*/

    /**
     * Get all students (for admin use)
     */
    public List<StudentProfileData> getAllStudents() {
        return studentRepository.findAll().stream()
            .map(student -> new StudentProfileData(student.getUser(), student))
            .toList();
    }

    /**
     * Search students by name (for admin use)
     */
    public List<StudentProfileData> searchStudentsByName(String searchTerm) {
        if (searchTerm == null || searchTerm.trim().isEmpty()) {
            return getAllStudents();
        }

        return getAllStudents().stream()
            .filter(profile -> {
                String fullName = (profile.getUser().getFirstname() + " " + profile.getUser().getLastname()).toLowerCase();
                String preferredName = profile.getUser().getPreferred_name();
                String email = profile.getUser().getEmail().toLowerCase();
                String campusId = profile.getStudent().getCampusId();
                
                return fullName.contains(searchTerm.toLowerCase()) ||
                       (preferredName != null && preferredName.toLowerCase().contains(searchTerm.toLowerCase())) ||
                       email.contains(searchTerm.toLowerCase()) ||
                       (campusId != null && campusId.toLowerCase().contains(searchTerm.toLowerCase()));
            })
            .toList();
    }

    /**
     * Get students by department (for admin use)
     */
    public List<StudentProfileData> getStudentsByDepartment(String department) {
        return getAllStudents().stream()
            .filter(profile -> profile.getStudent().getDepartment() != null &&
                             profile.getStudent().getDepartment().toString().equals(department))
            .toList();
    }

    /*------------------------- Data Validation and Health -------------------------*/

    /**
     * Validate student data consistency
     */
    public Map<String, Object> validateStudentData(int userId) {
        Map<String, Object> validation = new HashMap<>();
        
        Optional<StudentProfileData> profileOpt = getStudentProfile(userId);
        if (profileOpt.isEmpty()) {
            validation.put("valid", false);
            validation.put("error", "Student not found");
            return validation;
        }

        StudentProfileData profile = profileOpt.get();
        validation.put("valid", true);
        validation.put("user_id", profile.getUser().getId());
        validation.put("student_id", profile.getStudent().getId());
        validation.put("has_campus_id", profile.getStudent().getCampusId() != null);
        validation.put("has_department", profile.getStudent().getDepartment() != null);
        validation.put("has_gpa", profile.getStudent().getGpa() != null);
        validation.put("enrollment_status", profile.getStudent().getEnrollementStatus());
        validation.put("account_status", profile.getUser().getStatus());
        
        return validation;
    }

    /**
     * Get student counts for demo data validation
     */
    public Map<String, Long> getStudentCounts() {
        List<Student> allStudents = studentRepository.findAll();
        Map<String, Long> counts = new HashMap<>();
        
        counts.put("total_students", (long) allStudents.size());
        counts.put("active_students", allStudents.stream()
            .filter(s -> s.getUser().getStatus().toString().equals("ACTIVE"))
            .count());
        counts.put("students_with_gpa", allStudents.stream()
            .filter(s -> s.getGpa() != null)
            .count());
        counts.put("students_with_campus_id", allStudents.stream()
            .filter(s -> s.getCampusId() != null && !s.getCampusId().trim().isEmpty())
            .count());
            
        return counts;
    }

    /*------------------------- Data Transfer Objects -------------------------*/

    /**
     * Complete student profile data
     */
    public static class StudentProfileData {
        private final Users user;
        private final Student student;

        public StudentProfileData(Users user, Student student) {
            this.user = user;
            this.student = student;
        }

        public Users getUser() { return user; }
        public Student getStudent() { return student; }
    }

    /**
     * Student dashboard data (summary view)
     */
    public static class StudentDashboardData {
        private final int userId;
        private final String firstname;
        private final String lastname;
        private final String preferredName;
        private final String email;
        private final String campusId;
        private final Object department;
        private final Object standing;
        private final Object gpa;
        private final Object expectedGraduation;
        private final Object enrollmentStatus;

        public StudentDashboardData(int userId, String firstname, String lastname, String preferredName,
                                  String email, String campusId, Object department, Object standing,
                                  Object gpa, Object expectedGraduation, Object enrollmentStatus) {
            this.userId = userId;
            this.firstname = firstname;
            this.lastname = lastname;
            this.preferredName = preferredName;
            this.email = email;
            this.campusId = campusId;
            this.department = department;
            this.standing = standing;
            this.gpa = gpa;
            this.expectedGraduation = expectedGraduation;
            this.enrollmentStatus = enrollmentStatus;
        }

        // Getters
        public int getUserId() { return userId; }
        public String getFirstname() { return firstname; }
        public String getLastname() { return lastname; }
        public String getPreferredName() { return preferredName; }
        public String getEmail() { return email; }
        public String getCampusId() { return campusId; }
        public Object getDepartment() { return department; }
        public Object getStanding() { return standing; }
        public Object getGpa() { return gpa; }
        public Object getExpectedGraduation() { return expectedGraduation; }
        public Object getEnrollmentStatus() { return enrollmentStatus; }
    }
}