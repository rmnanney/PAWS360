package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.CourseEnrollment;
import com.uwm.paws360.Entity.Course.CourseSection;
import com.uwm.paws360.Entity.EntityDomains.SectionEnrollmentStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CourseEnrollmentRepository extends JpaRepository<CourseEnrollment, Long> {
    Optional<CourseEnrollment> findByStudentIdAndLectureSectionId(Integer studentId, Long lectureSectionId);

    List<CourseEnrollment> findByLectureSectionAndStatusOrderByWaitlistPositionAsc(CourseSection lectureSection, SectionEnrollmentStatus status);

    // List all enrollments (any status) for a given student
    List<CourseEnrollment> findByStudentId(Integer studentId);
}
