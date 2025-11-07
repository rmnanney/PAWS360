package com.uwm.paws360.Controller;

import com.uwm.paws360.Service.StudentProfileService;
import com.uwm.paws360.Service.SessionManagementService;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * REST controller for user profile data access.
 * Supports student portal and admin view data requirements with SSO session validation.
 */
@RestController
@RequestMapping("/api/profile")
public class UserProfileController {

    private static final Logger logger = LoggerFactory.getLogger(UserProfileController.class);

    private final StudentProfileService studentProfileService;
    private final SessionManagementService sessionManagementService;

    public UserProfileController(StudentProfileService studentProfileService, 
                               SessionManagementService sessionManagementService) {
        this.studentProfileService = studentProfileService;
        this.sessionManagementService = sessionManagementService;
    }

    /*------------------------- Student Profile Endpoints -------------------------*/

    /**
     * Get current user's student profile
     */
    @GetMapping("/student")
    public ResponseEntity<Map<String, Object>> getCurrentStudentProfile(HttpServletRequest request) {
        String clientIp = getClientIpAddress(request);
        String sessionToken = extractSessionToken(request);
        
        logger.debug("Student profile request from IP: {}", clientIp);
        
        try {
            if (sessionToken == null) {
                logger.warn("Student profile request without session token from IP: {}", clientIp);
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    Map.of("error", "No valid session found", "message", "Please log in to access your profile")
                );
            }

            var sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
            if (sessionOpt.isEmpty()) {
                logger.warn("Student profile request with invalid session from IP: {}", clientIp);
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                    Map.of("error", "Invalid or expired session", "message", "Your session has expired. Please log in again.")
                );
            }

            int userId = sessionOpt.get().getUser().getId();
            Optional<StudentProfileService.StudentDashboardData> dashboardOpt = 
                studentProfileService.getStudentDashboard(userId);

