package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.Courses;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CourseRepository extends JpaRepository<Courses, Integer> {
    Optional<Courses> findByCourseCodeIgnoreCase(String courseCode);
}
