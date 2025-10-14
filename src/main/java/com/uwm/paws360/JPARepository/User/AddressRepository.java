package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AddressRepository extends JpaRepository<Address, Integer> {
    List<Address> findAllByUser(Users user);
}

