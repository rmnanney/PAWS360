package com.uwm.paws360.Controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.time.format.TextStyle;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/api/course-search")
public class CourseSearchController {

    private final JdbcTemplate jdbcTemplate;

    public CourseSearchController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public List<Map<String, Object>> searchCourses(
            @RequestParam(required = false) String subject,
            @RequestParam(required = false) String courseCode,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String meetingPattern) {

        StringBuilder sql = new StringBuilder(
                "SELECT DISTINCT course_code, subject, course_number, title, " +
                "meeting_pattern, instructor, credits, term, status " +
                "FROM courses WHERE 1=1"
        );

        List<Object> params = new java.util.ArrayList<>();

        if (subject != null && !subject.trim().isEmpty()) {
            sql.append(" AND UPPER(subject) LIKE UPPER(?)");
            params.add("%" + subject.trim() + "%");
        }
        
        if (courseCode != null && !courseCode.trim().isEmpty()) {
            sql.append(" AND UPPER(REPLACE(course_code, ' ', '')) LIKE UPPER(?)");
            params.add("%" + courseCode.trim().replace(" ", "") + "%");
        }
        
        if (title != null && !title.trim().isEmpty()) {
            sql.append(" AND UPPER(title) LIKE UPPER(?)");
            params.add("%" + title.trim() + "%");
        }
        
        if (meetingPattern != null && !meetingPattern.trim().isEmpty()) {
            sql.append(" AND UPPER(meeting_pattern) LIKE UPPER(?)");
            params.add("%" + meetingPattern.trim() + "%");
        }

        sql.append(" ORDER BY subject, course_number LIMIT 100");

        return jdbcTemplate.queryForList(sql.toString(), params.toArray());
    }

    @GetMapping("/student/{studentId}/today-schedule")
    public List<Map<String, Object>> getTodaySchedule(@PathVariable Integer studentId) {
        DayOfWeek today = DayOfWeek.from(java.time.OffsetDateTime.now());
        String dayName = today.getDisplayName(TextStyle.FULL, Locale.ENGLISH).toUpperCase();
        
        String sql = 
            "SELECT DISTINCT " +
            "  c.course_code, " +
            "  c.title, " +
            "  cs.start_time, " +
            "  cs.end_time, " +
            "  COALESCE(b.code || ' ' || cr.room_number, 'TBD') as room " +
            "FROM course_enrollments ce " +
            "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
            "JOIN courses c ON cs.course_id = c.course_id " +
            "LEFT JOIN course_section_meeting_days csmd ON cs.section_id = csmd.section_id " +
            "LEFT JOIN buildings b ON cs.building_id = b.building_id " +
            "LEFT JOIN classrooms cr ON cs.classroom_id = cr.classroom_id " +
            "WHERE ce.student_id = ? " +
            "  AND ce.status = 'ENROLLED' " +
            "  AND csmd.meeting_day = ? " +
            "ORDER BY cs.start_time";
        
        return jdbcTemplate.queryForList(sql, studentId, dayName);
    }

    @GetMapping("/student/{studentId}/all-enrolled")
    public List<Map<String, Object>> getAllEnrolled(@PathVariable Integer studentId) {
        String sql = 
            "SELECT DISTINCT " +
            "  c.course_code, " +
            "  c.title, " +
            "  c.credits, " +
            "  c.meeting_pattern, " +
            "  c.instructor, " +
            "  cs.start_time, " +
            "  cs.end_time, " +
            "  cs.section_code, " +
            "  COALESCE(b.code || ' ' || cr.room_number, 'TBD') as room " +
            "FROM course_enrollments ce " +
            "JOIN course_sections cs ON ce.lecture_section_id = cs.section_id " +
            "JOIN courses c ON cs.course_id = c.course_id " +
            "LEFT JOIN buildings b ON cs.building_id = b.building_id " +
            "LEFT JOIN classrooms cr ON cs.classroom_id = cr.classroom_id " +
            "WHERE ce.student_id = ? " +
            "  AND ce.status = 'ENROLLED' " +
            "ORDER BY c.course_code";
        
        return jdbcTemplate.queryForList(sql, studentId);
    }
}
