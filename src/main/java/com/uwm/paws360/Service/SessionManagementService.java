package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.Base.AuthenticationSession;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.JPARepository.User.AuthenticationSessionRepository;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Comprehensive session management service for SSO authentication.
 * Handles session lifecycle, cleanup, security monitoring, and analytics.
 */
@Service
@Transactional
public class SessionManagementService {

    private final AuthenticationSessionRepository sessionRepository;
    private final UserRepository userRepository;
    
    // Session configuration
    private static final int DEFAULT_SESSION_TTL_HOURS = 1;
    private static final int EXTENDED_SESSION_TTL_HOURS = 8;
    private static final int CLEANUP_INACTIVE_SESSIONS_DAYS = 30;
    private static final int MAX_SESSIONS_PER_USER = 5;

    public SessionManagementService(AuthenticationSessionRepository sessionRepository, 
                                  UserRepository userRepository) {
        this.sessionRepository = sessionRepository;
        this.userRepository = userRepository;
    }

    /*------------------------- Session Creation and Validation -------------------------*/

    /**
     * Create a new SSO session
     */
    public AuthenticationSession createSession(Users user, String sessionToken, String ipAddress, 
                                             String userAgent, String serviceOrigin) {
        // Delete any existing sessions with the same token to avoid constraint violation
        sessionRepository.deleteBySessionToken(sessionToken);
        
        return createSessionWithTTL(user, sessionToken, ipAddress, userAgent, serviceOrigin, DEFAULT_SESSION_TTL_HOURS);
    }

    /**
     * Create a new SSO session with custom TTL (internal method)
     */
    private AuthenticationSession createSessionWithTTL(Users user, String sessionToken, String ipAddress, 
                                             String userAgent, String serviceOrigin, int ttlHours) {
        // Enforce session limits per user
        enforceSessionLimits(user);
        
        // Create new session
        AuthenticationSession session = new AuthenticationSession(
            user,
            sessionToken,
            LocalDateTime.now().plusHours(ttlHours),
            ipAddress,
            userAgent,
            serviceOrigin
        );
        
        return sessionRepository.save(session);
    }

    /**
     * Create a new SSO session with custom TTL
     */
    public AuthenticationSession createSession(Users user, String sessionToken, String ipAddress, 
                                             String userAgent, String serviceOrigin, int ttlHours) {
        // Delete any existing sessions with the same token to avoid constraint violation
        sessionRepository.deleteBySessionToken(sessionToken);
        
        return createSessionWithTTL(user, sessionToken, ipAddress, userAgent, serviceOrigin, ttlHours);
    }

    /**
     * Validate and refresh session
     */
    public Optional<AuthenticationSession> validateAndRefreshSession(String sessionToken) {
        Optional<AuthenticationSession> sessionOpt = sessionRepository.findValidSession(sessionToken, LocalDateTime.now());
        
        if (sessionOpt.isPresent()) {
            AuthenticationSession session = sessionOpt.get();
            
            // Update last accessed time
            session.setLastAccessed(LocalDateTime.now());
            
            // Auto-extend session if accessed within last hour
            LocalDateTime oneHourAgo = LocalDateTime.now().minusHours(1);
            if (session.getLastAccessed().isAfter(oneHourAgo)) {
                session.extendSession(DEFAULT_SESSION_TTL_HOURS);
            }
            
            return Optional.of(sessionRepository.save(session));
        }
        
        return Optional.empty();
    }

    /*------------------------- Session Management -------------------------*/

    /**
     * Extend session expiration
     */
    public boolean extendSession(String sessionToken, int hours) {
        Optional<AuthenticationSession> sessionOpt = sessionRepository.findBySessionTokenAndIsActiveTrue(sessionToken);
        
        if (sessionOpt.isPresent() && !sessionOpt.get().isExpired()) {
            AuthenticationSession session = sessionOpt.get();
            session.extendSession(hours);
            sessionRepository.save(session);
            return true;
        }
        
        return false;
    }

    /**
     * Invalidate specific session
     */
    public boolean invalidateSession(String sessionToken, String reason) {
        int invalidated = sessionRepository.invalidateSession(sessionToken, reason);
        return invalidated > 0;
    }

    /**
     * Invalidate all user sessions
     */
    public int invalidateAllUserSessions(int userId, String reason) {
        return sessionRepository.invalidateUserSessions(userId, reason);
    }

    /**
     * Get active sessions for user
     */
    public List<AuthenticationSession> getUserActiveSessions(int userId) {
        return sessionRepository.findActiveSessionsByUserId(userId, LocalDateTime.now());
    }

    /*------------------------- Security and Monitoring -------------------------*/

    /**
     * Detect suspicious sessions for user (multiple IPs, etc.)
     */
    public List<AuthenticationSession> detectSuspiciousSessions(int userId, String currentIp) {
        return sessionRepository.findSuspiciousSessionsForUser(userId, currentIp, LocalDateTime.now());
    }

