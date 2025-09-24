package com.uwm.paws360.JPARepository;

import com.uwm.paws360.Entity.Users;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRepository extends JpaRepository<Users, Integer> {
    List<Users> findAllByFirstnameLike(String firstname);
    Users findUsersByEmailLikeIgnoreCase(String email);
}
