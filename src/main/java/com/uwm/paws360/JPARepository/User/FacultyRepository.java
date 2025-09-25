package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Faculty;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FacultyRepository extends JpaRepository<Faculty, Integer> {
}
