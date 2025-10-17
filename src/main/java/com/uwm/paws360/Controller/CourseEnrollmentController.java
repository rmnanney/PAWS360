package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Course.CourseEnrollmentRequest;
import com.uwm.paws360.DTO.Course.CourseEnrollmentResponse;
import com.uwm.paws360.DTO.Course.DropEnrollmentRequest;
import com.uwm.paws360.DTO.Course.SwitchLabRequest;
import com.uwm.paws360.Service.CourseEnrollmentService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;

@RestController
@RequestMapping("/enrollments")
public class CourseEnrollmentController {

    private final CourseEnrollmentService courseEnrollmentService;

    public CourseEnrollmentController(CourseEnrollmentService courseEnrollmentService) {
        this.courseEnrollmentService = courseEnrollmentService;
    }

    @PostMapping("/enroll")
    public ResponseEntity<CourseEnrollmentResponse> enroll(@Valid @RequestBody CourseEnrollmentRequest request) {
        return ResponseEntity.ok(courseEnrollmentService.enrollStudent(request));
    }

    @PostMapping("/drop")
    public ResponseEntity<CourseEnrollmentResponse> drop(@Valid @RequestBody DropEnrollmentRequest request) {
        return ResponseEntity.ok(courseEnrollmentService.dropEnrollment(request));
    }

    @PostMapping("/switch-lab")
    public ResponseEntity<CourseEnrollmentResponse> switchLab(@Valid @RequestBody SwitchLabRequest request) {
        return ResponseEntity.ok(courseEnrollmentService.switchLab(request));
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<CourseEnrollmentResponse>> listStudentEnrollments(@PathVariable Integer studentId) {
        return ResponseEntity.ok(courseEnrollmentService.listEnrollmentsForStudent(studentId));
    }
}
