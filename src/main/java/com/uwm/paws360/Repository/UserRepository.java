package com.uwm.paws360.Repository;

import com.uwm.paws360.Domain.Users;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<Users, Integer> {}
