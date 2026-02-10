package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.EmergencyContact;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, Integer> {
    List<EmergencyContact> findByUser(Users user);
}

