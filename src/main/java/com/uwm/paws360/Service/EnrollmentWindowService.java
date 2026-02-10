package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Course.EnrollmentWindowDTO;
import com.uwm.paws360.JPARepository.Course.CourseRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

@Service
public class EnrollmentWindowService {

    private final CourseRepository courseRepository;

    public EnrollmentWindowService(CourseRepository courseRepository) {
        this.courseRepository = courseRepository;
    }

    /**
     * Computes enrollment windows from existing course terms and academic years.
     * Windows are derived from the term's approximate start month and span a short registration period.
     */
    public List<EnrollmentWindowDTO> listEnrollmentWindows() {
        List<CourseRepository.TermYearView> distinctTerms = courseRepository.findDistinctTermsAndYears();
        List<EnrollmentWindowDTO> windows = new ArrayList<>();

        for (CourseRepository.TermYearView t : distinctTerms) {
            if (t.getTerm() == null || t.getAcademicYear() == null) continue;
            String term = t.getTerm();
            int year = t.getAcademicYear();

            int startMonth = startMonthForTerm(term);
            LocalDate anchor = LocalDate.of(year, startMonth, 1);
            OffsetDateTime opensAt = anchor.minusWeeks(8).atTime(LocalTime.of(8, 0)).atOffset(ZoneOffset.UTC);
            OffsetDateTime closesAt = anchor.minusDays(1).atTime(LocalTime.of(23, 59)).atOffset(ZoneOffset.UTC);

            String priority = "Open enrollment";
            String note = "Derived from catalog term; confirm with registrar if dates differ.";

            windows.add(new EnrollmentWindowDTO(term, year, opensAt, closesAt, priority, note));
        }

        return windows;
    }

    private int startMonthForTerm(String term) {
        String upper = term.toUpperCase();
        if (upper.contains("SPRING")) return 1;
        if (upper.contains("SUMMER")) return 6;
        if (upper.contains("FALL") || upper.contains("AUTUMN")) return 8;
        if (upper.contains("WINTER")) return 12;
        return 1;
    }
}
