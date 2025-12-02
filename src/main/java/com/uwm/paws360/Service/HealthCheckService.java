package com.uwm.paws360.Service;

import com.uwm.paws360.JPARepository.User.UserRepository;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Service for comprehensive health checks and system validation.
 * Provides detailed health status for demo environment monitoring.
 */
@Service
public class HealthCheckService {

    private final DataSource dataSource;
    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final SessionManagementService sessionManagementService;

    public HealthCheckService(DataSource dataSource,
                            UserRepository userRepository,
                            StudentRepository studentRepository,
                            SessionManagementService sessionManagementService) {
        this.dataSource = dataSource;
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.sessionManagementService = sessionManagementService;
    }

    /*------------------------- Comprehensive Health Check -------------------------*/

    @Transactional(readOnly = true)
    public Map<String, Object> performComprehensiveHealthCheck() {
        Map<String, Object> healthStatus = new HashMap<>();
        healthStatus.put("timestamp", LocalDateTime.now());
        healthStatus.put("service", "paws360-auth-service");
        
        // Database connectivity and performance
        Map<String, Object> databaseHealth = checkDatabaseHealth();
        healthStatus.put("database", databaseHealth);
        
        // Authentication system health
        Map<String, Object> authHealth = checkAuthenticationHealth();
        healthStatus.put("authentication", authHealth);
        
        // Demo data integrity
        Map<String, Object> demoDataHealth = checkDemoDataHealth();
        healthStatus.put("demo_data", demoDataHealth);
        
        // Session management health
        Map<String, Object> sessionHealth = checkSessionHealth();
        healthStatus.put("session_management", sessionHealth);
        
        // Overall health calculation
        boolean overallHealthy = (Boolean) databaseHealth.get("healthy") &&
                               (Boolean) authHealth.get("healthy") &&
                               (Boolean) demoDataHealth.get("healthy") &&
                               (Boolean) sessionHealth.get("healthy");
        
        healthStatus.put("overall_healthy", overallHealthy);
        healthStatus.put("status", overallHealthy ? "UP" : "DOWN");
        
        return healthStatus;
    }

    /*------------------------- Database Health Checks -------------------------*/

    private Map<String, Object> checkDatabaseHealth() {
        Map<String, Object> dbHealth = new HashMap<>();
        
        try {
            long startTime = System.currentTimeMillis();
            
            // Test basic connectivity
            try (Connection connection = dataSource.getConnection()) {
                dbHealth.put("connected", true);
                
                // Test query performance
                try (PreparedStatement stmt = connection.prepareStatement("SELECT 1")) {
                    try (ResultSet rs = stmt.executeQuery()) {
                        rs.next();
                        long queryTime = System.currentTimeMillis() - startTime;
                        dbHealth.put("query_time_ms", queryTime);
                        dbHealth.put("query_performance", queryTime < 100 ? "GOOD" : queryTime < 500 ? "FAIR" : "SLOW");
                    }
                }
                
                // Test table existence and row counts
                Map<String, Integer> tableCounts = getTableCounts(connection);
                dbHealth.put("table_counts", tableCounts);
                
                // Database version info
                try (PreparedStatement stmt = connection.prepareStatement("SELECT version()")) {
                    try (ResultSet rs = stmt.executeQuery()) {
                        if (rs.next()) {
                            dbHealth.put("version", rs.getString(1));
                        }
                    }
                }
            }
            
            dbHealth.put("healthy", true);
            dbHealth.put("status", "UP");
            
        } catch (Exception e) {
            dbHealth.put("healthy", false);
            dbHealth.put("status", "DOWN");
            dbHealth.put("error", e.getMessage());
            dbHealth.put("connected", false);
        }
        
        return dbHealth;
    }

