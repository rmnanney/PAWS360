package com.uwm.paws360.JPARepository.Academics;

import com.uwm.paws360.Entity.Academics.DegreeProgram;
import com.uwm.paws360.Entity.Academics.DegreeRequirement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DegreeRequirementRepository extends JpaRepository<DegreeRequirement, Long> {
    List<DegreeRequirement> findByDegreeProgram(DegreeProgram program);
}

