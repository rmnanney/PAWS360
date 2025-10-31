package com.uwm.paws360.JPARepository.Advising;

import com.uwm.paws360.Entity.Advising.AdvisorAppointment;
import com.uwm.paws360.Entity.UserTypes.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;

public interface AdvisorAppointmentRepository extends JpaRepository<AdvisorAppointment, Long> {
    List<AdvisorAppointment> findByStudentAndScheduledAtAfterOrderByScheduledAtAsc(Student student, OffsetDateTime after);
}

