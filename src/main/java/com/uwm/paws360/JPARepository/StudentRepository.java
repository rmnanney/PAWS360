package com.uwm.paws360.JPARepository;

import com.uwm.paws360.Entity.Profiles.Student;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentRepository extends JpaRepository<Student, Integer>{}
