package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<Users, Integer> {
    List<Users> findAllByFirstnameLike(String firstname);
    Users findUsersByEmailLikeIgnoreCase(String email);  // Restored for backward compatibility
    Users findUsersByEmailIgnoreCase(String email);
    
    // Session management methods for SSO
    @Query("SELECT u FROM Users u WHERE u.session_token = :sessionToken")
    Optional<Users> findBySessionToken(@Param("sessionToken") String sessionToken);
    
    @Query("SELECT u FROM Users u WHERE u.session_token = :sessionToken AND u.session_expiration > :currentTime")
    Optional<Users> findByValidSessionToken(@Param("sessionToken") String sessionToken, 
                                          @Param("currentTime") LocalDateTime currentTime);
    
    @Query("SELECT u FROM Users u WHERE u.email = :email AND u.session_token IS NOT NULL AND u.session_expiration > :currentTime")
    Optional<Users> findByEmailWithActiveSession(@Param("email") String email, 
                                                @Param("currentTime") LocalDateTime currentTime);
    
    @Modifying
    @Query("UPDATE Users u SET u.session_token = NULL, u.session_expiration = NULL WHERE u.session_expiration < :expiredTime")
    int clearExpiredSessions(@Param("expiredTime") LocalDateTime expiredTime);
    
    @Modifying
    @Query("UPDATE Users u SET u.session_token = NULL, u.session_expiration = NULL WHERE u.id = :userId")
    int clearUserSession(@Param("userId") int userId);
    
    @Query("SELECT COUNT(u) FROM Users u WHERE u.session_token IS NOT NULL AND u.session_expiration > :currentTime")
    long countActiveSessions(@Param("currentTime") LocalDateTime currentTime);
}
