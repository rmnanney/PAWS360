package com.uwm.paws360.Controller;

import com.uwm.paws360.Entity.Base.AuthenticationSession;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Service.SessionManagementService;
import com.uwm.paws360.Service.StudentProfileService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Admin controller for student data lookup and management.
 * Provides role-based access to student information for administrators.
 */
@RestController
@RequestMapping("/admin")
public class AdminStudentController {

    private final StudentProfileService studentProfileService;
    private final SessionManagementService sessionManagementService;

    public AdminStudentController(StudentProfileService studentProfileService,
                                SessionManagementService sessionManagementService) {
        this.studentProfileService = studentProfileService;
        this.sessionManagementService = sessionManagementService;
    }

    /*------------------------- Student Search Endpoints -------------------------*/

    /**
     * Search students by name for admin use
     */
    @GetMapping("/students/search")
    public ResponseEntity<Map<String, Object>> searchStudents(@RequestParam(required = false) String query,
                                                              @RequestParam(required = false) String department,
                                                              @RequestParam(defaultValue = "50") int limit,
                                                              HttpServletRequest request) {
        // Verify admin authentication
        ResponseEntity<Map<String, Object>> authCheck = verifyAdminAccess(request);
        if (authCheck != null) {
            return authCheck;
        }

        List<StudentProfileService.StudentProfileData> students;
        
        if (department != null && !department.trim().isEmpty()) {
            students = studentProfileService.getStudentsByDepartment(department);
        } else if (query != null && !query.trim().isEmpty()) {
            students = studentProfileService.searchStudentsByName(query);
        } else {
            students = studentProfileService.getAllStudents();
        }

        // Apply limit to results
        if (students.size() > limit) {
            students = students.subList(0, limit);
        }

        List<Map<String, Object>> studentList = students.stream()
            .map(this::createAdminStudentSummary)
            .toList();

        Map<String, Object> response = new HashMap<>();
        response.put("students", studentList);
        response.put("count", studentList.size());
        response.put("total_available", studentProfileService.getAllStudents().size());
        response.put("query", query);
        response.put("department", department);
        response.put("limit", limit);

        return ResponseEntity.ok(response);
    }

    /**
     * Get detailed student profile by user ID (admin view)
     */
    @GetMapping("/students/{userId}")
    public ResponseEntity<Map<String, Object>> getStudentDetails(@PathVariable int userId,
                                                               HttpServletRequest request) {
        // Verify admin authentication
        ResponseEntity<Map<String, Object>> authCheck = verifyAdminAccess(request);
        if (authCheck != null) {
            return authCheck;
        }

        Optional<StudentProfileService.StudentProfileData> profileOpt = 
            studentProfileService.getStudentProfile(userId);

        if (profileOpt.isEmpty()) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Student not found");
            errorResponse.put("user_id", userId);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }

        StudentProfileService.StudentProfileData profile = profileOpt.get();
        Map<String, Object> response = createDetailedAdminStudentProfile(profile);

