package com.uwm.paws360.Entity.Academics;

import com.uwm.paws360.Entity.UserTypes.Student;
import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "student_programs", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"student_id", "degree_id", "primary_flag"})
})
public class StudentProgram {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "student_program_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "degree_id", nullable = false)
    private DegreeProgram program;

    @Column(name = "expected_grad_term")
    private String expectedGraduationTerm; // e.g., "Spring"

    @Column(name = "expected_grad_year")
    private Integer expectedGraduationYear; // e.g., 2027

    @Column(name = "declared_at", nullable = false)
    private OffsetDateTime declaredAt = OffsetDateTime.now();

    @Column(name = "primary_flag", nullable = false)
    private boolean primary = true;

    public Long getId() { return id; }
    public Student getStudent() { return student; }
    public void setStudent(Student student) { this.student = student; }
    public DegreeProgram getProgram() { return program; }
    public void setProgram(DegreeProgram program) { this.program = program; }
    public String getExpectedGraduationTerm() { return expectedGraduationTerm; }
    public void setExpectedGraduationTerm(String term) { this.expectedGraduationTerm = term; }
    public Integer getExpectedGraduationYear() { return expectedGraduationYear; }
    public void setExpectedGraduationYear(Integer year) { this.expectedGraduationYear = year; }
    public boolean isPrimary() { return primary; }
    public void setPrimary(boolean primary) { this.primary = primary; }
}

