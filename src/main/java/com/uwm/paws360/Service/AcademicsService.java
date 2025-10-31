package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Academics.*;
import com.uwm.paws360.Entity.Academics.DegreeProgram;
import com.uwm.paws360.Entity.Academics.DegreeRequirement;
import com.uwm.paws360.Entity.Academics.StudentProgram;
import com.uwm.paws360.Entity.Course.CourseEnrollment;
import com.uwm.paws360.Entity.Course.CourseSection;
import com.uwm.paws360.Entity.Course.Courses;
import com.uwm.paws360.Entity.EntityDomains.SectionEnrollmentStatus;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Academics.DegreeProgramRepository;
import com.uwm.paws360.JPARepository.Academics.DegreeRequirementRepository;
import com.uwm.paws360.JPARepository.Academics.StudentProgramRepository;
import com.uwm.paws360.JPARepository.Course.CourseEnrollmentRepository;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class AcademicsService {

    private final CourseEnrollmentRepository enrollmentRepository;
    private final StudentRepository studentRepository;
    private final StudentProgramRepository studentProgramRepository;
    private final DegreeRequirementRepository degreeRequirementRepository;
    private final DegreeProgramRepository degreeProgramRepository;

    public AcademicsService(CourseEnrollmentRepository enrollmentRepository,
                            StudentRepository studentRepository,
                            StudentProgramRepository studentProgramRepository,
                            DegreeRequirementRepository degreeRequirementRepository,
                            DegreeProgramRepository degreeProgramRepository) {
        this.enrollmentRepository = enrollmentRepository;
        this.studentRepository = studentRepository;
        this.studentProgramRepository = studentProgramRepository;
        this.degreeRequirementRepository = degreeRequirementRepository;
        this.degreeProgramRepository = degreeProgramRepository;
    }

    public AcademicSummaryResponseDTO getSummary(Integer studentId) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));

        List<CourseEnrollment> enrollments = enrollmentRepository.findByStudentId(studentId);

        // Completed enrollments are those with a final letter set or status COMPLETED
        List<CourseEnrollment> completed = enrollments.stream()
                .filter(e -> e.getFinalLetter() != null || e.getStatus() == SectionEnrollmentStatus.COMPLETED)
                .collect(Collectors.toList());

        double cumPoints = 0.0;
        int cumCredits = 0;
        Map<String, List<CourseEnrollment>> byTerm = new LinkedHashMap<>();
        for (CourseEnrollment e : completed) {
            CourseSection s = e.getLectureSection();
            Courses c = s.getCourse();
            int credits = c.getCreditHours() != null ? c.getCreditHours().intValue() : 0;
            double points = letterToPoints(e.getFinalLetter()) * credits;
            cumPoints += points;
            cumCredits += credits;
            byTerm.computeIfAbsent(termLabel(s), k -> new ArrayList<>()).add(e);
        }

        Double cumulativeGPA = cumCredits > 0 ? round2(cumPoints / cumCredits) : 0.0;
        Integer totalCredits = cumCredits;
        Integer semestersCompleted = byTerm.size();
        String academicStanding = cumulativeGPA >= 2.0 ? "Good Standing" : "Probation";

        // Current term GPA from latest term (if any) among enrollments with grades
        String currentTerm = latestTermLabel(enrollments.stream().map(CourseEnrollment::getLectureSection).collect(Collectors.toList()));
        Double currentTermGPA = null;
        if (currentTerm != null && byTerm.containsKey(currentTerm)) {
            List<CourseEnrollment> termCompleted = byTerm.get(currentTerm);
            double termPts = 0.0;
            int termCreds = 0;
            for (CourseEnrollment e : termCompleted) {
                int credits = e.getLectureSection().getCourse().getCreditHours().intValue();
                termPts += letterToPoints(e.getFinalLetter()) * credits;
                termCreds += credits;
            }
            currentTermGPA = termCreds > 0 ? round2(termPts / termCreds) : null;
        }

        // Graduation progress (very simplified): completed credits / program required
        List<StudentProgram> programs = studentProgramRepository.findByStudent(student);
        Integer graduationProgress = 0;
        String expectedGrad = null;
        if (!programs.isEmpty()) {
            StudentProgram primary = programs.stream().filter(StudentProgram::isPrimary).findFirst().orElse(programs.get(0));
            DegreeProgram program = primary.getProgram();
            int requiredCredits = program != null && program.getTotalCreditsRequired() != null ? program.getTotalCreditsRequired() : 120;
            graduationProgress = requiredCredits > 0 ? (int) Math.min(100, Math.round((totalCredits * 100.0) / requiredCredits)) : 0;
            if (primary.getExpectedGraduationTerm() != null && primary.getExpectedGraduationYear() != null) {
                expectedGrad = primary.getExpectedGraduationTerm() + " " + primary.getExpectedGraduationYear();
            }
        }

        return new AcademicSummaryResponseDTO(
                cumulativeGPA,
                totalCredits,
                semestersCompleted,
                academicStanding,
                graduationProgress,
                expectedGrad,
                currentTermGPA,
                currentTerm
        );
    }

    public Map<String, Object> getCurrentGrades(Integer studentId, String term, Integer year) {
        List<CourseEnrollment> enrollments = enrollmentRepository.findByStudentId(studentId);
        // Determine target term
        String targetTerm;
        if (term != null && year != null) {
            targetTerm = term + " " + year;
        } else {
            targetTerm = latestTermLabel(enrollments.stream().map(CourseEnrollment::getLectureSection).collect(Collectors.toList()));
        }

        List<CurrentGradeDTO> grades = enrollments.stream()
                .filter(e -> e.getStatus() == SectionEnrollmentStatus.ENROLLED)
                .filter(e -> targetTerm == null || Objects.equals(termLabel(e.getLectureSection()), targetTerm))
                .map(e -> {
                    Courses c = e.getLectureSection().getCourse();
                    String last = e.getLastGradeUpdate() != null ? e.getLastGradeUpdate().toString() : null;
                    Integer credits = c.getCreditHours() != null ? c.getCreditHours().intValue() : 0;
                    return new CurrentGradeDTO(
                            c.getCourseCode(),
                            c.getCourseName(),
                            e.getCurrentLetter(),
                            credits,
                            e.getCurrentPercentage(),
                            e.getStatus().name(),
                            last
                    );
                })
                .collect(Collectors.toList());
        Map<String, Object> out = new HashMap<>();
        out.put("termLabel", targetTerm);
        out.put("grades", grades);
        return out;
    }

    public TranscriptResponseDTO getTranscript(Integer studentId) {
        List<CourseEnrollment> enrollments = enrollmentRepository.findByStudentId(studentId);
        // Group by term label for completed/graded enrollments
        Map<String, List<CourseEnrollment>> byTerm = enrollments.stream()
                .filter(e -> e.getFinalLetter() != null || e.getStatus() == SectionEnrollmentStatus.COMPLETED)
                .collect(Collectors.groupingBy(e -> termLabel(e.getLectureSection()), LinkedHashMap::new, Collectors.toList()));

        List<TranscriptTermDTO> terms = new ArrayList<>();
        for (Map.Entry<String, List<CourseEnrollment>> entry : sortByTerm(byTerm).entrySet()) {
            String label = entry.getKey();
            List<CourseEnrollment> list = entry.getValue();
            double pts = 0.0;
            int creds = 0;
            List<TranscriptCourseDTO> courses = new ArrayList<>();
            for (CourseEnrollment e : list) {
                Courses c = e.getLectureSection().getCourse();
                int cr = c.getCreditHours() != null ? c.getCreditHours().intValue() : 0;
                creds += cr;
                pts += letterToPoints(e.getFinalLetter()) * cr;
                courses.add(new TranscriptCourseDTO(c.getCourseCode(), c.getCourseName(), e.getFinalLetter(), cr));
            }
            Double gpa = creds > 0 ? round2(pts / creds) : 0.0;
            terms.add(new TranscriptTermDTO(label, gpa, creds, courses));
        }
        return new TranscriptResponseDTO(terms);
    }

    public TuitionSummaryResponseDTO getTuition(Integer studentId, String term, Integer year) {
        List<CourseEnrollment> enrollments = enrollmentRepository.findByStudentId(studentId);
        String targetTerm = term != null && year != null ? term + " " + year
                : latestTermLabel(enrollments.stream().map(CourseEnrollment::getLectureSection).collect(Collectors.toList()));

        List<TuitionItemDTO> items = new ArrayList<>();
        BigDecimal total = BigDecimal.ZERO;
        for (CourseEnrollment e : enrollments) {
            if (e.getStatus() != SectionEnrollmentStatus.ENROLLED) continue;
            if (targetTerm != null && !Objects.equals(termLabel(e.getLectureSection()), targetTerm)) continue;
            Courses c = e.getLectureSection().getCourse();
            BigDecimal cost = c.getCourseCost() != null ? c.getCourseCost() : BigDecimal.ZERO;
            items.add(new TuitionItemDTO(c.getCourseCode(), c.getCourseName(), cost));
            total = total.add(cost);
        }
        return new TuitionSummaryResponseDTO(targetTerm, total, items);
    }

    // Helpers
    private double letterToPoints(String letter) {
        if (letter == null) return 0.0;
        return switch (letter.trim().toUpperCase()) {
            case "A" -> 4.0;
            case "A-" -> 3.7;
            case "B+" -> 3.3;
            case "B" -> 3.0;
            case "B-" -> 2.7;
            case "C+" -> 2.3;
            case "C" -> 2.0;
            case "C-" -> 1.7;
            case "D+" -> 1.3;
            case "D" -> 1.0;
            case "F" -> 0.0;
            default -> 0.0;
        };
    }

    private String termLabel(CourseSection s) {
        if (s == null) return null;
        return (s.getTerm() != null ? s.getTerm() : "") + " " + (s.getAcademicYear() != null ? s.getAcademicYear() : "");
    }

    private String latestTermLabel(List<CourseSection> sections) {
        if (sections == null || sections.isEmpty()) return null;
        return sections.stream()
                .filter(Objects::nonNull)
                .sorted((a, b) -> {
                    int ya = a.getAcademicYear() == null ? 0 : a.getAcademicYear();
                    int yb = b.getAcademicYear() == null ? 0 : b.getAcademicYear();
                    if (ya != yb) return Integer.compare(yb, ya);
                    return Integer.compare(termOrder(b.getTerm()), termOrder(a.getTerm()));
                })
                .map(this::termLabel)
                .filter(l -> l != null && !l.trim().isEmpty())
                .findFirst()
                .orElse(null);
    }

    private int termOrder(String term) {
        if (term == null) return 0;
        return switch (term.toLowerCase()) {
            case "spring" -> 1;
            case "summer" -> 2;
            case "fall" -> 3;
            default -> 0;
        };
    }

    private Double round2(double v) {
        return BigDecimal.valueOf(v).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }

    private LinkedHashMap<String, List<CourseEnrollment>> sortByTerm(Map<String, List<CourseEnrollment>> in) {
        return in.entrySet().stream()
                .sorted((e1, e2) -> compareTermLabels(e2.getKey(), e1.getKey()))
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue,
                        (a, b) -> a, LinkedHashMap::new));
    }

    private int compareTermLabels(String a, String b) {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        try {
            String[] ap = a.split(" ");
            String[] bp = b.split(" ");
            int ay = Integer.parseInt(ap[ap.length - 1]);
            int by = Integer.parseInt(bp[bp.length - 1]);
            if (ay != by) return Integer.compare(ay, by);
            return Integer.compare(termOrder(ap[0]), termOrder(bp[0]));
        } catch (Exception ex) {
            return a.compareTo(b);
        }
    }
}
