package com.uwm.paws360.JPARepository;

import com.uwm.paws360.Entity.UserRole.Professor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProfessorRepository extends JpaRepository<Professor, Integer> {
}
