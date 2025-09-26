package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Mentor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MentorRepository extends JpaRepository<Mentor, Integer> {
}
