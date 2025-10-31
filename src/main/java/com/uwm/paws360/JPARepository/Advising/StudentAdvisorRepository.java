package com.uwm.paws360.JPARepository.Advising;

import com.uwm.paws360.Entity.Advising.StudentAdvisor;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StudentAdvisorRepository extends JpaRepository<StudentAdvisor, Long> {
    List<StudentAdvisor> findByStudent(Student student);
    Optional<StudentAdvisor> findFirstByStudentAndPrimaryAdvisorIsTrue(Student student);
}

