package com.uwm.paws360.Entity.Academics;

import com.uwm.paws360.Entity.Course.Courses;
import jakarta.persistence.*;

@Entity
@Table(name = "degree_requirements")
public class DegreeRequirement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "requirement_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "degree_id", nullable = false)
    private DegreeProgram degreeProgram;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Courses course;

    @Column(name = "is_required", nullable = false)
    private boolean required = true;

    public Long getId() { return id; }
    public DegreeProgram getDegreeProgram() { return degreeProgram; }
    public void setDegreeProgram(DegreeProgram degreeProgram) { this.degreeProgram = degreeProgram; }
    public Courses getCourse() { return course; }
    public void setCourse(Courses course) { this.course = course; }
    public boolean isRequired() { return required; }
    public void setRequired(boolean required) { this.required = required; }
}

