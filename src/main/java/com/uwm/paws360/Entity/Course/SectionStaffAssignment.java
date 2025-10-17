package com.uwm.paws360.Entity.Course;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.InstructionalRole;
import jakarta.persistence.*;

import java.time.OffsetDateTime;

@Entity
@Table(
        name = "section_staff_assignments",
        schema = "paws360",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"section_id", "user_id", "role"})
        }
)
public class SectionStaffAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "assignment_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "section_id", nullable = false)
    private CourseSection section;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private Users staff;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 30)
    private InstructionalRole role;

    @Column(name = "assigned_at", nullable = false)
    private OffsetDateTime assignedAt = OffsetDateTime.now();

    public SectionStaffAssignment() {
    }

    public SectionStaffAssignment(CourseSection section, Users staff, InstructionalRole role) {
        this.section = section;
        this.staff = staff;
        this.role = role;
    }

    public Long getId() {
        return id;
    }

    public CourseSection getSection() {
        return section;
    }

    public void setSection(CourseSection section) {
        this.section = section;
    }

    public Users getStaff() {
        return staff;
    }

    public void setStaff(Users staff) {
        this.staff = staff;
    }

    public InstructionalRole getRole() {
        return role;
    }

    public void setRole(InstructionalRole role) {
        this.role = role;
    }

    public OffsetDateTime getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(OffsetDateTime assignedAt) {
        this.assignedAt = assignedAt;
    }
}
