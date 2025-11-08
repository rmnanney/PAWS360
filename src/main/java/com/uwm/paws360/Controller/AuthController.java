package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.AuthenticationSession;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Service.LoginService;
import com.uwm.paws360.Service.SessionManagementService;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Enhanced authentication controller with SSO session management for repository unification.
 * Supports seamless authentication between Spring Boot backend and Next.js frontend.
 */
@RestController
@RequestMapping("/auth")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    private final LoginService loginService;
    private final SessionManagementService sessionManagementService;
    
    // Cookie configuration for SSO
    private static final String SESSION_COOKIE_NAME = "PAWS360_SESSION";
    private static final int COOKIE_MAX_AGE = 3600; // 1 hour in seconds
    private static final boolean COOKIE_HTTP_ONLY = true;
    private static final boolean COOKIE_SECURE = false; // Set to true in production with HTTPS

    public AuthController(LoginService loginService, SessionManagementService sessionManagementService) {
        this.loginService = loginService;
        this.sessionManagementService = sessionManagementService;
    }

    /**
     * SSO Login endpoint that creates session cookies for cross-service authentication
     */
    @PostMapping("/login")
    public ResponseEntity<UserLoginResponseDTO> login(@Valid @RequestBody UserLoginRequestDTO loginDTO,
                                                    HttpServletRequest request, 
                                                    HttpServletResponse response) {
        String clientIp = getClientIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        
        logger.info("Login attempt for email: {} from IP: {}", 
            loginDTO.email() != null ? loginDTO.email().replaceAll("(.{3}).*(@.*)", "$1***$2") : "null", 
            clientIp);
        
        try {
            // Use existing login service for authentication
            UserLoginResponseDTO loginResponse = loginService.login(loginDTO);
            
            if (loginResponse.message().equals("Login Successful")) {
                // Create SSO session with additional context
                String serviceOrigin = request.getHeader("X-Service-Origin");
                if (serviceOrigin == null) {
                    serviceOrigin = "student-portal"; // Default for frontend requests
                }
                
                // Create or update SSO session
                Optional<Users> userOpt = loginService.validateSSOSession(loginResponse.session_token());
                if (userOpt.isPresent()) {
                    Users user = userOpt.get();
                    
                    sessionManagementService.createSession(
                        user,
                        loginResponse.session_token(),
                        clientIp,
                        userAgent,
                        serviceOrigin
                    );
                    
                    // Set HTTP-only session cookie for SSO
                    Cookie sessionCookie = new Cookie(SESSION_COOKIE_NAME, loginResponse.session_token());
                    sessionCookie.setHttpOnly(COOKIE_HTTP_ONLY);
                    sessionCookie.setMaxAge(COOKIE_MAX_AGE);
                    sessionCookie.setPath("/");
                    sessionCookie.setSecure(COOKIE_SECURE);
                    response.addCookie(sessionCookie);
                    
                    logger.info("Successful login for user ID: {} ({}), role: {}, from IP: {}", 
                        user.getId(), user.getEmail().replaceAll("(.{3}).*(@.*)", "$1***$2"), 
                        user.getRole(), clientIp);
                    
                    return ResponseEntity.ok(loginResponse);
                } else {
                    logger.warn("Login response indicated success but session validation failed for email: {}", 
                        loginDTO.email() != null ? loginDTO.email().replaceAll("(.{3}).*(@.*)", "$1***$2") : "null");
                }
            }
            
            // Handle authentication failures
            logger.warn("Failed login attempt for email: {} from IP: {} - {}", 
                loginDTO.email() != null ? loginDTO.email().replaceAll("(.{3}).*(@.*)", "$1***$2") : "null", 
                clientIp, loginResponse.message());
            
            if (loginResponse.message().contains("Locked")) {
                return ResponseEntity.status(HttpStatus.LOCKED).body(loginResponse);
            }
            
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(loginResponse);
            
        } catch (Exception e) {
            logger.error("Login error for email: {} from IP: {}: {}", 
                loginDTO.email() != null ? loginDTO.email().replaceAll("(.{3}).*(@.*)", "$1***$2") : "null", 
                clientIp, e.getMessage(), e);
            
            UserLoginResponseDTO errorResponse = new UserLoginResponseDTO(
                -1, null, null, null, null, null, null, null,
                "Authentication service temporarily unavailable"
            );
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Session validation endpoint for cross-service authentication
     */
    @GetMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateSession(HttpServletRequest request) {
        String clientIp = getClientIpAddress(request);
        String sessionToken = extractSessionToken(request);
        
        Map<String, Object> responseBody = new HashMap<>();
        
        try {
            if (sessionToken != null) {
                Optional<AuthenticationSession> sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
                
                if (sessionOpt.isPresent()) {
                    AuthenticationSession session = sessionOpt.get();
                    Users user = session.getUser();
                    
                    responseBody.put("valid", true);
                    responseBody.put("user_id", user.getId());
                    responseBody.put("email", user.getEmail());
                    responseBody.put("firstname", user.getFirstname());
                    responseBody.put("lastname", user.getLastname());
                    responseBody.put("role", user.getRole());
                    responseBody.put("status", user.getStatus());
                    responseBody.put("session_id", session.getSessionId());
                    responseBody.put("expires_at", session.getExpiresAt());
                    responseBody.put("service_origin", session.getServiceOrigin());
                    responseBody.put("last_accessed", session.getLastAccessed());
                    
                    logger.debug("Valid session validated for user ID: {} from IP: {}", 
                        user.getId(), clientIp);
                    
                    return ResponseEntity.ok(responseBody);
                } else {
                    logger.debug("Invalid or expired session token from IP: {}", clientIp);
                }
            } else {
                logger.debug("No session token provided from IP: {}", clientIp);
            }
            
            responseBody.put("valid", false);
            responseBody.put("message", "Invalid or expired session");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(responseBody);
            
        } catch (Exception e) {
            logger.error("Session validation error from IP: {}: {}", clientIp, e.getMessage(), e);
            
            responseBody.put("valid", false);
            responseBody.put("message", "Session validation service temporarily unavailable");
            responseBody.put("error_type", "SERVICE_ERROR");
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(responseBody);
        }
    }

    /**
     * Session extension endpoint for keeping sessions alive
     */
    @PostMapping("/extend")
    public ResponseEntity<Map<String, Object>> extendSession(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        Map<String, Object> responseBody = new HashMap<>();
        
        if (sessionToken != null) {
            boolean extended = sessionManagementService.extendSession(sessionToken, 1); // Extend by 1 hour
            
            if (extended) {
                responseBody.put("extended", true);
                responseBody.put("message", "Session extended successfully");
                return ResponseEntity.ok(responseBody);
            }
        }
        
        responseBody.put("extended", false);
        responseBody.put("message", "Failed to extend session");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(responseBody);
    }

    /**
     * Logout endpoint with comprehensive session cleanup
     */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, Object>> logout(HttpServletRequest request, 
                                                     HttpServletResponse response) {
        String sessionToken = extractSessionToken(request);
        
        Map<String, Object> responseBody = new HashMap<>();
        
        try {
            if (sessionToken != null) {
                // Use SessionManagementService to invalidate session
                boolean loggedOut = sessionManagementService.invalidateSession(sessionToken, "manual_logout");
                
                // Clear session cookie
                Cookie sessionCookie = new Cookie(SESSION_COOKIE_NAME, "");
                sessionCookie.setHttpOnly(COOKIE_HTTP_ONLY);
                sessionCookie.setMaxAge(0); // Delete cookie
                sessionCookie.setPath("/");
                sessionCookie.setSecure(COOKIE_SECURE);
                response.addCookie(sessionCookie);
                
                responseBody.put("logged_out", loggedOut);
                responseBody.put("message", loggedOut ? "Logout successful" : "Session not found");
                
                return ResponseEntity.ok(responseBody);
            }
            
            responseBody.put("logged_out", false);
            responseBody.put("message", "No active session found");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(responseBody);
        } catch (Exception e) {
            responseBody.put("logged_out", false);
            responseBody.put("message", "Logout failed: " + e.getMessage());
            responseBody.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(responseBody);
        }
    }

    /**
     * Get current user session information
     */
    @GetMapping("/session")
    public ResponseEntity<Map<String, Object>> getSessionInfo(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        Map<String, Object> responseBody = new HashMap<>();
        
        if (sessionToken != null) {
            Optional<AuthenticationSession> sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
            
            if (sessionOpt.isPresent()) {
                AuthenticationSession session = sessionOpt.get();
                Users user = session.getUser();
                
                responseBody.put("session_id", session.getSessionId());
                responseBody.put("user_id", user.getId());
                responseBody.put("email", user.getEmail());
                responseBody.put("role", user.getRole());
                responseBody.put("created_at", session.getCreatedAt());
                responseBody.put("expires_at", session.getExpiresAt());
                responseBody.put("last_accessed", session.getLastAccessed());
                responseBody.put("service_origin", session.getServiceOrigin());
                responseBody.put("ip_address", session.getIpAddress());
                
                return ResponseEntity.ok(responseBody);
            }
        }
        
        responseBody.put("message", "No valid session found");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(responseBody);
    }

    /**
     * Health check endpoint for monitoring
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> responseBody = new HashMap<>();
        
        boolean healthy = sessionManagementService.isSessionRepositoryHealthy();
        long activeSessions = sessionManagementService.getActiveSessionsCount();
        
        responseBody.put("status", healthy ? "UP" : "DOWN");
        responseBody.put("active_sessions", activeSessions);
        responseBody.put("service", "AuthController");
        responseBody.put("sso_enabled", true);
        
        return ResponseEntity.ok(responseBody);
    }

    /*------------------------- Admin Role Authentication -------------------------*/

    /**
     * Admin-specific session validation endpoint with role-based access control
     */
    @GetMapping("/validate/admin")
    public ResponseEntity<Map<String, Object>> validateAdminSession(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        Map<String, Object> responseBody = new HashMap<>();
        
        if (sessionToken != null) {
            Optional<AuthenticationSession> sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
            
            if (sessionOpt.isPresent()) {
                AuthenticationSession session = sessionOpt.get();
                Users user = session.getUser();
                
                // Check if user has admin privileges
                if (hasAdminRole(user)) {
                    responseBody.put("valid", true);
                    responseBody.put("user_id", user.getId());
                    responseBody.put("email", user.getEmail());
                    responseBody.put("firstname", user.getFirstname());
                    responseBody.put("lastname", user.getLastname());
                    responseBody.put("role", user.getRole().toString());
                    responseBody.put("admin_level", getAdminLevel(user));
                    responseBody.put("session_id", session.getSessionId());
                    responseBody.put("service_origin", session.getServiceOrigin());
                    responseBody.put("expires_at", session.getExpiresAt());
                    responseBody.put("last_accessed", session.getLastAccessed());
                    
                    return ResponseEntity.ok(responseBody);
                } else {
                    responseBody.put("valid", false);
                    responseBody.put("error", "Insufficient privileges");
                    responseBody.put("required_role", "Administrator or Super_Administrator");
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(responseBody);
                }
            }
        }
        
        responseBody.put("valid", false);
        responseBody.put("error", "Invalid or expired session");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(responseBody);
    }

    /**
     * Get current admin user information
     */
    @GetMapping("/admin/profile")
    public ResponseEntity<Map<String, Object>> getAdminProfile(HttpServletRequest request) {
        String sessionToken = extractSessionToken(request);
        
        Map<String, Object> responseBody = new HashMap<>();
        
        if (sessionToken != null) {
            Optional<AuthenticationSession> sessionOpt = sessionManagementService.validateAndRefreshSession(sessionToken);
            
            if (sessionOpt.isPresent()) {
                AuthenticationSession session = sessionOpt.get();
                Users user = session.getUser();
                
                // Verify admin role
                if (hasAdminRole(user)) {
                    responseBody.put("user_id", user.getId());
                    responseBody.put("email", user.getEmail());
                    responseBody.put("firstname", user.getFirstname());
                    responseBody.put("lastname", user.getLastname());
                    responseBody.put("role", user.getRole().toString());
                    responseBody.put("admin_level", getAdminLevel(user));
                    responseBody.put("permissions", getAdminPermissions(user));
                    responseBody.put("status", user.getStatus());
                    responseBody.put("phone", user.getPhone());
                    responseBody.put("country_code", user.getCountryCode());
                    responseBody.put("session_info", Map.of(
                        "session_id", session.getSessionId(),
                        "service_origin", session.getServiceOrigin(),
                        "ip_address", session.getIpAddress(),
                        "expires_at", session.getExpiresAt(),
                        "last_accessed", session.getLastAccessed()
                    ));
                    
                    return ResponseEntity.ok(responseBody);
                } else {
                    responseBody.put("error", "Access denied: Admin privileges required");
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(responseBody);
                }
            }
        }
        
        responseBody.put("error", "Authentication required");
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(responseBody);
    }

    /*------------------------- Helper Methods -------------------------*/

    /**
     * Check if user has admin role privileges
     */
    private boolean hasAdminRole(Users user) {
        if (user == null || user.getRole() == null) {
            return false;
        }
        return user.getRole().toString().equals("Administrator") || 
               user.getRole().toString().equals("Super_Administrator");
    }

    /**
     * Get admin level description based on role
     */
    private String getAdminLevel(Users user) {
        if (user == null || user.getRole() == null) {
            return "NONE";
        }
        
        switch (user.getRole().toString()) {
            case "Administrator":
                return "ADMIN";
            case "Super_Administrator":
                return "SUPER_ADMIN";
            default:
                return "NONE";
        }
    }

    /**
     * Get admin permissions based on role
     */
    private java.util.List<String> getAdminPermissions(Users user) {
        java.util.List<String> permissions = new java.util.ArrayList<>();
        
        if (user == null || user.getRole() == null) {
            return permissions;
        }
        
        String role = user.getRole().toString();
        
        if ("Administrator".equals(role) || "Super_Administrator".equals(role)) {
            permissions.add("VIEW_STUDENTS");
            permissions.add("SEARCH_STUDENTS");
            permissions.add("VIEW_STUDENT_DETAILS");
            permissions.add("VIEW_ACADEMIC_RECORDS");
            permissions.add("VIEW_FINANCIAL_RECORDS");
            permissions.add("GENERATE_REPORTS");
        }
        
        if ("Super_Administrator".equals(role)) {
            permissions.add("MODIFY_STUDENT_RECORDS");
            permissions.add("DELETE_STUDENT_RECORDS");
            permissions.add("MANAGE_USERS");
            permissions.add("SYSTEM_ADMINISTRATION");
            permissions.add("SECURITY_MANAGEMENT");
        }
        
        return permissions;
    }

    /**
     * Extract session token from cookie or Authorization header
     */
    private String extractSessionToken(HttpServletRequest request) {
        // First try to get from cookie (preferred for SSO)
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if (SESSION_COOKIE_NAME.equals(cookie.getName())) {
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