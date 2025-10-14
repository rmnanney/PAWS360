package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@Service
public class LoginService {

    private final UserRepository userRepository;
    private final int TOKEN = 32;
    private final String ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";
    private static final int MAX_FAILED_ATTEMPTS = 5;
    private static final int LOCK_DURATION_MINUTES = 15;
    private static final int SESSION_TTL_HOURS = 1;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public LoginService(UserRepository userRepository){
        this.userRepository = userRepository;
    }

    public UserLoginResponseDTO login(UserLoginRequestDTO userLogin){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(userLogin.email());
        if (user == null) return new UserLoginResponseDTO(-1, null, null, null,
                null, null, null, null, "Invalid Email or Password");

        // If locked, check if lock has expired
        if (user.isAccount_locked()){
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime lockedUntil = user.getAccount_locked_duration();
            if (lockedUntil != null && now.isBefore(lockedUntil)){
                return new UserLoginResponseDTO(user.getId(), user.getEmail(),
                        user.getFirstname(), user.getLastname(), user.getRole(), user.getStatus(), null, user.getAccount_locked_duration(), "Account Locked - Try again later");
            } else {
                // Unlock account after timeout
                user.setAccount_locked(false);
                user.setAccount_locked_duration(null);
                user.setFailed_attempts(0);
            }
        }

        if(!user.getStatus().equals(Status.ACTIVE)) return new UserLoginResponseDTO(user.getId(), user.getEmail(),
                user.getFirstname(), user.getLastname(), user.getRole(), user.getStatus(), null, null, "Account Is Not Active");

        if(!passwordMatches(user.getPassword(), userLogin.password())){
            int fails = user.getFailed_attempts() + 1;
            user.setFailed_attempts(fails);
            if(fails >= MAX_FAILED_ATTEMPTS){
                user.setAccount_locked(true);
                user.setAccount_locked_duration(LocalDateTime.now().plusMinutes(LOCK_DURATION_MINUTES));
                userRepository.save(user);
                return new UserLoginResponseDTO(user.getId(), user.getEmail(),
                        user.getFirstname(), user.getLastname(), user.getRole(), user.getStatus(), null, user.getAccount_locked_duration(), "Account Locked - Too many attempts");
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
