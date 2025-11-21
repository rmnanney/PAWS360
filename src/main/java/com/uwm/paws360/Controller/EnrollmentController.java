package com.uwm.paws360.Controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.LocalTime;
import java.util.*;

@RestController
@RequestMapping("/api/enrollment")
public class EnrollmentController {

    private final JdbcTemplate jdbcTemplate;
    private static final int MAX_CREDITS_PER_SEMESTER = 13;

    public EnrollmentController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostMapping("/validate")
    public Map<String, Object> validateEnrollment(@RequestBody Map<String, Object> request) {
        Integer studentId = (Integer) request.get("studentId");
        String courseCode = (String) request.get("courseCode");
        String instructor = (String) request.get("instructor");
        String meetingPattern = (String) request.get("meetingPattern");
        
        Map<String, Object> response = new HashMap<>();
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        
        try {
            // Get course details from courses table
            String courseQuery = 
                "SELECT course_id, credits, meeting_pattern, total_seats, subject, course_number, " +
                "start_date, end_date, term FROM courses " +
                "WHERE course_code = ? AND instructor = ? AND meeting_pattern = ? LIMIT 1";
            
            List<Map<String, Object>> courseResults = jdbcTemplate.queryForList(
                courseQuery, courseCode, instructor, meetingPattern
            );
            
            if (courseResults.isEmpty()) {
                errors.add("Course not found");
                response.put("valid", false);
                response.put("errors", errors);
                return response;
            }
            
            Map<String, Object> course = courseResults.get(0);
            Integer courseId = (Integer) course.get("course_id");
            Double credits = course.get("credits") != null ? 
                ((Number) course.get("credits")).doubleValue() : 0.0;
            Integer totalSeats = (Integer) course.get("total_seats");
            String term = (String) course.get("term");
            
            // 1. Check if already enrolled in this exact course
            String enrolledCheckQuery = 
                "SELECT COUNT(*) FROM course_enrollments ce " +
                "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                "WHERE ce.student_id = ? AND cs.course_id = ? " +
                "AND ce.status IN ('ENROLLED', 'WAITLISTED')";
            
            Integer enrolledCount = jdbcTemplate.queryForObject(
                enrolledCheckQuery, Integer.class, studentId, courseId
            );
            
            if (enrolledCount != null && enrolledCount > 0) {
                errors.add("You are already enrolled in this course");
            }
            
            // 2. Check if already completed the course
            String completedCheckQuery = 
                "SELECT ce.final_letter FROM course_enrollments ce " +
                "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                "WHERE ce.student_id = ? AND cs.course_id = ? " +
                "AND ce.status = 'COMPLETED' " +
                "ORDER BY ce.completed_at DESC LIMIT 1";
            
            List<Map<String, Object>> completedResults = jdbcTemplate.queryForList(
                completedCheckQuery, studentId, courseId
            );
            
            if (!completedResults.isEmpty()) {
                String finalGrade = (String) completedResults.get(0).get("final_letter");
                if (finalGrade != null && !finalGrade.equals("F") && !finalGrade.equals("W")) {
                    errors.add("You have already successfully completed this course with grade: " + finalGrade);
                }
            }
            
            // 3. Check prerequisites
            String prereqQuery = 
                "SELECT cp.prerequisite_course_id, cp.minimum_grade, cp.concurrent_allowed, " +
                "c.course_code, c.title " +
                "FROM course_prerequisites cp " +
                "JOIN courses c ON cp.prerequisite_course_id = c.course_id " +
                "WHERE cp.course_id = ?";
            
            List<Map<String, Object>> prerequisites = jdbcTemplate.queryForList(prereqQuery, courseId);
            
            for (Map<String, Object> prereq : prerequisites) {
                Integer prereqCourseId = (Integer) prereq.get("prerequisite_course_id");
                String minimumGrade = (String) prereq.get("minimum_grade");
                Boolean concurrentAllowed = (Boolean) prereq.get("concurrent_allowed");
                String prereqCourseCode = (String) prereq.get("course_code");
                String prereqTitle = (String) prereq.get("title");
                
                // Check if student has completed prerequisite
                String prereqCompletedQuery = 
                    "SELECT ce.final_letter FROM course_enrollments ce " +
                    "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                    "WHERE ce.student_id = ? AND cs.course_id = ? " +
                    "AND ce.status = 'COMPLETED' " +
                    "ORDER BY ce.completed_at DESC LIMIT 1";
                
                List<Map<String, Object>> prereqCompleted = jdbcTemplate.queryForList(
                    prereqCompletedQuery, studentId, prereqCourseId
                );
                
                if (prereqCompleted.isEmpty()) {
                    // Check if concurrently enrolled
                    if (Boolean.TRUE.equals(concurrentAllowed)) {
                        String concurrentQuery = 
                            "SELECT COUNT(*) FROM course_enrollments ce " +
                            "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                            "WHERE ce.student_id = ? AND cs.course_id = ? " +
                            "AND ce.status IN ('ENROLLED', 'WAITLISTED')";
                        
                        Integer concurrentCount = jdbcTemplate.queryForObject(
                            concurrentQuery, Integer.class, studentId, prereqCourseId
                        );
                        
                        if (concurrentCount == null || concurrentCount == 0) {
                            errors.add("Missing prerequisite: " + prereqCourseCode + " - " + prereqTitle + 
                                     " (may be taken concurrently)");
                        }
                    } else {
                        errors.add("Missing prerequisite: " + prereqCourseCode + " - " + prereqTitle);
                    }
                } else {
                    // Check grade requirement
                    String earnedGrade = (String) prereqCompleted.get(0).get("final_letter");
                    if (minimumGrade != null && !meetsGradeRequirement(earnedGrade, minimumGrade)) {
                        errors.add("Insufficient grade in prerequisite " + prereqCourseCode + 
                                 ". Required: " + minimumGrade + ", Earned: " + earnedGrade);
                    }
                }
            }
            
            // 4. Check for failed course twice
            String failCountQuery = 
                "SELECT COUNT(*) FROM course_enrollments ce " +
                "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                "WHERE ce.student_id = ? AND cs.course_id = ? " +
                "AND ce.status = 'COMPLETED' AND ce.final_letter = 'F'";
            
            Integer failCount = jdbcTemplate.queryForObject(failCountQuery, Integer.class, studentId, courseId);
            
            if (failCount != null && failCount >= 2) {
                errors.add("You have failed this course twice and cannot re-enroll");
            }
            
            // 5. Check for schedule conflicts
            // First, get the meeting times for this course
            String meetingTimesQuery = 
                "SELECT cs.start_time, cs.end_time, csmd.meeting_day " +
                "FROM course_sections cs " +
                "JOIN course_section_meeting_days csmd ON cs.section_id = csmd.section_id " +
                "WHERE cs.course_id = ? " +
                "AND cs.term = ? " +
                "LIMIT 10";
            
            List<Map<String, Object>> newCourseTimes = jdbcTemplate.queryForList(
                meetingTimesQuery, courseId, term
            );
            
            if (!newCourseTimes.isEmpty()) {
                // Get student's current enrolled courses with times
                String currentScheduleQuery = 
                    "SELECT c.course_code, cs.start_time, cs.end_time, csmd.meeting_day " +
                    "FROM course_enrollments ce " +
                    "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                    "JOIN courses c ON cs.course_id = c.course_id " +
                    "JOIN course_section_meeting_days csmd ON cs.section_id = csmd.section_id " +
                    "WHERE ce.student_id = ? " +
                    "AND ce.status = 'ENROLLED' " +
                    "AND cs.term = ?";
                
                List<Map<String, Object>> currentSchedule = jdbcTemplate.queryForList(
                    currentScheduleQuery, studentId, term
                );
                
                for (Map<String, Object> newTime : newCourseTimes) {
                    LocalTime newStart = (LocalTime) newTime.get("start_time");
                    LocalTime newEnd = (LocalTime) newTime.get("end_time");
                    String newDay = (String) newTime.get("meeting_day");
                    
                    if (newStart == null || newEnd == null) continue;
                    
                    for (Map<String, Object> currentTime : currentSchedule) {
                        String currentDay = (String) currentTime.get("meeting_day");
                        
                        if (newDay.equals(currentDay)) {
                            LocalTime currentStart = (LocalTime) currentTime.get("start_time");
                            LocalTime currentEnd = (LocalTime) currentTime.get("end_time");
                            
                            if (currentStart != null && currentEnd != null) {
                                if (timesOverlap(newStart, newEnd, currentStart, currentEnd)) {
                                    String conflictCourse = (String) currentTime.get("course_code");
                                    errors.add("Schedule conflict: This course conflicts with " + 
                                             conflictCourse + " on " + newDay);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            
            // 6. Check credit limit
            String currentCreditsQuery = 
                "SELECT COALESCE(SUM(c.credits), 0) " +
                "FROM course_enrollments ce " +
                "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
                "JOIN courses c ON cs.course_id = c.course_id " +
                "WHERE ce.student_id = ? " +
                "AND ce.status = 'ENROLLED' " +
                "AND cs.term = ?";
            
            Double currentCredits = jdbcTemplate.queryForObject(
                currentCreditsQuery, Double.class, studentId, term
            );
            
            if (currentCredits == null) currentCredits = 0.0;
            
            if (currentCredits + credits > MAX_CREDITS_PER_SEMESTER) {
                errors.add("Enrolling in this course would exceed the " + MAX_CREDITS_PER_SEMESTER + 
                         " credit limit. Current: " + currentCredits + ", Course: " + credits);
            }
            
            // 7. Check if course is full
            if (totalSeats != null) {
                String enrollmentCountQuery = 
                    "SELECT COUNT(*) FROM course_enrollments ce " +
                    "WHERE ce.lecture_section_id IN ( " +
                    "  SELECT section_id FROM course_sections " +
                    "  WHERE course_id = ? " +
                    ") " +
                    "AND ce.status = 'ENROLLED'";
                
                Integer currentEnrollment = jdbcTemplate.queryForObject(
                    enrollmentCountQuery, Integer.class, courseId
                );
                
                if (currentEnrollment != null && currentEnrollment >= totalSeats) {
                    errors.add("This course section is full (" + currentEnrollment + "/" + totalSeats + " seats)");
                }
            }
            
            // 8. Check enrollment period (simplified - you may want to add a dedicated table)
            // For now, we'll just add a warning
            warnings.add("Please ensure enrollment period is currently active");
            
            response.put("valid", errors.isEmpty());
            response.put("errors", errors);
            response.put("warnings", warnings);
            response.put("courseDetails", course);
            
        } catch (Exception e) {
            errors.add("Validation error: " + e.getMessage());
            response.put("valid", false);
            response.put("errors", errors);
        }
        
        return response;
    }

    @PostMapping("/enroll")
    public Map<String, Object> enrollStudent(@RequestBody Map<String, Object> request) {
        Integer studentId = (Integer) request.get("studentId");
        String courseCode = (String) request.get("courseCode");
        String instructor = (String) request.get("instructor");
        String meetingPattern = (String) request.get("meetingPattern");
        
        Map<String, Object> response = new HashMap<>();
        
        try {
            // First validate
            Map<String, Object> validation = validateEnrollment(request);
            
            if (!(Boolean) validation.get("valid")) {
                return validation;
            }
            
            // Get the course details from courses table
            String courseQuery = 
                "SELECT course_id, section, term FROM courses " +
                "WHERE course_code = ? " +
                "AND instructor = ? " +
                "AND meeting_pattern = ? " +
                "LIMIT 1";
            
            List<Map<String, Object>> courseResults = jdbcTemplate.queryForList(
                courseQuery, courseCode, instructor, meetingPattern
            );
            
            if (courseResults.isEmpty()) {
                response.put("success", false);
                response.put("error", "Course not found in catalog");
                return response;
            }
            
            Map<String, Object> course = courseResults.get(0);
            Integer courseId = (Integer) course.get("course_id");
            String sectionCode = (String) course.get("section");
            String term = (String) course.get("term");
            
            // Check if a course_section already exists for this course
            String sectionCheckQuery = 
                "SELECT section_id FROM course_sections " +
                "WHERE course_id = ? AND section_code = ? AND term = ? LIMIT 1";
            
            List<Map<String, Object>> sectionResults = jdbcTemplate.queryForList(
                sectionCheckQuery, courseId, sectionCode, term
            );
            
            Long sectionId;
            
            if (sectionResults.isEmpty()) {
                // Create a course_section entry for this course
                String createSectionQuery = 
                    "INSERT INTO course_sections " +
                    "(course_id, section_code, term, academic_year, section_type, " +
                    "auto_enroll_waitlist, consent_required, created_at, updated_at) " +
                    "VALUES (?, ?, ?, 2025, 'LECTURE', false, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) " +
                    "RETURNING section_id";
                
                try {
                    sectionId = jdbcTemplate.queryForObject(
                        createSectionQuery, Long.class, courseId, sectionCode, term
                    );
                } catch (Exception e) {
                    // If there's a unique constraint violation, try to find the section that was just created
                    List<Map<String, Object>> retryResults = jdbcTemplate.queryForList(
                        sectionCheckQuery, courseId, sectionCode, term
                    );
                    if (!retryResults.isEmpty()) {
                        sectionId = ((Number) retryResults.get(0).get("section_id")).longValue();
                    } else {
                        throw e;
                    }
                }
            } else {
                sectionId = ((Number) sectionResults.get(0).get("section_id")).longValue();
            }
            
            // Insert enrollment
            String insertQuery = 
                "INSERT INTO course_enrollments " +
                "(student_id, lecture_section_id, status, enrolled_at, updated_at, auto_enrolled_from_waitlist) " +
                "VALUES (?, ?, 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, false)";
            
            jdbcTemplate.update(insertQuery, studentId, sectionId);
            
            response.put("success", true);
            response.put("message", "Successfully enrolled in " + courseCode);
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Enrollment failed: " + e.getMessage());
        }
        
        return response;
    }

    private boolean meetsGradeRequirement(String earnedGrade, String minimumGrade) {
        if (earnedGrade == null || minimumGrade == null) return false;
        
        Map<String, Integer> gradeValues = new HashMap<>();
        gradeValues.put("A", 12);
        gradeValues.put("A-", 11);
        gradeValues.put("B+", 10);
        gradeValues.put("B", 9);
        gradeValues.put("B-", 8);
        gradeValues.put("C+", 7);
        gradeValues.put("C", 6);
        gradeValues.put("C-", 5);
        gradeValues.put("D+", 4);
        gradeValues.put("D", 3);
        gradeValues.put("D-", 2);
        gradeValues.put("F", 0);
        
        Integer earnedValue = gradeValues.get(earnedGrade);
        Integer requiredValue = gradeValues.get(minimumGrade);
        
        if (earnedValue == null || requiredValue == null) return false;
        
        return earnedValue >= requiredValue;
    }

    private boolean timesOverlap(LocalTime start1, LocalTime end1, LocalTime start2, LocalTime end2) {
        return start1.isBefore(end2) && start2.isBefore(end1);
    }
}
