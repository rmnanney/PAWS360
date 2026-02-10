package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Professor;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ProfessorRepository extends JpaRepository<Professor, Integer> {
    Optional<Professor> findByUser(Users user);
    void deleteByUser(Users user);
}
