package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Advising.AdvisorDTO;
import com.uwm.paws360.DTO.Advising.AppointmentDTO;
import com.uwm.paws360.Entity.Advising.AdvisorAppointment;
import com.uwm.paws360.Entity.Advising.AdvisorMessage;
import com.uwm.paws360.Entity.Advising.StudentAdvisor;
import com.uwm.paws360.Entity.UserTypes.Advisor;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Advising.AdvisorAppointmentRepository;
import com.uwm.paws360.JPARepository.Advising.StudentAdvisorRepository;
import com.uwm.paws360.JPARepository.Advising.AdvisorMessageRepository;
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
    private final AdvisorMessageRepository messageRepository;

    public AdvisingService(StudentRepository studentRepository,
                           AdvisorRepository advisorRepository,
                           StudentAdvisorRepository studentAdvisorRepository,
                           AdvisorAppointmentRepository appointmentRepository,
                           AdvisorMessageRepository messageRepository) {
        this.studentRepository = studentRepository;
        this.advisorRepository = advisorRepository;
        this.studentAdvisorRepository = studentAdvisorRepository;
        this.appointmentRepository = appointmentRepository;
        this.messageRepository = messageRepository;
    }

    public AdvisorDTO getPrimaryAdvisor(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        return studentAdvisorRepository.findFirstByStudentAndPrimaryAdvisorIsTrue(s)
                .map(link -> {
                    Advisor a = link.getAdvisor();
                    String name = a.getUser().getFirstname() + " " + a.getUser().getLastname();
                    String email = a.getUser().getEmail();
                    String phone = a.getUser().getPhone();
                    String dept = a.getDepartment() != null ? a.getDepartment().name() : null;
                    return new AdvisorDTO(a.getId(), name, "Academic Advisor", dept, email, phone, a.getOfficeLocation(), "Mon-Fri 9AM-5PM");
                })
                .orElse(null);
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

    public java.util.List<com.uwm.paws360.DTO.Advising.MessageDTO> listMessages(Integer studentId) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        return messageRepository.findByStudentOrderBySentAtAsc(s).stream().map(m -> new com.uwm.paws360.DTO.Advising.MessageDTO(
                m.getId(),
                s.getId(),
                m.getAdvisor().getId(),
                m.getAdvisor().getUser().getFirstname() + " " + m.getAdvisor().getUser().getLastname(),
                m.getSender().name(),
                m.getContent(),
                m.getSentAt()
        )).collect(Collectors.toList());
    }

    @Transactional
    public com.uwm.paws360.DTO.Advising.MessageDTO sendMessage(Integer studentId, Integer advisorId, String content) {
        Student s = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        Advisor a = advisorRepository.findById(advisorId)
                .orElseThrow(() -> new EntityNotFoundException("Advisor not found for id " + advisorId));
        AdvisorMessage msg = new AdvisorMessage();
        msg.setStudent(s);
        msg.setAdvisor(a);
        msg.setSender(AdvisorMessage.Sender.STUDENT);
        msg.setContent(content);
        msg.setSentAt(OffsetDateTime.now());
        AdvisorMessage saved = messageRepository.save(msg);
        return new com.uwm.paws360.DTO.Advising.MessageDTO(
                saved.getId(), s.getId(), a.getId(),
                a.getUser().getFirstname() + " " + a.getUser().getLastname(),
                saved.getSender().name(), saved.getContent(), saved.getSentAt()
        );
    }
}

