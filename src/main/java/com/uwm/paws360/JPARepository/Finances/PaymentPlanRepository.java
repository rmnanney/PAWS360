package com.uwm.paws360.JPARepository.Finances;

import com.uwm.paws360.Entity.Finances.PaymentPlan;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PaymentPlanRepository extends JpaRepository<PaymentPlan, Long> {
    List<PaymentPlan> findByStudent(Student student);
}

