package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Counselor;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CounselorRepository extends JpaRepository<Counselor, Integer> {
    Optional<Counselor> findByUser(Users user);
    void deleteByUser(Users user);
}
