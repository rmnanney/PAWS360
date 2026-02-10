package com.uwm.paws360.JPARepository.Advising;

import com.uwm.paws360.Entity.Advising.AdvisorMessage;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AdvisorMessageRepository extends JpaRepository<AdvisorMessage, Long> {
    List<AdvisorMessage> findByStudentOrderBySentAtAsc(Student student);
}

