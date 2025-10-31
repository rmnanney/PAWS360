package com.uwm.paws360.Service;

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
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class AdvisingService {

    private final StudentRepository studentRepository;
    private final AdvisorRepository advisorRepository;
    private final StudentAdvisorRepository studentAdvisorRepository;
    private final AdvisorAppointmentRepository appointmentRepository;

    public AdvisingService(StudentRepository studentRepository,
                           AdvisorRepository advisorRepository,
                           StudentAdvisorRepository studentAdvisorRepository,
                           AdvisorAppointmentRepository appointmentRepository) {
        this.studentRepository = studentRepository;
        this.advisorRepository = advisorRepository;
        this.studentAdvisorRepository = studentAdvisorRepository;
        this.appointmentRepository = appointmentRepository;
    }

    public AdvisorDTO getPrimaryAdvisor(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        StudentAdvisor link = studentAdvisorRepository.findFirstByStudentAndPrimaryAdvisorIsTrue(s)
                .orElseThrow(() -> new EntityNotFoundException("Primary advisor not assigned for student " + studentId));
        Advisor a = link.getAdvisor();
        String name = a.getUser().getFirstname() + " " + a.getUser().getLastname();
        String email = a.getUser().getEmail();
        String phone = a.getUser().getPhone();
        String dept = a.getDepartment() != null ? a.getDepartment().name() : null;
        return new AdvisorDTO(a.getId(), name, "Academic Advisor", dept, email, phone, a.getOfficeLocation(), "Mon-Fri 9AM-5PM");
    }

    public List<AdvisorDTO> listAdvisors() {
        return advisorRepository.findAll().stream().map(a ->
                new AdvisorDTO(a.getId(), a.getUser().getFirstname() + " " + a.getUser().getLastname(),
                        "Advisor", a.getDepartment() != null ? a.getDepartment().name() : null,
                        a.getUser().getEmail(), a.getUser().getPhone(), a.getOfficeLocation(), "Mon-Fri 9AM-5PM")
        ).collect(Collectors.toList());
    }

    public List<AppointmentDTO> upcomingAppointments(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        return appointmentRepository.findByStudentAndScheduledAtAfterOrderByScheduledAtAsc(s, OffsetDateTime.now())
                .stream()
                .map(appt -> new AppointmentDTO(
                        appt.getId(),
                        appt.getScheduledAt(),
                        appt.getAdvisor().getUser().getFirstname() + " " + appt.getAdvisor().getUser().getLastname(),
                        appt.getType(),
                        appt.getLocation(),
                        appt.getStatus(),
                        appt.getNotes()
                ))
                .collect(Collectors.toList());
    }
}

