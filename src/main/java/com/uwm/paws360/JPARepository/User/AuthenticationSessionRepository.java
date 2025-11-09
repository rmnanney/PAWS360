package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.AuthenticationSession;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for managing SSO authentication sessions across services.
 * Provides comprehensive session management and cleanup capabilities.
 */
public interface AuthenticationSessionRepository extends JpaRepository<AuthenticationSession, String> {
    
    // Find active sessions
    Optional<AuthenticationSession> findBySessionTokenAndIsActiveTrue(String sessionToken);
    
    @Query("SELECT s FROM AuthenticationSession s WHERE s.sessionToken = :sessionToken AND s.isActive = true AND s.expiresAt > :currentTime")
    Optional<AuthenticationSession> findValidSession(@Param("sessionToken") String sessionToken, 
                                                    @Param("currentTime") LocalDateTime currentTime);
    
    // User session management
    List<AuthenticationSession> findByUserAndIsActiveTrueOrderByCreatedAtDesc(Users user);
    
    @Query("SELECT s FROM AuthenticationSession s WHERE s.user.id = :userId AND s.isActive = true AND s.expiresAt > :currentTime")
    List<AuthenticationSession> findActiveSessionsByUserId(@Param("userId") int userId, 
                                                          @Param("currentTime") LocalDateTime currentTime);
    
    // Service-specific sessions
    @Query("SELECT s FROM AuthenticationSession s WHERE s.serviceOrigin = :serviceOrigin AND s.isActive = true AND s.expiresAt > :currentTime")
    List<AuthenticationSession> findActiveSessionsByService(@Param("serviceOrigin") String serviceOrigin, 
                                                           @Param("currentTime") LocalDateTime currentTime);
    
    // Session cleanup operations
    @Modifying
    @Query("UPDATE AuthenticationSession s SET s.isActive = false, s.logoutReason = 'expired' WHERE s.expiresAt < :expiredTime AND s.isActive = true")
    int expireOldSessions(@Param("expiredTime") LocalDateTime expiredTime);
    
    @Modifying
    @Query("UPDATE AuthenticationSession s SET s.isActive = false, s.logoutReason = :reason WHERE s.user.id = :userId AND s.isActive = true")
    int invalidateUserSessions(@Param("userId") int userId, @Param("reason") String reason);
    
    @Modifying
    @Query("UPDATE AuthenticationSession s SET s.isActive = false, s.logoutReason = :reason WHERE s.sessionToken = :sessionToken")
    int invalidateSession(@Param("sessionToken") String sessionToken, @Param("reason") String reason);
    
    @Modifying
    @Query("DELETE FROM AuthenticationSession s WHERE s.sessionToken = :sessionToken")
    int deleteBySessionToken(@Param("sessionToken") String sessionToken);
    
    @Modifying
    @Query("DELETE FROM AuthenticationSession s WHERE s.isActive = false AND s.createdAt < :cleanupDate")
    int deleteInactiveSessions(@Param("cleanupDate") LocalDateTime cleanupDate);
    
    // Analytics and monitoring
    @Query("SELECT COUNT(s) FROM AuthenticationSession s WHERE s.isActive = true AND s.expiresAt > :currentTime")
    long countActiveSessions(@Param("currentTime") LocalDateTime currentTime);
    
    @Query("SELECT COUNT(s) FROM AuthenticationSession s WHERE s.serviceOrigin = :serviceOrigin AND s.isActive = true AND s.expiresAt > :currentTime")
    long countActiveSessionsByService(@Param("serviceOrigin") String serviceOrigin, 
                                     @Param("currentTime") LocalDateTime currentTime);
    
    @Query("SELECT s.serviceOrigin, COUNT(s) FROM AuthenticationSession s WHERE s.isActive = true AND s.expiresAt > :currentTime GROUP BY s.serviceOrigin")
    List<Object[]> getActiveSessionCountsByService(@Param("currentTime") LocalDateTime currentTime);
    
    @Query("SELECT s FROM AuthenticationSession s WHERE s.user.id = :userId AND s.createdAt >= :fromDate ORDER BY s.createdAt DESC")
    List<AuthenticationSession> findUserSessionHistory(@Param("userId") int userId, 
                                                       @Param("fromDate") LocalDateTime fromDate);
    
    // Session extension
    @Modifying
    @Query("UPDATE AuthenticationSession s SET s.expiresAt = :newExpirationTime, s.lastAccessed = :accessTime WHERE s.sessionToken = :sessionToken AND s.isActive = true")
    int extendSession(@Param("sessionToken") String sessionToken, 
                     @Param("newExpirationTime") LocalDateTime newExpirationTime,
                     @Param("accessTime") LocalDateTime accessTime);
    
    // Find sessions for security auditing
    @Query("SELECT s FROM AuthenticationSession s WHERE s.ipAddress = :ipAddress AND s.createdAt >= :fromDate")
    List<AuthenticationSession> findSessionsByIpAddress(@Param("ipAddress") String ipAddress, 
                                                        @Param("fromDate") LocalDateTime fromDate);
    
    @Query("SELECT s FROM AuthenticationSession s WHERE s.user.id = :userId AND s.ipAddress != :currentIp AND s.isActive = true AND s.expiresAt > :currentTime")
    List<AuthenticationSession> findSuspiciousSessionsForUser(@Param("userId") int userId, 
                                                              @Param("currentIp") String currentIp, 
                                                              @Param("currentTime") LocalDateTime currentTime);
}