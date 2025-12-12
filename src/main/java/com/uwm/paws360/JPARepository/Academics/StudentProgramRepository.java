package com.uwm.paws360.JPARepository.Academics;

import com.uwm.paws360.Entity.Academics.StudentProgram;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StudentProgramRepository extends JpaRepository<StudentProgram, Long> {
    List<StudentProgram> findByStudent(Student student);
    Optional<StudentProgram> findFirstByStudentAndProgramAndPrimary(Student student, com.uwm.paws360.Entity.Academics.DegreeProgram program, boolean primary);
}
