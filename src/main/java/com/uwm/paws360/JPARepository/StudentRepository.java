package com.uwm.paws360.JPARepository;

import com.uwm.paws360.Entity.UserRole.Student;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentRepository extends JpaRepository<Student, Integer>{}
