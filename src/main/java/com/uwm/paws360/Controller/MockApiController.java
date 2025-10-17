package com.uwm.paws360.Controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class MockApiController {

    @GetMapping("/classes/")
    public ResponseEntity<Map<String, Object>> getClasses() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "classes-api-mock");

        List<Map<String, Object>> classes = Arrays.asList(
            Map.of("id", 1, "name", "Introduction to Computer Science", "code", "CS101"),
            Map.of("id", 2, "name", "Data Structures", "code", "CS201"),
            Map.of("id", 3, "name", "Calculus I", "code", "MATH201")
        );
        response.put("classes", classes);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/student/planning/")
    public ResponseEntity<Map<String, Object>> getStudentPlanning() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "planning-api-mock");
        
        Map<String, Object> student = new HashMap<>();
        student.put("id", 12345);
        student.put("name", "John Doe");
        student.put("major", "Computer Science");
        
        List<Map<String, Object>> courses = Arrays.asList(
            Map.of("code", "CS101", "credits", 3),
            Map.of("code", "MATH201", "credits", 4)
        );
        student.put("courses", courses);
        response.put("student", student);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/instructor/courses/")
    public ResponseEntity<Map<String, Object>> getInstructorCourses() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "instructor-api-mock");
        
        List<Map<String, Object>> courses = Arrays.asList(
            Map.of("id", 1, "code", "CS101", "students", 25),
            Map.of("id", 2, "code", "CS201", "students", 18)
        );
        response.put("courses", courses);

        return ResponseEntity.ok(response);
    }
}