        return ResponseEntity.ok(response);
    }

    /**
     * Get student profile by email (admin view)
     */
    @GetMapping("/students/by-email")
    public ResponseEntity<Map<String, Object>> getStudentDetailsByEmail(@RequestParam String email,
                                                                       HttpServletRequest request) {
        // Verify admin authentication
        ResponseEntity<Map<String, Object>> authCheck = verifyAdminAccess(request);
        if (authCheck != null) {
            return authCheck;
        }

        Optional<StudentProfileService.StudentProfileData> profileOpt = 
            studentProfileService.getStudentProfileByEmail(email);

        if (profileOpt.isEmpty()) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Student not found");
            errorResponse.put("email", email);
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }

        StudentProfileService.StudentProfileData profile = profileOpt.get();
        Map<String, Object> response = createDetailedAdminStudentProfile(profile);

        return ResponseEntity.ok(response);
    }

    /*------------------------- Data Consistency Endpoints -------------------------*/

    /**
     * Validate student data consistency between different views
     */
    @GetMapping("/students/{userId}/validate")
    public ResponseEntity<Map<String, Object>> validateStudentDataConsistency(@PathVariable int userId,
                                                                             HttpServletRequest request) {
        // Verify admin authentication
        ResponseEntity<Map<String, Object>> authCheck = verifyAdminAccess(request);
        if (authCheck != null) {
            return authCheck;
        }

        Map<String, Object> validation = studentProfileService.validateStudentData(userId);
        
        // Add additional admin-specific validation checks
        validation.put("admin_verified", true);
        validation.put("validated_by", getCurrentAdminUser(request));
        validation.put("validation_timestamp", java.time.LocalDateTime.now());

        return ResponseEntity.ok(validation);
    }

    /**
     * Get student statistics for admin dashboard
     */
    @GetMapping("/dashboard/stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats(HttpServletRequest request) {
        // Verify admin authentication
        ResponseEntity<Map<String, Object>> authCheck = verifyAdminAccess(request);
        if (authCheck != null) {
            return authCheck;
        }

        Map<String, Long> counts = studentProfileService.getStudentCounts();
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("student_counts", counts);
        stats.put("active_sessions", sessionManagementService.getActiveSessionsCount());
        stats.put("session_stats", sessionManagementService.getSessionStatsByService());
        stats.put("generated_at", java.time.LocalDateTime.now());

        return ResponseEntity.ok(stats);
    }

    /*------------------------- Helper Methods -------------------------*/

    /**
     * Verify admin access and return error response if unauthorized
     */
    private ResponseEntity<Map<String, Object>> verifyAdminAccess(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        if (sessionToken == null) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Authentication required");
            errorResponse.put("required_role", "Administrator or Super_Administrator");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        Optional<AuthenticationSession> sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
        
        if (sessionOpt.isEmpty()) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Invalid or expired session");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        Users user = sessionOpt.get().getUser();
        if (!hasAdminRole(user)) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Insufficient privileges");
            errorResponse.put("required_role", "Administrator or Super_Administrator");
            errorResponse.put("current_role", user.getRole().toString());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        return null; // Access granted
    }

    /**
     * Get current admin user info from session
     */
    private String getCurrentAdminUser(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        if (sessionToken != null) {
            Optional<AuthenticationSession> sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
            if (sessionOpt.isPresent()) {
                Users user = sessionOpt.get().getUser();
                return user.getEmail() + " (" + user.getRole().toString() + ")";
            }
        }
        return "Unknown Admin";
    }

    /**
     * Create summary student profile for admin list view
     */
    private Map<String, Object> createAdminStudentSummary(StudentProfileService.StudentProfileData profile) {
        Map<String, Object> summary = new HashMap<>();
        
        // User information
        summary.put("user_id", profile.getUser().getId());
        summary.put("student_id", profile.getStudent().getId());
        summary.put("email", profile.getUser().getEmail());
        summary.put("firstname", profile.getUser().getFirstname());
        summary.put("lastname", profile.getUser().getLastname());
        summary.put("preferred_name", profile.getUser().getPreferred_name());
        summary.put("status", profile.getUser().getStatus());
        
        // Student academic information
        summary.put("campus_id", profile.getStudent().getCampusId());
        summary.put("department", profile.getStudent().getDepartment());
        summary.put("standing", profile.getStudent().getStanding());
        summary.put("enrollment_status", profile.getStudent().getEnrollementStatus());
        summary.put("gpa", profile.getStudent().getGpa());
        summary.put("expected_graduation", profile.getStudent().getExpectedGraduation());
        
        // Admin-specific fields
        summary.put("last_updated", profile.getStudent().getUpdatedAt());
        summary.put("account_created", profile.getUser().getDate_created());
        
        return summary;
    }

    /**
     * Create detailed student profile for admin detail view
     */
    private Map<String, Object> createDetailedAdminStudentProfile(StudentProfileService.StudentProfileData profile) {
        Map<String, Object> response = new HashMap<>();
        
        // Complete user information
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("user_id", profile.getUser().getId());
        userInfo.put("email", profile.getUser().getEmail());
        userInfo.put("firstname", profile.getUser().getFirstname());
        userInfo.put("lastname", profile.getUser().getLastname());
        userInfo.put("preferred_name", profile.getUser().getPreferred_name());
        userInfo.put("status", profile.getUser().getStatus());
        userInfo.put("role", profile.getUser().getRole());
        userInfo.put("phone", profile.getUser().getPhone());
        userInfo.put("country_code", profile.getUser().getCountryCode());
        userInfo.put("created_at", profile.getUser().getDate_created());
        userInfo.put("updated_at", profile.getUser().getAccount_updated());
        
        // Complete student information
        Map<String, Object> studentInfo = new HashMap<>();
        studentInfo.put("student_id", profile.getStudent().getId());
        studentInfo.put("campus_id", profile.getStudent().getCampusId());
        studentInfo.put("department", profile.getStudent().getDepartment());
        studentInfo.put("standing", profile.getStudent().getStanding());
        studentInfo.put("enrollment_status", profile.getStudent().getEnrollementStatus());
        studentInfo.put("gpa", profile.getStudent().getGpa());
        studentInfo.put("expected_graduation", profile.getStudent().getExpectedGraduation());
        studentInfo.put("created_at", profile.getStudent().getCreatedAt());
        studentInfo.put("updated_at", profile.getStudent().getUpdatedAt());
        
        response.put("user", userInfo);
        response.put("student", studentInfo);
        response.put("admin_view", true);
        response.put("data_consistency_check", studentProfileService.validateStudentData(profile.getUser().getId()));
        
        return response;
    }

    /**
     * Extract session token from request
     */
    private String extractSessionToken(HttpServletRequest request) {
        // First try to get from cookie
        if (request.getCookies() != null) {
            for (var cookie : request.getCookies()) {
                if ("PAWS360_SESSION".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        
        // Fallback to Authorization header
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        
        return request.getHeader("X-Session-Token");
    }

    /**
     * Check if user has admin role
     */
    private boolean hasAdminRole(Users user) {
        if (user == null || user.getRole() == null) {
            return false;
        }
        return user.getRole().toString().equals("Administrator") || 
               user.getRole().toString().equals("Super_Administrator");
    }
}