package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
public class Mentor {

    @Id
    @Column(name = "mentor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private Users user;

    @Column(length = 120)
    private String program; // Mentoring program name

    private LocalDate startDate;
    private LocalDate endDate;
    private boolean active = true;

    @Column(nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Mentor(){}

    public Mentor(Users user){
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
    public String getProgram() { return program; }
    public void setProgram(String program) { this.program = program; }
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
