package com.uwm.paws360.JPARepository.Finances;

import com.uwm.paws360.Entity.Finances.AidAward;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AidAwardRepository extends JpaRepository<AidAward, Long> {
    List<AidAward> findByStudent(Student student);
}

