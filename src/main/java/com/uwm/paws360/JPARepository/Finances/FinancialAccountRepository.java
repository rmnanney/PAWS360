package com.uwm.paws360.JPARepository.Finances;

import com.uwm.paws360.Entity.Finances.FinancialAccount;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FinancialAccountRepository extends JpaRepository<FinancialAccount, Long> {
    Optional<FinancialAccount> findByStudent(Student student);
}

