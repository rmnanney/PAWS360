package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.AuthenticationSession;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.AuthenticationSessionRepository;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@Service
public class LoginService {

    private final UserRepository userRepository;
    private final AuthenticationSessionRepository sessionRepository;
    private final int TOKEN = 32;
    private final String ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    private static final int MAX_FAILED_ATTEMPTS = 5;
    private static final int LOCK_DURATION_MINUTES = 15;
    private static final int SESSION_TTL_HOURS = 1;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public LoginService(UserRepository userRepository, AuthenticationSessionRepository sessionRepository){
        this.userRepository = userRepository;
        this.sessionRepository = sessionRepository;
    }

    @Transactional
    public UserLoginResponseDTO login(UserLoginRequestDTO userLogin){
        Users user = userRepository.findUsersByEmailIgnoreCase(userLogin.email());
        if (user == null) return new UserLoginResponseDTO(-1, null, null, null,
                null, null, null, null, "Invalid Email or Password");

        // If locked, check if lock has expired
        if (user.isAccount_locked()){
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime lockedUntil = user.getAccount_locked_duration();
            if (lockedUntil != null && now.isBefore(lockedUntil)){
                return new UserLoginResponseDTO(-1, null,
                        null, null, null, null, null, null, "Account Locked - Try again later");
            } else {
                // Unlock account after timeout
                user.setAccount_locked(false);
                user.setAccount_locked_duration(null);
                user.setFailed_attempts(0);
            }
        }

        if(!user.getStatus().equals(Status.ACTIVE)) return new UserLoginResponseDTO(-1, null,
                null, null, null, null, null, null, "Account Is Not Active");

        if(!passwordMatches(user.getPassword(), userLogin.password())){
            int fails = user.getFailed_attempts() + 1;
            user.setFailed_attempts(fails);
            if(fails >= MAX_FAILED_ATTEMPTS){
                user.setAccount_locked(true);
                user.setAccount_locked_duration(LocalDateTime.now().plusMinutes(LOCK_DURATION_MINUTES));
                userRepository.save(user);
                return new UserLoginResponseDTO(-1, null,
                        null, null, null, null, null, null, "Account Locked - Too many attempts");
            }
            userRepository.save(user);
            return new UserLoginResponseDTO(-1, null, null, null, null, null, null, null, "Invalid Email or Password");
        }

        user.setFailed_attempts(0);
        user.setAccount_locked(false);
        user.setAccount_locked_duration(null);
        user.setLast_login(LocalDateTime.now());
        // Upgrade legacy plaintext password to bcrypt
        if (!isBCrypt(user.getPassword())){
            user.setPassword(passwordEncoder.encode(userLogin.password()));
        }
        user.setSession_token(generateAuthenticationToken());
        user.setSession_expiration(LocalDateTime.now().plusHours(SESSION_TTL_HOURS));
        
        // Create SSO session record for cross-service authentication
        createSSOSession(user, user.getSession_token(), null, null, "student-portal");
        
        userRepository.save(user);
        return new UserLoginResponseDTO(
                user.getId(),
                user.getEmail(),
                user.getFirstname(),
                user.getLastname(),
                user.getRole(),
                user.getStatus(),
                user.getSession_token(),
                user.getSession_expiration(),
                "Login Successful"
        );
    }

    /**
     * Create SSO session for cross-service authentication
     */
    @Transactional
    public AuthenticationSession createSSOSession(Users user, String sessionToken, String ipAddress, 
                                                 String userAgent, String serviceOrigin) {
        // Invalidate any existing active sessions for this user
        sessionRepository.invalidateUserSessions(user.getId(), "new_login");
        
        // Delete any sessions with the same token to avoid constraint violation
        sessionRepository.deleteBySessionToken(sessionToken);
        
        // Create new SSO session
        AuthenticationSession session = new AuthenticationSession(
            user,
            sessionToken,
            LocalDateTime.now().plusHours(SESSION_TTL_HOURS),
            ipAddress,
            userAgent,
            serviceOrigin
        );
        
        return sessionRepository.save(session);
    }

    /**
     * Validate SSO session token across services
     */
    public Optional<Users> validateSSOSession(String sessionToken) {
        if (sessionToken == null || sessionToken.trim().isEmpty()) {
            return Optional.empty();
        }
        
        // Check session repository first
        Optional<AuthenticationSession> sessionOpt = sessionRepository.findValidSession(sessionToken, LocalDateTime.now());
        if (sessionOpt.isPresent()) {
            AuthenticationSession session = sessionOpt.get();
            // Update last accessed time
            session.setLastAccessed(LocalDateTime.now());
            sessionRepository.save(session);
            return Optional.of(session.getUser());
        }
        
        // Fallback to user table session token for backward compatibility
        return userRepository.findByValidSessionToken(sessionToken, LocalDateTime.now());
    }

    /**
     * Logout and invalidate SSO session
     */
    public boolean logoutSSOSession(String sessionToken, String reason) {
        if (sessionToken == null || sessionToken.trim().isEmpty()) {
            return false;
        }
        
        // Invalidate SSO session
        int sessionsInvalidated = sessionRepository.invalidateSession(sessionToken, reason != null ? reason : "manual_logout");
        
        // Also clear user table session for backward compatibility
        Optional<Users> userOpt = userRepository.findBySessionToken(sessionToken);
        if (userOpt.isPresent()) {
            Users user = userOpt.get();
            user.setSession_token(null);
            user.setSession_expiration(null);
            userRepository.save(user);
        }
        
        return sessionsInvalidated > 0 || userOpt.isPresent();
    }

    /**
     * Clean up expired sessions
     */
    public int cleanupExpiredSessions() {
        LocalDateTime expiredTime = LocalDateTime.now();
        
        // Clean up SSO sessions
        int expiredSSOSessions = sessionRepository.expireOldSessions(expiredTime);
        
        // Clean up user table sessions
        int clearedUserSessions = userRepository.clearExpiredSessions(expiredTime);
        
        return expiredSSOSessions + clearedUserSessions;
    }

    private boolean isBCrypt(String value){
        if (value == null) return false;
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }

    private boolean passwordMatches(String stored, String raw){
        if (stored == null || raw == null) return false;
        if (isBCrypt(stored)){
            return passwordEncoder.matches(raw, stored);
        }
        // Fallback for legacy plaintext records; upgrade to bcrypt on next success
        boolean match = stored.equals(raw);
        if (match){
            // hash and upgrade stored password
            String hashed = passwordEncoder.encode(raw);
            // fetch fresh user and update handled by caller; to avoid extra load, let caller do it
        }
        return match;
    }

    private String generateAuthenticationToken(){
        SecureRandom secureRandom = new SecureRandom();
        StringBuilder tokenBuilder = new StringBuilder(TOKEN);
        for(int i = 0; i < TOKEN; i++){
            int randomIndex = secureRandom.nextInt(ALPHANUMERIC.length());
            tokenBuilder.append(ALPHANUMERIC.charAt(randomIndex));
        }
        return tokenBuilder.toString();
    }

}
