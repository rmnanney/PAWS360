package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.Department;
import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
public class Counselor {
    @Id
    @Column(name = "councelor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private Users user;

    @Enumerated(EnumType.STRING)
    private Department department;

    @Column(length = 120)
    private String officeLocation;

    @Column(length = 120)
    private String specialty;

    private boolean active = true;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Counselor(Users user) {
        this.user = user;
    }

    public Counselor(){}

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
    public String getOfficeLocation() { return officeLocation; }
    public void setOfficeLocation(String officeLocation) { this.officeLocation = officeLocation; }
    public String getSpecialty() { return specialty; }
    public void setSpecialty(String specialty) { this.specialty = specialty; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
