package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Faculty;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface FacultyRepository extends JpaRepository<Faculty, Integer> {
    Optional<Faculty> findByUser(Users user);
    void deleteByUser(Users user);
}
