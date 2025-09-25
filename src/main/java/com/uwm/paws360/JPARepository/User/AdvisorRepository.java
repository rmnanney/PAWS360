package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Advisor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AdvisorRepository extends JpaRepository<Advisor, Integer>{
}
