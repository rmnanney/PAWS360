package com.uwm.paws360.Controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
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

        if (subject != null && !subject.trim().isEmpty()) {
            sql.append(" AND UPPER(subject) LIKE UPPER('%").append(subject.replace("'", "''")).append("%')");
        }
        
        if (courseCode != null && !courseCode.trim().isEmpty()) {
            sql.append(" AND UPPER(REPLACE(course_code, ' ', '')) LIKE UPPER('%")
               .append(courseCode.replace("'", "''").replace(" ", "")).append("%')");
        }
        
        if (title != null && !title.trim().isEmpty()) {
            sql.append(" AND UPPER(title) LIKE UPPER('%").append(title.replace("'", "''")).append("%')");
        }
        
        if (meetingPattern != null && !meetingPattern.trim().isEmpty()) {
            sql.append(" AND UPPER(meeting_pattern) LIKE UPPER('%").append(meetingPattern.replace("'", "''")).append("%')");
        }

        sql.append(" ORDER BY subject, course_number LIMIT 100");

        return jdbcTemplate.queryForList(sql.toString());
    }
}
