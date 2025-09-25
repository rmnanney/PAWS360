package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Professor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProfessorRepository extends JpaRepository<Professor, Integer> {
}
