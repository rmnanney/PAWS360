package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Course.EnrollmentWindowDTO;
import com.uwm.paws360.Service.EnrollmentWindowService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/enrollment")
public class EnrollmentWindowController {

    private final EnrollmentWindowService enrollmentWindowService;

    public EnrollmentWindowController(EnrollmentWindowService enrollmentWindowService) {
        this.enrollmentWindowService = enrollmentWindowService;
    }

    @GetMapping("/windows")
    public ResponseEntity<List<EnrollmentWindowDTO>> windows() {
        return ResponseEntity.ok(enrollmentWindowService.listEnrollmentWindows());
    }
}
