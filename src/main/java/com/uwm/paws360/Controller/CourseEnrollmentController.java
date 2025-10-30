package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Course.*;
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
    public ResponseEntity<CourseEnrollmentResponseDTO> enroll(@Valid @RequestBody CourseEnrollmentRequestDTO request) {
        return ResponseEntity.ok(courseEnrollmentService.enrollStudent(request));
    }

    @PostMapping("/drop")
    public ResponseEntity<CourseEnrollmentResponseDTO> drop(@Valid @RequestBody DropEnrollmentRequestDTO request) {
        return ResponseEntity.ok(courseEnrollmentService.dropEnrollment(request));
    }

    @PostMapping("/switch-lab")
    public ResponseEntity<CourseEnrollmentResponseDTO> switchLab(@Valid @RequestBody SwitchLabRequestDTO request) {
        return ResponseEntity.ok(courseEnrollmentService.switchLab(request));
    }

    @GetMapping("/student/{studentId}")
    public ResponseEntity<List<CourseEnrollmentResponseDTO>> listStudentEnrollments(@PathVariable Integer studentId) {
        return ResponseEntity.ok(courseEnrollmentService.listEnrollmentsForStudent(studentId));
    }

    @PostMapping("/grade")
    public ResponseEntity<CourseEnrollmentResponseDTO> updateCurrentGrade(@Valid @RequestBody GradeUpdateRequestDTO request) {
        return ResponseEntity.ok(courseEnrollmentService.updateCurrentGrade(request));
    }

    @PostMapping("/finalize")
    public ResponseEntity<CourseEnrollmentResponseDTO> finalizeGrade(@Valid @RequestBody FinalizeGradeRequestDTO request) {
        return ResponseEntity.ok(courseEnrollmentService.finalizeGrade(request));
    }
}