    /**
     * Get session history for user
     */
    public List<AuthenticationSession> getUserSessionHistory(int userId, int days) {
        LocalDateTime fromDate = LocalDateTime.now().minusDays(days);
        return sessionRepository.findUserSessionHistory(userId, fromDate);
    }

    /**
     * Get sessions by IP address for security analysis
     */
    public List<AuthenticationSession> getSessionsByIpAddress(String ipAddress, int days) {
        LocalDateTime fromDate = LocalDateTime.now().minusDays(days);
        return sessionRepository.findSessionsByIpAddress(ipAddress, fromDate);
    }

    /*------------------------- Analytics and Statistics -------------------------*/

    /**
     * Get total active sessions count
     */
    public long getActiveSessionsCount() {
        return sessionRepository.countActiveSessions(LocalDateTime.now());
    }

    /**
     * Get active sessions count by service
     */
    public long getActiveSessionsCountByService(String serviceOrigin) {
        return sessionRepository.countActiveSessionsByService(serviceOrigin, LocalDateTime.now());
    }

    /**
     * Get session statistics by service
     */
    public List<Object[]> getSessionStatsByService() {
        return sessionRepository.getActiveSessionCountsByService(LocalDateTime.now());
    }

    /*------------------------- Cleanup and Maintenance -------------------------*/

    /**
     * Enforce session limits per user
     */
    private void enforceSessionLimits(Users user) {
        List<AuthenticationSession> activeSessions = getUserActiveSessions(user.getId());
        
        if (activeSessions.size() >= MAX_SESSIONS_PER_USER) {
            // Invalidate oldest sessions
            activeSessions.stream()
                .limit(activeSessions.size() - MAX_SESSIONS_PER_USER + 1)
                .forEach(session -> invalidateSession(session.getSessionToken(), "session_limit_exceeded"));
        }
    }

    /**
     * Scheduled cleanup of expired sessions (runs every hour)
     */
    @Scheduled(fixedRate = 3600000) // 1 hour in milliseconds
    public void cleanupExpiredSessions() {
        LocalDateTime now = LocalDateTime.now();
        
        // Expire old sessions
        int expiredSessions = sessionRepository.expireOldSessions(now);
        
        // Delete inactive sessions older than 30 days
        LocalDateTime cleanupDate = now.minusDays(CLEANUP_INACTIVE_SESSIONS_DAYS);
        int deletedSessions = sessionRepository.deleteInactiveSessions(cleanupDate);
        
        // Also clean up user table sessions for backward compatibility
        int clearedUserSessions = userRepository.clearExpiredSessions(now);
        
        if (expiredSessions > 0 || deletedSessions > 0 || clearedUserSessions > 0) {
            System.out.println(String.format("Session cleanup completed: %d expired, %d deleted, %d user sessions cleared", 
                expiredSessions, deletedSessions, clearedUserSessions));
        }
    }

    /**
     * Manual cleanup with custom parameters
     */
    public void performManualCleanup(int expiredSessionsDays, int inactiveSessionsDays) {
        LocalDateTime expiredTime = LocalDateTime.now().minusDays(expiredSessionsDays);
        LocalDateTime cleanupTime = LocalDateTime.now().minusDays(inactiveSessionsDays);
        
        int expiredSessions = sessionRepository.expireOldSessions(expiredTime);
        int deletedSessions = sessionRepository.deleteInactiveSessions(cleanupTime);
        int clearedUserSessions = userRepository.clearExpiredSessions(expiredTime);
        
        System.out.println(String.format("Manual cleanup completed: %d expired, %d deleted, %d user sessions cleared", 
            expiredSessions, deletedSessions, clearedUserSessions));
    }

    /*------------------------- Health Check Methods -------------------------*/

    /**
     * Check session repository health
     */
    public boolean isSessionRepositoryHealthy() {
        try {
            // Simple count query to verify database connectivity
            long count = sessionRepository.countActiveSessions(LocalDateTime.now());
            return count >= 0;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Get session system statistics for monitoring
     */
    public SessionSystemStats getSystemStats() {
        LocalDateTime now = LocalDateTime.now();
        
        long totalActiveSessions = sessionRepository.countActiveSessions(now);
        long totalActiveUserSessions = userRepository.countActiveSessions(now);
        
        return new SessionSystemStats(
            totalActiveSessions,
            totalActiveUserSessions,
            getSessionStatsByService(),
            now
        );
    }

    /**
     * Simple data class for session system statistics
     */
    public static class SessionSystemStats {
        public final long totalActiveSessions;
        public final long totalActiveUserSessions;
        public final List<Object[]> sessionsByService;
        public final LocalDateTime timestamp;

        public SessionSystemStats(long totalActiveSessions, long totalActiveUserSessions, 
                                List<Object[]> sessionsByService, LocalDateTime timestamp) {
            this.totalActiveSessions = totalActiveSessions;
            this.totalActiveUserSessions = totalActiveUserSessions;
            this.sessionsByService = sessionsByService;
            this.timestamp = timestamp;
        }
    }
}