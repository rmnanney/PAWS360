package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Advising.AssignAdvisorRequestDTO;
import com.uwm.paws360.DTO.Advising.CreateAppointmentRequestDTO;
import com.uwm.paws360.DTO.Advising.AdvisorDTO;
import com.uwm.paws360.DTO.Advising.AppointmentDTO;
import com.uwm.paws360.Entity.Advising.AdvisorAppointment;
import com.uwm.paws360.Entity.Advising.StudentAdvisor;
import com.uwm.paws360.Entity.UserTypes.Advisor;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Advising.AdvisorAppointmentRepository;
import com.uwm.paws360.JPARepository.Advising.StudentAdvisorRepository;
import com.uwm.paws360.JPARepository.User.AdvisorRepository;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/advising/admin")
public class AdvisingAdminController {

    private final StudentRepository studentRepository;
    private final AdvisorRepository advisorRepository;
    private final StudentAdvisorRepository studentAdvisorRepository;
    private final AdvisorAppointmentRepository appointmentRepository;

    public AdvisingAdminController(StudentRepository studentRepository,
                                   AdvisorRepository advisorRepository,
                                   StudentAdvisorRepository studentAdvisorRepository,
                                   AdvisorAppointmentRepository appointmentRepository) {
        this.studentRepository = studentRepository;
        this.advisorRepository = advisorRepository;
        this.studentAdvisorRepository = studentAdvisorRepository;
        this.appointmentRepository = appointmentRepository;
    }

    @PostMapping("/students/{studentId}/advisor")
    public ResponseEntity<AdvisorDTO> assignAdvisor(@PathVariable Integer studentId,
                                                    @Valid @RequestBody AssignAdvisorRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        Advisor a = advisorRepository.findById(req.advisorId())
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Advisor not found for id " + req.advisorId()));

        if (Boolean.TRUE.equals(req.primary())) {
            studentAdvisorRepository.findFirstByStudentAndPrimaryAdvisorIsTrue(s)
                    .ifPresent(existing -> { existing.setPrimaryAdvisor(false); studentAdvisorRepository.save(existing); });
        }

        StudentAdvisor link = new StudentAdvisor();
        link.setStudent(s);
        link.setAdvisor(a);
        link.setPrimaryAdvisor(Boolean.TRUE.equals(req.primary()));
        studentAdvisorRepository.save(link);

        String dept = a.getDepartment() != null ? a.getDepartment().name() : null;
        AdvisorDTO dto = new AdvisorDTO(a.getId(), a.getUser().getFirstname() + " " + a.getUser().getLastname(),
                "Advisor", dept, a.getUser().getEmail(), a.getUser().getPhone(), a.getOfficeLocation(), "Mon-Fri 9AM-5PM");
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/students/{studentId}/appointments")
    public ResponseEntity<AppointmentDTO> createAppointment(@PathVariable Integer studentId,
                                                            @Valid @RequestBody CreateAppointmentRequestDTO req) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        Advisor a = advisorRepository.findById(req.advisorId())
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Advisor not found for id " + req.advisorId()));

        AdvisorAppointment appt = new AdvisorAppointment();
        appt.setStudent(s);
        appt.setAdvisor(a);
        if (req.type() != null) appt.setType(req.type());
        if (req.status() != null) appt.setStatus(req.status());
        appt.setScheduledAt(req.scheduledAt());
        appt.setLocation(req.location());
        appt.setNotes(req.notes());
        AdvisorAppointment saved = appointmentRepository.save(appt);

        AppointmentDTO dto = new AppointmentDTO(saved.getId(), saved.getScheduledAt(),
                saved.getAdvisor().getUser().getFirstname() + " " + saved.getAdvisor().getUser().getLastname(),
                saved.getType(), saved.getLocation(), saved.getStatus(), saved.getNotes());
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/students/{studentId}/advisors")
    public ResponseEntity<List<AdvisorDTO>> listStudentAdvisors(@PathVariable Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Student not found for id " + studentId));
        List<AdvisorDTO> list = studentAdvisorRepository.findByStudent(s).stream().map(link -> {
            Advisor a = link.getAdvisor();
            String dept = a.getDepartment() != null ? a.getDepartment().name() : null;
            return new AdvisorDTO(a.getId(), a.getUser().getFirstname() + " " + a.getUser().getLastname(),
                    link.isPrimaryAdvisor() ? "Primary Advisor" : "Advisor",
                    dept, a.getUser().getEmail(), a.getUser().getPhone(), a.getOfficeLocation(), "Mon-Fri 9AM-5PM");
        }).collect(Collectors.toList());
        return ResponseEntity.ok(list);
    }
}

