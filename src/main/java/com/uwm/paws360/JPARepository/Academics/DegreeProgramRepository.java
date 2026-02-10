package com.uwm.paws360.JPARepository.Academics;

import com.uwm.paws360.Entity.Academics.DegreeProgram;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DegreeProgramRepository extends JpaRepository<DegreeProgram, Long> {
    Optional<DegreeProgram> findByCodeIgnoreCase(String code);
}

