package com.uwm.paws360.Entity.Course;

import jakarta.persistence.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "buildings", schema = "paws360", uniqueConstraints = {
        @UniqueConstraint(columnNames = "code")
})
public class Building {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "building_id")
    private Long id;

    @Column(name = "code", nullable = false, length = 12)
    private String code;

    @Column(name = "name", nullable = false, length = 120)
    private String name;

    @Column(name = "campus", length = 120)
    private String campus;

    @Column(name = "accessible", nullable = false)
    private boolean accessible = true;

    @Column(name = "notes", length = 500)
    private String notes;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public Building() {
    }

    public Building(String code, String name, String campus, boolean accessible, String notes) {
        this.code = code;
        this.name = name;
        this.campus = campus;
        this.accessible = accessible;
        this.notes = notes;
    }

    @PrePersist
    public void onCreate() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = this.createdAt;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCampus() {
        return campus;
    }

    public void setCampus(String campus) {
        this.campus = campus;
    }

    public boolean isAccessible() {
        return accessible;
    }

    public void setAccessible(boolean accessible) {
        this.accessible = accessible;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
