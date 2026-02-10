package com.uwm.paws360.JPARepository.Academics;

import com.uwm.paws360.Entity.Academics.StudentProgram;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface StudentProgramRepository extends JpaRepository<StudentProgram, Long> {
    List<StudentProgram> findByStudent(Student student);
}

