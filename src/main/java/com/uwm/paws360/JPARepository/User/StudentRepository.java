package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface StudentRepository extends JpaRepository<Student, Integer>{
    Optional<Student> findByUser(Users user);
    void deleteByUser(Users user);
}