            if (dashboardOpt.isEmpty()) {
                logger.warn("Student profile not found for user ID: {} from IP: {}", userId, clientIp);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                    Map.of("error", "Student profile not found", "message", "No student profile found for your account")
                );
            }

            StudentProfileService.StudentDashboardData dashboard = dashboardOpt.get();
            Map<String, Object> response = new HashMap<>();
            response.put("user_id", dashboard.getUserId());
            response.put("firstname", dashboard.getFirstname());
            response.put("lastname", dashboard.getLastname());
            response.put("preferred_name", dashboard.getPreferredName());
            response.put("email", dashboard.getEmail());
            response.put("campus_id", dashboard.getCampusId());
            response.put("department", dashboard.getDepartment());
            response.put("standing", dashboard.getStanding());
            response.put("gpa", dashboard.getGpa());
            response.put("expected_graduation", dashboard.getExpectedGraduation());
            response.put("enrollment_status", dashboard.getEnrollmentStatus());

            logger.info("Student profile successfully retrieved for user ID: {} from IP: {}", userId, clientIp);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Error retrieving student profile from IP: {}: {}", clientIp, e.getMessage(), e);
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                Map.of(
                    "error", "Service temporarily unavailable", 
                    "message", "Unable to retrieve profile at this time. Please try again later.",
                    "error_type", "SERVICE_ERROR"
                )
            );
        }
    }

    /**
     * Get student profile by user ID (admin use)
     */
    @GetMapping("/student/{userId}")
    public ResponseEntity<Map<String, Object>> getStudentProfile(@PathVariable int userId,
                                                               HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        if (sessionToken == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "No valid session found")
            );
        }

        var sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
        if (sessionOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "Invalid or expired session")
            );
        }

        // TODO: Add role-based access control for admin endpoints

        Optional<StudentProfileService.StudentProfileData> profileOpt = 
            studentProfileService.getStudentProfile(userId);

        if (profileOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                Map.of("error", "Student profile not found")
            );
        }

        StudentProfileService.StudentProfileData profile = profileOpt.get();
        Map<String, Object> response = createFullProfileResponse(profile);

        return ResponseEntity.ok(response);
    }

    /**
     * Get student profile by email (admin use)
     */
    @GetMapping("/student/by-email")
    public ResponseEntity<Map<String, Object>> getStudentProfileByEmail(@RequestParam String email,
                                                                      HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        if (sessionToken == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "No valid session found")
            );
        }

        var sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
        if (sessionOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "Invalid or expired session")
            );
        }

        // TODO: Add role-based access control for admin endpoints

        Optional<StudentProfileService.StudentProfileData> profileOpt = 
            studentProfileService.getStudentProfileByEmail(email);

        if (profileOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
                Map.of("error", "Student profile not found")
            );
        }

        StudentProfileService.StudentProfileData profile = profileOpt.get();
        Map<String, Object> response = createFullProfileResponse(profile);

        return ResponseEntity.ok(response);
    }

    /**
     * Search students (admin use)
     */
    @GetMapping("/students/search")
    public ResponseEntity<Map<String, Object>> searchStudents(@RequestParam(required = false) String query,
                                                             @RequestParam(required = false) String department,
                                                             HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        if (sessionToken == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "No valid session found")
            );
        }

        var sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
        if (sessionOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "Invalid or expired session")
            );
        }

        // TODO: Add role-based access control for admin endpoints

        List<StudentProfileService.StudentProfileData> students;
        
        if (department != null && !department.trim().isEmpty()) {
            students = studentProfileService.getStudentsByDepartment(department);
        } else if (query != null && !query.trim().isEmpty()) {
            students = studentProfileService.searchStudentsByName(query);
        } else {
            students = studentProfileService.getAllStudents();
        }

        List<Map<String, Object>> studentList = students.stream()
            .map(this::createSummaryProfileResponse)
            .toList();

        Map<String, Object> response = new HashMap<>();
        response.put("students", studentList);
        response.put("count", studentList.size());
        response.put("query", query);
        response.put("department", department);

        return ResponseEntity.ok(response);
    }

    /*------------------------- Data Validation Endpoints -------------------------*/

    /**
     * Validate student data consistency
     */
    @GetMapping("/student/{userId}/validate")
    public ResponseEntity<Map<String, Object>> validateStudentData(@PathVariable int userId,
                                                                  HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        if (sessionToken == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "No valid session found")
            );
        }

        var sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
        if (sessionOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "Invalid or expired session")
            );
        }

        Map<String, Object> validation = studentProfileService.validateStudentData(userId);
        return ResponseEntity.ok(validation);
    }

    /**
     * Get student statistics (admin use)
     */
    @GetMapping("/students/stats")
    public ResponseEntity<Map<String, Object>> getStudentStats(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        if (sessionToken == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "No valid session found")
            );
        }

        var sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
        if (sessionOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                Map.of("error", "Invalid or expired session")
            );
        }

        // TODO: Add role-based access control for admin endpoints

        Map<String, Long> counts = studentProfileService.getStudentCounts();
        return ResponseEntity.ok(Map.of("statistics", counts));
    }

    /*------------------------- Helper Methods -------------------------*/

    /**
     * Create full profile response for detailed views
     */
    private Map<String, Object> createFullProfileResponse(StudentProfileService.StudentProfileData profile) {
        Map<String, Object> response = new HashMap<>();
        
        // User information
        response.put("user_id", profile.getUser().getId());
        response.put("email", profile.getUser().getEmail());
        response.put("firstname", profile.getUser().getFirstname());
        response.put("lastname", profile.getUser().getLastname());
        response.put("preferred_name", profile.getUser().getPreferred_name());
        response.put("status", profile.getUser().getStatus());
        response.put("role", profile.getUser().getRole());
        response.put("phone", profile.getUser().getPhone());
        response.put("country_code", profile.getUser().getCountryCode());
        
        // Student information
        response.put("student_id", profile.getStudent().getId());
        response.put("campus_id", profile.getStudent().getCampusId());
        response.put("department", profile.getStudent().getDepartment());
        response.put("standing", profile.getStudent().getStanding());
        response.put("enrollment_status", profile.getStudent().getEnrollementStatus());
        response.put("gpa", profile.getStudent().getGpa());
        response.put("expected_graduation", profile.getStudent().getExpectedGraduation());
        response.put("created_at", profile.getStudent().getCreatedAt());
        response.put("updated_at", profile.getStudent().getUpdatedAt());
        
        return response;
    }

    /**
     * Create summary profile response for list views
     */
    private Map<String, Object> createSummaryProfileResponse(StudentProfileService.StudentProfileData profile) {
        Map<String, Object> response = new HashMap<>();
        
        response.put("user_id", profile.getUser().getId());
        response.put("student_id", profile.getStudent().getId());
        response.put("email", profile.getUser().getEmail());
        response.put("firstname", profile.getUser().getFirstname());
        response.put("lastname", profile.getUser().getLastname());
        response.put("preferred_name", profile.getUser().getPreferred_name());
        response.put("campus_id", profile.getStudent().getCampusId());
        response.put("department", profile.getStudent().getDepartment());
        response.put("standing", profile.getStudent().getStanding());
        response.put("gpa", profile.getStudent().getGpa());
        response.put("status", profile.getUser().getStatus());
        
        return response;
    }

    /**
     * Extract session token from cookie or Authorization header
     */
    private String extractSessionToken(HttpServletRequest request) {
        // First try to get from cookie (preferred for SSO)
        if (request.getCookies() != null) {
            for (var cookie : request.getCookies()) {
                if ("PAWS360_SESSION".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        
        // Fallback to Authorization header for API clients
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        
        // Fallback to X-Session-Token header
        return request.getHeader("X-Session-Token");
    }

    /**
     * Extract client IP address from request
     */
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }
}