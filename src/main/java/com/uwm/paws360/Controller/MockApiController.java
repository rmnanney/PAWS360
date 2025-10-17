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
            Map.of("id", 3, "name", "Algorithms", "code", "CS301")
        );
        response.put("classes", classes);

        return ResponseEntity.ok(response);
    }
}