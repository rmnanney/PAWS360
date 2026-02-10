package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Instructor;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface InstructorRepository extends JpaRepository<Instructor, Integer> {
    Optional<Instructor> findByUser(Users user);
    void deleteByUser(Users user);
}
