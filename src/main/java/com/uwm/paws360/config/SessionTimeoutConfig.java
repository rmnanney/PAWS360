package com.uwm.paws360.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.uwm.paws360.Service.SessionManagementService;

/**
 * Session timeout and cleanup configuration for PAWS360 application.
 * Provides automated session management and timeout handling.
 */
@Configuration
@EnableScheduling
@Component
public class SessionTimeoutConfig {

    private static final Logger logger = LoggerFactory.getLogger(SessionTimeoutConfig.class);

    private final SessionManagementService sessionManagementService;

    @Value("${paws360.demo.authentication.session-timeout:3600s}")
    private String sessionTimeoutDuration;

    @Value("${paws360.demo.authentication.max-sessions:100}")
    private int maxSessions;

    public SessionTimeoutConfig(SessionManagementService sessionManagementService) {
        this.sessionManagementService = sessionManagementService;
    }

    /**
     * Scheduled task to clean up expired sessions
     * Runs every 5 minutes to remove expired sessions
     */
    @Scheduled(fixedRate = 300000) // 5 minutes
    public void cleanupExpiredSessions() {
        try {
            logger.debug("Starting scheduled session cleanup");
            
            long activeSessionsBefore = sessionManagementService.getActiveSessionsCount();
            sessionManagementService.cleanupExpiredSessions();
            long activeSessionsAfter = sessionManagementService.getActiveSessionsCount();
            
            long cleanedSessions = activeSessionsBefore - activeSessionsAfter;
            
            if (cleanedSessions > 0) {
                logger.info("Session cleanup completed: {} expired sessions removed, {} active sessions remaining", 
                    cleanedSessions, activeSessionsAfter);
            } else {
                logger.debug("Session cleanup completed: no expired sessions found, {} active sessions", 
                    activeSessionsAfter);
            }
            
            // Log warning if approaching session limit
            if (activeSessionsAfter > maxSessions * 0.8) {
                logger.warn("High session count: {} active sessions (limit: {})", 
                    activeSessionsAfter, maxSessions);
            }
            
        } catch (Exception e) {
            logger.error("Error during scheduled session cleanup: {}", e.getMessage(), e);
        }
    }

    /**
     * Scheduled task to log session statistics
     * Runs every 15 minutes for demo monitoring
     */
    @Scheduled(fixedRate = 900000) // 15 minutes
    public void logSessionStatistics() {
        try {
            long activeSessions = sessionManagementService.getActiveSessionsCount();
            logger.info("Session statistics: {} active sessions (max: {})", activeSessions, maxSessions);
            
            if (activeSessions >= maxSessions) {
                logger.error("Session limit reached: {} sessions (limit: {}). New logins may fail.", 
                    activeSessions, maxSessions);
            }
            
        } catch (Exception e) {
            logger.error("Error retrieving session statistics: {}", e.getMessage(), e);
        }
    }

    /**
     * Get session timeout configuration for controllers
     */
    public String getSessionTimeoutDuration() {
        return sessionTimeoutDuration;
    }

    /**
     * Get max sessions configuration for controllers
     */
    public int getMaxSessions() {
        return maxSessions;
    }

    /**
     * Check if session limit is reached
     */
    public boolean isSessionLimitReached() {
        try {
            return sessionManagementService.getActiveSessionsCount() >= maxSessions;
        } catch (Exception e) {
            logger.error("Error checking session limit: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * Get session health status for health checks
     */
    public SessionHealthStatus getSessionHealthStatus() {
        try {
            long activeSessions = sessionManagementService.getActiveSessionsCount();
            boolean isHealthy = sessionManagementService.isSessionRepositoryHealthy();
            
            return new SessionHealthStatus(
                isHealthy,
                activeSessions,
                maxSessions,
                sessionTimeoutDuration,
                activeSessions < maxSessions * 0.9 // Healthy if under 90% capacity
            );
            
        } catch (Exception e) {
            logger.error("Error getting session health status: {}", e.getMessage(), e);
            return new SessionHealthStatus(false, 0, maxSessions, sessionTimeoutDuration, false);
        }
    }

    /**
     * Session health status data class
     */
    public static class SessionHealthStatus {
        private final boolean repositoryHealthy;
        private final long activeSessions;
        private final int maxSessions;
        private final String timeoutDuration;
        private final boolean capacityHealthy;

        public SessionHealthStatus(boolean repositoryHealthy, long activeSessions, int maxSessions, 
                                 String timeoutDuration, boolean capacityHealthy) {
            this.repositoryHealthy = repositoryHealthy;
            this.activeSessions = activeSessions;
            this.maxSessions = maxSessions;
            this.timeoutDuration = timeoutDuration;
            this.capacityHealthy = capacityHealthy;
        }

        public boolean isRepositoryHealthy() { return repositoryHealthy; }
        public long getActiveSessions() { return activeSessions; }
        public int getMaxSessions() { return maxSessions; }
        public String getTimeoutDuration() { return timeoutDuration; }
        public boolean isCapacityHealthy() { return capacityHealthy; }
        public boolean isOverallHealthy() { return repositoryHealthy && capacityHealthy; }
    }
}