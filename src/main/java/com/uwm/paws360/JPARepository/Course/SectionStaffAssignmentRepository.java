package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.SectionStaffAssignment;
import com.uwm.paws360.Entity.EntityDomains.InstructionalRole;
import com.uwm.paws360.Entity.Course.CourseSection;
import com.uwm.paws360.Entity.Base.Users;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SectionStaffAssignmentRepository extends JpaRepository<SectionStaffAssignment, Long> {
    boolean existsBySectionAndStaffAndRole(CourseSection section, Users staff, InstructionalRole role);
}
