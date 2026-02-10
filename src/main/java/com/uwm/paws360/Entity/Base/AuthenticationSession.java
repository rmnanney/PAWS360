package com.uwm.paws360.Entity.Base;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity for managing SSO authentication sessions across services.
 * Supports secure session management with automatic expiration and cleanup.
 */
@Entity
@Table(name = "authentication_sessions")
public class AuthenticationSession {

    @Id
    @Column(name = "session_id", unique = true, updatable = false)
    private String sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users user;

    @Column(name = "session_token", nullable = false, length = 255, unique = true)
    private String sessionToken;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "last_accessed", nullable = false)
    private LocalDateTime lastAccessed;

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;

    @Column(name = "service_origin", length = 100)
    private String serviceOrigin; // e.g., "student-portal", "admin-view"

    @Column(name = "logout_reason", length = 50)
    private String logoutReason; // e.g., "manual", "timeout", "security"

    /*------------------------- Constructors -------------------------*/

    public AuthenticationSession() {}

    public AuthenticationSession(Users user, String sessionToken, LocalDateTime expiresAt, 
                               String ipAddress, String userAgent, String serviceOrigin) {
        this.sessionId = UUID.randomUUID().toString();
        this.user = user;
        this.sessionToken = sessionToken;
        this.createdAt = LocalDateTime.now();
        this.expiresAt = expiresAt;
        this.lastAccessed = LocalDateTime.now();
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.serviceOrigin = serviceOrigin;
        this.isActive = true;
    }

    /*------------------------- Lifecycle Methods -------------------------*/

    @PrePersist
    private void onCreate() {
        if (sessionId == null) {
            sessionId = UUID.randomUUID().toString();
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (lastAccessed == null) {
            lastAccessed = LocalDateTime.now();
        }
        if (isActive == false) {
            isActive = true;
        }
    }

    @PreUpdate
    private void onUpdate() {
        lastAccessed = LocalDateTime.now();
    }

    /*------------------------- Business Methods -------------------------*/

    /**
     * Check if the session is expired
     */
    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }

    /**
     * Check if the session is valid (active and not expired)
     */
    public boolean isValid() {
        return isActive && !isExpired();
    }

    /**
     * Extend session expiration by specified hours
     */
    public void extendSession(int hours) {
        this.expiresAt = LocalDateTime.now().plusHours(hours);
        this.lastAccessed = LocalDateTime.now();
    }

    /**
     * Invalidate the session
     */
    public void invalidate(String reason) {
        this.isActive = false;
        this.logoutReason = reason;
    }

    /*------------------------- Getters -------------------------*/

    public String getSessionId() {
        return sessionId;
    }

    public Users getUser() {
        return user;
    }

    public String getSessionToken() {
        return sessionToken;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public LocalDateTime getLastAccessed() {
        return lastAccessed;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public String getUserAgent() {
        return userAgent;
    }

    public boolean isActive() {
        return isActive;
    }

    public String getServiceOrigin() {
        return serviceOrigin;
    }

    public String getLogoutReason() {
        return logoutReason;
    }

    /*------------------------- Setters -------------------------*/

    public void setSessionId(String sessionId) {
        this.sessionId = sessionId;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public void setSessionToken(String sessionToken) {
        this.sessionToken = sessionToken;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public void setLastAccessed(LocalDateTime lastAccessed) {
        this.lastAccessed = lastAccessed;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }

    public void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public void setServiceOrigin(String serviceOrigin) {
        this.serviceOrigin = serviceOrigin;
    }

    public void setLogoutReason(String logoutReason) {
        this.logoutReason = logoutReason;
    }
}