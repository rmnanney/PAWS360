package com.uwm.paws360.Controller;

import com.uwm.paws360.Service.DemoDataService;
import com.uwm.paws360.Service.HealthCheckService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Demo controller for managing demo environment setup, data reset, and validation.
 * Provides endpoints for demo facilitators to prepare and maintain demo environments.
 */
@RestController
@RequestMapping("/demo")
public class DemoController {

    private static final Logger logger = LoggerFactory.getLogger(DemoController.class);

    @Autowired
    private DemoDataService demoDataService;

    @Autowired
    private HealthCheckService healthCheckService;

    /*------------------------- Demo Data Management -------------------------*/

    /**
     * Reset demo data to baseline state for consistent demo execution.
     * This operation truncates all user-related data and reloads demo seed data.
     */
    @PostMapping("/reset")
    public ResponseEntity<Map<String, Object>> resetDemoData() {
        logger.info("Demo data reset requested");
        
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("operation", "demo_data_reset");
        
        try {
            DemoDataService.DemoResetResult result = demoDataService.resetDemoData();
            
            response.put("success", result.isSuccess());
            response.put("message", result.getMessage());
            
            if (result.getValidation() != null) {
                response.put("validation", Map.of(
                    "valid", result.getValidation().isValid(),
                    "errors", result.getValidation().getErrors()
                ));
            }
            
            if (result.isSuccess()) {
                logger.info("Demo data reset completed successfully");
                return ResponseEntity.ok(response);
            } else {
                logger.error("Demo data reset failed: {}", result.getMessage());
                return ResponseEntity.status(500).body(response);
            }
            
        } catch (Exception e) {
            logger.error("Demo data reset operation failed", e);
            response.put("success", false);
            response.put("message", "Demo data reset failed: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Validate current demo data integrity and consistency.
     */
    @GetMapping("/validate")
    public ResponseEntity<Map<String, Object>> validateDemoData() {
        logger.info("Demo data validation requested");
        
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("operation", "demo_data_validation");
        
        try {
            DemoDataService.DemoDataValidation validation = demoDataService.validateDemoData();
            
            response.put("valid", validation.isValid());
            response.put("errors", validation.getErrors());
            response.put("error_count", validation.getErrors().size());
            
            if (validation.isValid()) {
                response.put("message", "Demo data validation passed - all checks successful");
                logger.info("Demo data validation passed");
                return ResponseEntity.ok(response);
            } else {
                response.put("message", "Demo data validation failed - issues found");
                logger.warn("Demo data validation failed with {} errors", validation.getErrors().size());
                return ResponseEntity.status(412).body(response); // Precondition Failed
            }
            
        } catch (Exception e) {
            logger.error("Demo data validation operation failed", e);
            response.put("valid", false);
            response.put("message", "Demo data validation failed: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Get current demo environment status and statistics.
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getDemoStatus() {
        logger.debug("Demo status requested");
        
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("operation", "demo_status");
        
        try {
            DemoDataService.DemoStatusInfo status = demoDataService.getDemoStatus();
            
            response.put("healthy", status.isHealthy());
            response.put("total_users", status.getTotalUsers());
            response.put("total_students", status.getTotalStudents());
            response.put("total_administrators", status.getTotalAdministrators());
            response.put("demo_accounts", status.getDemoAccounts());
            response.put("data_valid", status.isDataValid());
            response.put("validation_errors", status.getValidationErrors());
            
            if (status.isHealthy() && status.isDataValid()) {
                response.put("message", "Demo environment is healthy and ready");
                return ResponseEntity.ok(response);
            } else {
                response.put("message", "Demo environment requires attention");
                return ResponseEntity.status(412).body(response);
            }
            
        } catch (Exception e) {
            logger.error("Demo status retrieval failed", e);
            response.put("healthy", false);
            response.put("message", "Demo status retrieval failed: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(response);
        }
    }

    /*------------------------- Demo Environment Management -------------------------*/

    /**
     * Comprehensive demo environment readiness check.
     * Validates both infrastructure health and demo data consistency.
     */
    @GetMapping("/ready")
    public ResponseEntity<Map<String, Object>> isDemoReady() {
        logger.info("Demo readiness check requested");
        
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("operation", "demo_readiness_check");
        
        try {
            // Check infrastructure health
            Map<String, Object> healthStatus = healthCheckService.performComprehensiveHealthCheck();
            boolean infrastructureHealthy = (Boolean) healthStatus.get("overall_healthy");
            
            // Check demo data integrity
            DemoDataService.DemoDataValidation validation = demoDataService.validateDemoData();
            boolean dataValid = validation.isValid();
            
            // Check demo accounts availability
            DemoDataService.DemoStatusInfo status = demoDataService.getDemoStatus();
            boolean demoAccountsReady = status.getDemoAccounts().size() >= 2; // At least admin + student
            
            // Overall readiness assessment
            boolean overallReady = infrastructureHealthy && dataValid && demoAccountsReady;
            
            response.put("infrastructure_healthy", infrastructureHealthy);
            response.put("data_valid", dataValid);
            response.put("demo_accounts_ready", demoAccountsReady);
            response.put("overall_ready", overallReady);
            
            // Detailed status information
            response.put("infrastructure_status", healthStatus);
            response.put("data_validation", Map.of(
                "valid", validation.isValid(),
                "errors", validation.getErrors()
            ));
            response.put("demo_status", Map.of(
                "total_users", status.getTotalUsers(),
                "demo_accounts", status.getDemoAccounts()
            ));
            
            if (overallReady) {
                response.put("message", "Demo environment is fully ready for demonstration");
                logger.info("Demo environment readiness check passed");
                return ResponseEntity.ok(response);
            } else {
                response.put("message", "Demo environment requires setup before demonstration");
                logger.warn("Demo environment readiness check failed");
                return ResponseEntity.status(412).body(response);
            }
            
        } catch (Exception e) {
            logger.error("Demo readiness check failed", e);
            response.put("overall_ready", false);
            response.put("message", "Demo readiness check failed: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(response);
        }
    }

    /**
     * Quick setup validation for demo preparation scripts.
     */
    @GetMapping("/setup/validate")
    public ResponseEntity<Map<String, Object>> validateDemoSetup() {
        logger.info("Demo setup validation requested");
        
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("operation", "demo_setup_validation");
        
        try {
            // Check if basic infrastructure is available
            boolean dbReady = healthCheckService.isSystemReady();
            
            // Check if demo data needs initialization
            DemoDataService.DemoStatusInfo status = demoDataService.getDemoStatus();
            boolean hasUsers = status.getTotalUsers() > 0;
            boolean hasValidData = status.isDataValid();
            
            response.put("database_ready", dbReady);
            response.put("has_users", hasUsers);
            response.put("data_valid", hasValidData);
            response.put("requires_reset", hasUsers && !hasValidData);
            response.put("requires_initialization", !hasUsers);
            
            String recommendedAction;
            if (!dbReady) {
                recommendedAction = "Wait for database to be ready";
            } else if (!hasUsers) {
                recommendedAction = "Initialize demo data";
            } else if (!hasValidData) {
                recommendedAction = "Reset demo data to fix validation issues";
            } else {
                recommendedAction = "Demo setup is complete";
            }
            
            response.put("recommended_action", recommendedAction);
            response.put("setup_complete", dbReady && hasUsers && hasValidData);
            
            if (dbReady) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(503).body(response); // Service Unavailable
            }
            
        } catch (Exception e) {
            logger.error("Demo setup validation failed", e);
            response.put("setup_complete", false);
            response.put("recommended_action", "Check system logs for errors");
            response.put("message", "Demo setup validation failed: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(response);
        }
    }

    /*------------------------- Demo Account Management -------------------------*/

    /**
     * List available demo accounts for testing purposes.
     */
    @GetMapping("/accounts")
    public ResponseEntity<Map<String, Object>> listDemoAccounts() {
        logger.debug("Demo accounts list requested");
        
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("operation", "list_demo_accounts");
        
        try {
            DemoDataService.DemoStatusInfo status = demoDataService.getDemoStatus();
            
            response.put("demo_accounts", status.getDemoAccounts());
            response.put("total_count", status.getDemoAccounts().size());
            response.put("has_admin", status.getTotalAdministrators() > 0);
            response.put("has_students", status.getTotalStudents() > 0);
            
            // Demo credentials note (password is always 'password' for demo accounts)
            response.put("note", "All demo accounts use password 'password'");
            response.put("test_credentials", Map.of(
                "admin", "admin@uwm.edu / password",
                "student", "john.smith@uwm.edu / password"
            ));
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            logger.error("Demo accounts listing failed", e);
            response.put("message", "Demo accounts listing failed: " + e.getMessage());
            response.put("error", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(response);
        }
    }

    /*------------------------- Utility Endpoints -------------------------*/

    /**
     * Simple ping endpoint for demo controller availability.
     */
    @GetMapping("/ping")
    public ResponseEntity<Map<String, Object>> ping() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "paws360-demo-controller");
        response.put("timestamp", LocalDateTime.now());
        response.put("message", "Demo controller is responding");
        return ResponseEntity.ok(response);
    }

    /**
     * Get demo controller information and available operations.
     */
    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> getDemoInfo() {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now());
        response.put("controller", "DemoController");
        response.put("version", "1.0.0");
        response.put("purpose", "Demo environment management and data reset functionality");
        
        response.put("available_endpoints", Map.of(
            "POST /demo/reset", "Reset demo data to baseline state",
            "GET /demo/validate", "Validate demo data integrity",
            "GET /demo/status", "Get demo environment status",
            "GET /demo/ready", "Check demo environment readiness",
            "GET /demo/setup/validate", "Validate demo setup requirements",
            "GET /demo/accounts", "List available demo accounts",
            "GET /demo/ping", "Simple health check",
            "GET /demo/info", "This endpoint"
        ));
        
        response.put("demo_requirements", Map.of(
            "database", "PostgreSQL with PAWS360 schema",
            "demo_accounts", "At least 1 admin and 1 student account",
            "demo_password", "password for all demo accounts"
        ));
        
        return ResponseEntity.ok(response);
    }
}