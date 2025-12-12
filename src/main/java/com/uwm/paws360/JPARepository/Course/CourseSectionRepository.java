package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.CourseSection;
import com.uwm.paws360.Entity.Course.Courses;
import com.uwm.paws360.Entity.EntityDomains.SectionType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.List;

public interface CourseSectionRepository extends JpaRepository<CourseSection, Long> {
    List<CourseSection> findByCourse(Courses course);
    List<CourseSection> findByCourseAndSectionType(Courses course, SectionType sectionType);
    List<CourseSection> findByParentSection(CourseSection parentSection);
    Optional<CourseSection> findFirstByCourseAndSectionCodeIgnoreCaseAndTermIgnoreCaseAndAcademicYearAndSectionType(
            Courses course, String sectionCode, String term, Integer academicYear, SectionType sectionType);
}
