package com.uwm.paws360.Entity.Advising;

import com.uwm.paws360.Entity.UserTypes.Advisor;
import com.uwm.paws360.Entity.UserTypes.Student;
import jakarta.persistence.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "student_advisors", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"student_id", "advisor_id"})
})
public class StudentAdvisor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "advisor_id", nullable = false)
    private Advisor advisor;

    @Column(name = "primary_advisor", nullable = false)
    private boolean primaryAdvisor = true;

    @Column(name = "assigned_at", nullable = false)
    private OffsetDateTime assignedAt = OffsetDateTime.now();

    public Long getId() { return id; }
    public Student getStudent() { return student; }
    public void setStudent(Student student) { this.student = student; }
    public Advisor getAdvisor() { return advisor; }
    public void setAdvisor(Advisor advisor) { this.advisor = advisor; }
    public boolean isPrimaryAdvisor() { return primaryAdvisor; }
    public void setPrimaryAdvisor(boolean primaryAdvisor) { this.primaryAdvisor = primaryAdvisor; }
    public OffsetDateTime getAssignedAt() { return assignedAt; }
    public void setAssignedAt(OffsetDateTime assignedAt) { this.assignedAt = assignedAt; }
}