    private Map<String, Integer> getTableCounts(Connection connection) {
        Map<String, Integer> counts = new HashMap<>();
        String[] tables = {"users", "student", "authentication_session"};
        
        for (String table : tables) {
            try (PreparedStatement stmt = connection.prepareStatement(
                "SELECT COUNT(*) FROM " + table)) {
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        counts.put(table, rs.getInt(1));
                    }
                }
            } catch (Exception e) {
                counts.put(table + "_error", -1);
            }
        }
        
        return counts;
    }

    /*------------------------- Authentication Health Checks -------------------------*/

    private Map<String, Object> checkAuthenticationHealth() {
        Map<String, Object> authHealth = new HashMap<>();
        
        try {
            // Check user repository accessibility
            long userCount = userRepository.count();
            authHealth.put("user_count", userCount);
            authHealth.put("user_repository_accessible", true);
            
            // Check for demo accounts
            boolean studentDemoExists = userRepository.findUsersByEmailIgnoreCase("demo.student@uwm.edu") != null;
            boolean adminDemoExists = userRepository.findUsersByEmailIgnoreCase("demo.admin@uwm.edu") != null;
            
            authHealth.put("demo_student_exists", studentDemoExists);
            authHealth.put("demo_admin_exists", adminDemoExists);
            authHealth.put("demo_accounts_ready", studentDemoExists && adminDemoExists);
            
            // Check authentication service health
            authHealth.put("service_initialized", true);
            
            authHealth.put("healthy", userCount > 0 && studentDemoExists);
            authHealth.put("status", authHealth.get("healthy").equals(true) ? "UP" : "DOWN");
            
        } catch (Exception e) {
            authHealth.put("healthy", false);
            authHealth.put("status", "DOWN");
            authHealth.put("error", e.getMessage());
            authHealth.put("user_repository_accessible", false);
        }
        
        return authHealth;
    }

    /*------------------------- Demo Data Health Checks -------------------------*/

    private Map<String, Object> checkDemoDataHealth() {
        Map<String, Object> demoHealth = new HashMap<>();
        
        try {
            // Check student data integrity
            long studentCount = studentRepository.count();
            demoHealth.put("student_count", studentCount);
            
            // Check for demo student profile
            var demoStudent = userRepository.findUsersByEmailIgnoreCase("demo.student@uwm.edu");
            if (demoStudent != null) {
                var studentProfile = studentRepository.findByUser(demoStudent);
                demoHealth.put("demo_student_profile_exists", studentProfile.isPresent());
                
                if (studentProfile.isPresent()) {
                    var student = studentProfile.get();
                    demoHealth.put("demo_student_has_campus_id", student.getCampusId() != null);
                    demoHealth.put("demo_student_has_department", student.getDepartment() != null);
                    demoHealth.put("demo_student_has_gpa", student.getGpa() != null);
                }
            } else {
                demoHealth.put("demo_student_profile_exists", false);
            }
            
            // Data consistency checks
            boolean dataConsistent = studentCount > 0 && demoStudent != null;
            demoHealth.put("data_consistent", dataConsistent);
            
            demoHealth.put("healthy", dataConsistent);
            demoHealth.put("status", dataConsistent ? "UP" : "DOWN");
            
        } catch (Exception e) {
            demoHealth.put("healthy", false);
            demoHealth.put("status", "DOWN");
            demoHealth.put("error", e.getMessage());
        }
        
        return demoHealth;
    }

    /*------------------------- Session Health Checks -------------------------*/

    private Map<String, Object> checkSessionHealth() {
        Map<String, Object> sessionHealth = new HashMap<>();
        
        try {
            // Check session management service
            long activeSessions = sessionManagementService.getActiveSessionsCount();
            sessionHealth.put("active_sessions", activeSessions);
            
            // Check session cleanup functionality
            sessionManagementService.cleanupExpiredSessions();
            sessionHealth.put("cleanup_executed", true);
            
            // Session service health
            sessionHealth.put("service_operational", true);
            sessionHealth.put("healthy", true);
            sessionHealth.put("status", "UP");
            
        } catch (Exception e) {
            sessionHealth.put("healthy", false);
            sessionHealth.put("status", "DOWN");
            sessionHealth.put("error", e.getMessage());
            sessionHealth.put("service_operational", false);
        }
        
        return sessionHealth;
    }

    /*------------------------- Quick Health Checks -------------------------*/

    /**
     * Quick health check for startup validation
     */
    public boolean isSystemReady() {
        try {
            // Quick database ping
            try (Connection connection = dataSource.getConnection()) {
                try (PreparedStatement stmt = connection.prepareStatement("SELECT 1")) {
                    stmt.executeQuery();
                }
            }
            
            // Quick authentication check
            long userCount = userRepository.count();
            
            return userCount > 0;
            
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Check if demo environment is ready for demonstration
     */
    public boolean isDemoReady() {
        try {
            var demoStudent = userRepository.findUsersByEmailIgnoreCase("demo.student@uwm.edu");
            var demoAdmin = userRepository.findUsersByEmailIgnoreCase("demo.admin@uwm.edu");
            
            return demoStudent != null && demoAdmin != null;
            
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Get system performance metrics
     */
    public Map<String, Object> getPerformanceMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        
        try {
            long startTime = System.currentTimeMillis();
            
            // Database performance
            try (Connection connection = dataSource.getConnection()) {
                try (PreparedStatement stmt = connection.prepareStatement("SELECT COUNT(*) FROM users")) {
                    stmt.executeQuery();
                }
            }
            long dbQueryTime = System.currentTimeMillis() - startTime;
            
            metrics.put("db_query_time_ms", dbQueryTime);
            metrics.put("active_sessions", sessionManagementService.getActiveSessionsCount());
            metrics.put("total_users", userRepository.count());
            metrics.put("total_students", studentRepository.count());
            metrics.put("timestamp", LocalDateTime.now());
            
        } catch (Exception e) {
            metrics.put("error", e.getMessage());
        }
        
        return metrics;
    }
}