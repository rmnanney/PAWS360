package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.TA;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface TARepository extends JpaRepository<TA, Integer> {
    Optional<TA> findByUser(Users user);
    void deleteByUser(Users user);
}
