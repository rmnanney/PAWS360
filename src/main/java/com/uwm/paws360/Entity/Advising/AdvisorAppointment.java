package com.uwm.paws360.Entity.Advising;

import com.uwm.paws360.Entity.UserTypes.Advisor;
import com.uwm.paws360.Entity.UserTypes.Student;
import jakarta.persistence.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "advisor_appointments")
public class AdvisorAppointment {

    public enum AppointmentType { ACADEMIC_ADVISING, DEGREE_PLANNING, CAREER_ADVISEMENT }
    public enum AppointmentStatus { CONFIRMED, PENDING, CANCELLED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "appointment_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "advisor_id", nullable = false)
    private Advisor advisor;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 40)
    private AppointmentType type = AppointmentType.ACADEMIC_ADVISING;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private AppointmentStatus status = AppointmentStatus.CONFIRMED;

    @Column(name = "scheduled_at", nullable = false)
    private OffsetDateTime scheduledAt = OffsetDateTime.now();

    @Column(name = "location", length = 200)
    private String location;

    @Column(name = "notes", length = 400)
    private String notes;

    public Long getId() { return id; }
    public Student getStudent() { return student; }
    public void setStudent(Student student) { this.student = student; }
    public Advisor getAdvisor() { return advisor; }
    public void setAdvisor(Advisor advisor) { this.advisor = advisor; }
    public AppointmentType getType() { return type; }
    public void setType(AppointmentType type) { this.type = type; }
    public AppointmentStatus getStatus() { return status; }
    public void setStatus(AppointmentStatus status) { this.status = status; }
    public OffsetDateTime getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; }
    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}

