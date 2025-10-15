package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.Department;
import com.uwm.paws360.Entity.EntityDomains.Enrollement_Status;
import com.uwm.paws360.Entity.EntityDomains.Student_Standing;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
public class Student {

    @Id
    @Column(name = "student_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private Users user;

    @Column(name = "campus_id", unique = true, length = 32)
    private String campusId;

    @Enumerated(EnumType.STRING)
    private Department department;

    @Enumerated(EnumType.STRING)
    private Student_Standing standing;

    @Enumerated(EnumType.STRING)
    private Enrollement_Status enrollementStatus;

    @Column(precision = 3, scale = 2)
    private BigDecimal gpa;

    private LocalDate expectedGraduation;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Student(Users user) {
        this.user = user;
    }

    public Student(){}

    @PrePersist
    private void onCreate(){
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    private void onUpdate(){
        this.updatedAt = LocalDateTime.now();
    }

    public Users getUser() {
        return user;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public int getId() { return id; }

    public String getCampusId() { return campusId; }
    public void setCampusId(String campusId) { this.campusId = campusId; }

    public Department getDepartment() { return department; }
    public void setDepartment(Department department) { this.department = department; }

    public Student_Standing getStanding() { return standing; }
    public void setStanding(Student_Standing standing) { this.standing = standing; }

    public Enrollement_Status getEnrollementStatus() { return enrollementStatus; }
    public void setEnrollementStatus(Enrollement_Status enrollementStatus) { this.enrollementStatus = enrollementStatus; }

    public BigDecimal getGpa() { return gpa; }
    public void setGpa(BigDecimal gpa) { this.gpa = gpa; }

    public LocalDate getExpectedGraduation() { return expectedGraduation; }
    public void setExpectedGraduation(LocalDate expectedGraduation) { this.expectedGraduation = expectedGraduation; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
