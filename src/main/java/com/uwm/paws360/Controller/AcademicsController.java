package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Academics.*;
import com.uwm.paws360.Service.AcademicsService;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/academics")
public class AcademicsController {

    private final AcademicsService academicsService;

    public AcademicsController(AcademicsService academicsService) {
        this.academicsService = academicsService;
    }

    @GetMapping("/student/{studentId}/summary")
    public ResponseEntity<AcademicSummaryResponseDTO> getSummary(@PathVariable Integer studentId) {
        return ResponseEntity.ok(academicsService.getSummary(studentId));
    }

    @GetMapping("/student/{studentId}/current-grades")
    public ResponseEntity<Map<String, Object>> getCurrentGrades(
            @PathVariable Integer studentId,
            @RequestParam(value = "term", required = false) String term,
            @RequestParam(value = "year", required = false) Integer year
    ) {
        return ResponseEntity.ok(academicsService.getCurrentGrades(studentId, term, year));
    }

    @GetMapping("/student/{studentId}/transcript")
    public ResponseEntity<TranscriptResponseDTO> getTranscript(@PathVariable Integer studentId) {
        return ResponseEntity.ok(academicsService.getTranscript(studentId));
    }

    @GetMapping("/student/{studentId}/tuition")
    public ResponseEntity<TuitionSummaryResponseDTO> getTuition(
            @PathVariable Integer studentId,
            @RequestParam(value = "term", required = false) String term,
            @RequestParam(value = "year", required = false) Integer year
    ) {
        return ResponseEntity.ok(academicsService.getTuition(studentId, term, year));
    }
}

