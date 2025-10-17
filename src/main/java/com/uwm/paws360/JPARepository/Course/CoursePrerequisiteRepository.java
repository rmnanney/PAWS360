package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.CoursePrerequisite;
import com.uwm.paws360.Entity.Course.Courses;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CoursePrerequisiteRepository extends JpaRepository<CoursePrerequisite, Long> {
    List<CoursePrerequisite> findByCourse(Courses course);
}
