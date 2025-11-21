package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<Users, Integer> {
    List<Users> findAllByFirstnameLike(String firstname);
    Users findUsersByEmailLikeIgnoreCase(String email);

    // Backwards-compatible method name expected by services
    Users findUsersByEmailIgnoreCase(String email);

    // Methods to support legacy session token storage in the user table
    // Use explicit JPQL to reference the field `session_token` (snake_case) since the entity uses
    // field access. This avoids Spring Data trying to create a derived query for a 'sessionToken'
    // attribute that Hibernate doesn't expose.
    @Query("SELECT u FROM Users u WHERE u.session_token = :sessionToken")
    Optional<Users> findBySessionToken(@Param("sessionToken") String sessionToken);

    @Query("SELECT u FROM Users u WHERE u.session_token = :sessionToken AND u.session_expiration > :currentTime")
    Optional<Users> findByValidSessionToken(@Param("sessionToken") String sessionToken, @Param("currentTime") LocalDateTime currentTime);

    @Modifying
    @Query("UPDATE Users u SET u.session_token = NULL, u.session_expiration = NULL WHERE u.session_expiration < :expiredTime")
    int clearExpiredSessions(@Param("expiredTime") LocalDateTime expiredTime);

    @Query("SELECT COUNT(u) FROM Users u WHERE u.session_expiration > :currentTime")
    long countActiveSessions(@Param("currentTime") LocalDateTime currentTime);
}
