package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Instructor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InstructorRepository extends JpaRepository<Instructor, Integer> {
}
