package com.uwm.paws360.JPARepository;

import com.uwm.paws360.Entity.Role.Professor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProfessorRepository extends JpaRepository<Professor, Integer> {
}
