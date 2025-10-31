package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Advising.AdvisorDTO;
import com.uwm.paws360.DTO.Advising.AppointmentDTO;
import com.uwm.paws360.Service.AdvisingService;
import org.springframework.http.ResponseEntity;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/advising")
public class AdvisingController {

    private final AdvisingService advisingService;

    public AdvisingController(AdvisingService advisingService) {
        this.advisingService = advisingService;
    }

    @GetMapping("/student/{studentId}/advisor")
    public ResponseEntity<AdvisorDTO> primaryAdvisor(@PathVariable Integer studentId) {
        return ResponseEntity.ok(advisingService.getPrimaryAdvisor(studentId));
    }

    @GetMapping("/student/{studentId}/appointments")
    public ResponseEntity<List<AppointmentDTO>> appointments(@PathVariable Integer studentId) {
        return ResponseEntity.ok(advisingService.upcomingAppointments(studentId));
    }

    @GetMapping("/advisors")
    public ResponseEntity<List<AdvisorDTO>> advisors() {
        return ResponseEntity.ok(advisingService.listAdvisors());
    }

    // Simple messaging endpoints
    @GetMapping("/student/{studentId}/messages")
    public ResponseEntity<java.util.List<com.uwm.paws360.DTO.Advising.MessageDTO>> messages(@PathVariable Integer studentId) {
        return ResponseEntity.ok(advisingService.listMessages(studentId));
    }

    @PostMapping("/student/{studentId}/messages")
    public ResponseEntity<com.uwm.paws360.DTO.Advising.MessageDTO> sendMessage(
            @PathVariable Integer studentId,
            @Valid @RequestBody com.uwm.paws360.DTO.Advising.CreateMessageRequestDTO req) {
        return ResponseEntity.ok(advisingService.sendMessage(studentId, req.advisorId(), req.content()));
    }
}

