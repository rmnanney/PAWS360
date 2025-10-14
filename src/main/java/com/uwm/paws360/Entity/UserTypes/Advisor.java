package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.Department;
import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
public class Advisor {

    @Id
    @Column(name = "advisor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private Users user;

    @Enumerated(EnumType.STRING)
    private Department department;

    @Column(length = 120)
    private String officeLocation;

    private boolean active = true;
    private Integer adviseeCapacity;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Advisor(Users user) {
        this.user = user;
    }

    public Advisor(){}

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
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public Integer getAdviseeCapacity() { return adviseeCapacity; }
    public void setAdviseeCapacity(Integer adviseeCapacity) { this.adviseeCapacity = adviseeCapacity; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
