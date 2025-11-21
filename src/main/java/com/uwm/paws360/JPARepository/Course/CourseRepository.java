package com.uwm.paws360.JPARepository.Course;

import com.uwm.paws360.Entity.Course.Courses;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Courses, Integer> {
    Optional<Courses> findByCourseCodeIgnoreCase(String courseCode);

    interface TermYearView {
        String getTerm();
        Integer getAcademicYear();
    }

    @Query("""
            select distinct c.term as term, c.academicYear as academicYear
            from Courses c
            order by c.academicYear desc, c.term asc
            """)
    List<TermYearView> findDistinctTermsAndYears();
}
