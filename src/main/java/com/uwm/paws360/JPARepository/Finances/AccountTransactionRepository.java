package com.uwm.paws360.JPARepository.Finances;

import com.uwm.paws360.Entity.Finances.AccountTransaction;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AccountTransactionRepository extends JpaRepository<AccountTransaction, Long> {
    List<AccountTransaction> findByStudentOrderByPostedAtDesc(Student student);
}

