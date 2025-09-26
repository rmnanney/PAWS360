package com.uwm.paws360.JPARepository.User;

import com.uwm.paws360.Entity.UserTypes.Counselor;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CounselorRepository extends JpaRepository<Counselor, Integer> {
}
