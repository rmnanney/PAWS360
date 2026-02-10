package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Advisor;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface AdvisorRepository extends JpaRepository<Advisor, Integer>{
    Optional<Advisor> findByUser(Users user);
    void deleteByUser(Users user);
}
