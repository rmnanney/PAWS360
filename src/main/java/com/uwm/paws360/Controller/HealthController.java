package com.uwm.paws360.Controller;

import com.uwm.paws360.Service.HealthCheckService;
import com.uwm.paws360.Service.SessionManagementService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Health check controller with detailed status for demo environment monitoring.
 * Provides comprehensive health endpoints for system validation.
 */
@RestController
@RequestMapping("/health")
public class HealthController {

    private final HealthCheckService healthCheckService;
    private final SessionManagementService sessionManagementService;

    public HealthController(HealthCheckService healthCheckService,
                          SessionManagementService sessionManagementService) {
        this.healthCheckService = healthCheckService;
        this.sessionManagementService = sessionManagementService;
    }

    /*------------------------- Health Check Endpoints -------------------------*/

    /**
     * Comprehensive system health check
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSystemHealth() {
        try {
            Map<String, Object> healthStatus = healthCheckService.performComprehensiveHealthCheck();
            boolean isHealthy = (Boolean) healthStatus.get("overall_healthy");
            
            if (isHealthy) {
                return ResponseEntity.ok(healthStatus);
            } else {
                return ResponseEntity.status(503).body(healthStatus); // Service Unavailable
            }
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "DOWN");
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    /**
     * Quick readiness check for startup validation
     */
    @GetMapping("/ready")
    public ResponseEntity<Map<String, Object>> isSystemReady() {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        
        try {
            boolean ready = healthCheckService.isSystemReady();
            response.put("ready", ready);
            response.put("status", ready ? "UP" : "DOWN");
            
            if (ready) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(503).body(response);
            }
        } catch (Exception e) {
            response.put("ready", false);
            response.put("status", "DOWN");
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Demo environment readiness check
     */
    @GetMapping("/demo/ready")
    public ResponseEntity<Map<String, Object>> isDemoReady() {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        
        try {
            boolean demoReady = healthCheckService.isDemoReady();
            response.put("demo_ready", demoReady);
            response.put("status", demoReady ? "READY" : "NOT_READY");
            
            if (demoReady) {
                response.put("message", "Demo environment is ready for demonstration");
                return ResponseEntity.ok(response);
            } else {
                response.put("message", "Demo environment requires setup - missing demo accounts");
                return ResponseEntity.status(412).body(response); // Precondition Failed
            }
        } catch (Exception e) {
            response.put("demo_ready", false);
            response.put("status", "ERROR");
            response.put("error", e.getMessage());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Performance metrics for system monitoring
     */
    @GetMapping("/metrics")
    public ResponseEntity<Map<String, Object>> getPerformanceMetrics() {
        try {
            Map<String, Object> metrics = healthCheckService.getPerformanceMetrics();
            return ResponseEntity.ok(metrics);
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    /**
     * Database-specific health check
     */
    @GetMapping("/database")
    public ResponseEntity<Map<String, Object>> getDatabaseHealth() {
        try {
            Map<String, Object> fullHealth = healthCheckService.performComprehensiveHealthCheck();
            Map<String, Object> dbHealth = (Map<String, Object>) fullHealth.get("database");
            
            boolean healthy = (Boolean) dbHealth.get("healthy");
            if (healthy) {
                return ResponseEntity.ok(dbHealth);
            } else {
                return ResponseEntity.status(503).body(dbHealth);
            }
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("healthy", false);
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    /**
     * Authentication system health check
     */
    @GetMapping("/authentication")
    public ResponseEntity<Map<String, Object>> getAuthenticationHealth() {
        try {
            Map<String, Object> fullHealth = healthCheckService.performComprehensiveHealthCheck();
            Map<String, Object> authHealth = (Map<String, Object>) fullHealth.get("authentication");
            
            boolean healthy = (Boolean) authHealth.get("healthy");
            if (healthy) {
                return ResponseEntity.ok(authHealth);
            } else {
                return ResponseEntity.status(503).body(authHealth);
            }
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("healthy", false);
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    /**
     * Session management health check
     */
    @GetMapping("/sessions")
    public ResponseEntity<Map<String, Object>> getSessionHealth() {
        try {
            Map<String, Object> fullHealth = healthCheckService.performComprehensiveHealthCheck();
            Map<String, Object> sessionHealth = (Map<String, Object>) fullHealth.get("session_management");
            
            // Add real-time session statistics
            sessionHealth.put("current_active_sessions", sessionManagementService.getActiveSessionsCount());
            sessionHealth.put("session_stats_by_service", sessionManagementService.getSessionStatsByService());
            
            boolean healthy = (Boolean) sessionHealth.get("healthy");
            if (healthy) {
                return ResponseEntity.ok(sessionHealth);
            } else {
                return ResponseEntity.status(503).body(sessionHealth);
            }
        } catch (Exception e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("healthy", false);
            errorResponse.put("error", e.getMessage());
            errorResponse.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    /*------------------------- Demo-Specific Endpoints -------------------------*/

    /**
     * Complete demo environment validation
     */
    @GetMapping("/demo/validate")
    public ResponseEntity<Map<String, Object>> validateDemoEnvironment() {
        Map<String, Object> validation = new HashMap<>();
        validation.put("timestamp", LocalDateTime.now());
        
        try {
            // Perform comprehensive health check
            Map<String, Object> healthStatus = healthCheckService.performComprehensiveHealthCheck();
            
            // Extract key validation points
            Map<String, Object> dbHealth = (Map<String, Object>) healthStatus.get("database");
            Map<String, Object> authHealth = (Map<String, Object>) healthStatus.get("authentication");
            Map<String, Object> demoDataHealth = (Map<String, Object>) healthStatus.get("demo_data");
            Map<String, Object> sessionHealth = (Map<String, Object>) healthStatus.get("session_management");
            
            // Demo-specific validations
            validation.put("database_ready", dbHealth.get("healthy"));
            validation.put("authentication_ready", authHealth.get("healthy"));
            validation.put("demo_accounts_available", authHealth.get("demo_accounts_ready"));
            validation.put("demo_data_consistent", demoDataHealth.get("healthy"));
            validation.put("session_management_ready", sessionHealth.get("healthy"));
            
            // Overall demo readiness
            boolean overallReady = (Boolean) healthStatus.get("overall_healthy") && 
                                 (Boolean) authHealth.get("demo_accounts_ready");
            
            validation.put("demo_environment_ready", overallReady);
            validation.put("status", overallReady ? "READY" : "NOT_READY");
            
            if (overallReady) {
                validation.put("message", "Demo environment fully validated and ready for use");
                return ResponseEntity.ok(validation);
            } else {
                validation.put("message", "Demo environment requires attention before demonstration");
                validation.put("detailed_status", healthStatus);
                return ResponseEntity.status(412).body(validation);
            }
            
        } catch (Exception e) {
            validation.put("demo_environment_ready", false);
            validation.put("status", "ERROR");
            validation.put("error", e.getMessage());
            return ResponseEntity.status(500).body(validation);
        }
    }

    /**
     * Simple ping endpoint for basic connectivity testing
     */
    @GetMapping("/ping")
    public ResponseEntity<Map<String, Object>> ping() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "paws360-auth-service");
        response.put("timestamp", LocalDateTime.now());
        response.put("message", "Service is responding");
        return ResponseEntity.ok(response);
    }
}