package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Mentor;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface MentorRepository extends JpaRepository<Mentor, Integer> {
    Optional<Mentor> findByUser(Users user);
    void deleteByUser(Users user);
}
