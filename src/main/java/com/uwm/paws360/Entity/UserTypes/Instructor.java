package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.Department;
import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
public class Instructor {

    @Id
    @Column(name = "instructor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private Users user;

    @Enumerated(EnumType.STRING)
    private Department department;

    @Column(length = 100)
    private String title; // Lecturer, Senior Lecturer, etc.

    private LocalDate hireDate;
    private boolean partTime;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Instructor(){}

    public Instructor(Users user){
        this.user = user;
    }

    @PrePersist
    private void onCreate(){
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    private void onUpdate(){
        this.updatedAt = LocalDateTime.now();
    }

    public int getId() { return id; }
    public Users getUser(){ return this.user; }
    public void setUser(Users user) { this.user = user; }
    public Department getDepartment() { return department; }
    public void setDepartment(Department department) { this.department = department; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public LocalDate getHireDate() { return hireDate; }
    public void setHireDate(LocalDate hireDate) { this.hireDate = hireDate; }
    public boolean isPartTime() { return partTime; }
    public void setPartTime(boolean partTime) { this.partTime = partTime; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
