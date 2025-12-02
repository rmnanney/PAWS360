package com.uwm.paws360.Entity.Base;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Entity for managing demo data sets and reset functionality.
 * Supports demo environment automation and data consistency validation.
 */
@Entity
@Table(name = "demo_data_sets")
public class DemoDataSet {

    @Id
    @Column(name = "data_set_id", unique = true, updatable = false)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(name = "data_set_name", nullable = false, length = 100, unique = true)
    private String dataSetName;

    @Column(name = "description", length = 500)
    private String description;

    @Column(name = "version", nullable = false, length = 20)
    private String version;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "last_reset_at")
    private LocalDateTime lastResetAt;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;

    @Column(name = "reset_script_path", length = 255)
    private String resetScriptPath;

    @Column(name = "validation_script_path", length = 255)
    private String validationScriptPath;

    @Column(name = "student_count", nullable = false)
    private int studentCount;

    @Column(name = "admin_count", nullable = false)
    private int adminCount;

    @Column(name = "faculty_count", nullable = false)
    private int facultyCount;

    @Column(name = "course_count", nullable = false)
    private int courseCount;

    @Column(name = "data_consistency_hash", length = 64)
    private String dataConsistencyHash;

    /*------------------------- Constructors -------------------------*/

    public DemoDataSet() {}

    public DemoDataSet(String dataSetName, String description, String version, 
                      String resetScriptPath, String validationScriptPath) {
        this.dataSetName = dataSetName;
        this.description = description;
        this.version = version;
        this.resetScriptPath = resetScriptPath;
        this.validationScriptPath = validationScriptPath;
        this.isActive = true;
        this.studentCount = 0;
        this.adminCount = 0;
        this.facultyCount = 0;
        this.courseCount = 0;
    }

    /*------------------------- Lifecycle Methods -------------------------*/

    @PrePersist
    private void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = this.createdAt;
        if (!isActive) {
            this.isActive = true;
        }
    }

    @PreUpdate
    private void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /*------------------------- Business Methods -------------------------*/

    /**
     * Mark the data set as reset with current timestamp
     */
    public void markAsReset() {
        this.lastResetAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Update entity counts
     */
    public void updateCounts(int studentCount, int adminCount, int facultyCount, int courseCount) {
        this.studentCount = studentCount;
        this.adminCount = adminCount;
        this.facultyCount = facultyCount;
        this.courseCount = courseCount;
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Calculate total user count
     */
    public int getTotalUserCount() {
        return studentCount + adminCount + facultyCount;
    }

    /**
     * Check if data set has been reset within specified hours
     */
    public boolean wasResetWithin(int hours) {
        if (lastResetAt == null) {
            return false;
        }
        return lastResetAt.isAfter(LocalDateTime.now().minusHours(hours));
    }

    /**
     * Generate a simple hash for data consistency validation
     */
    public String generateConsistencyHash() {
        return String.format("%s-%s-%d-%d-%d-%d", 
            dataSetName, version, studentCount, adminCount, facultyCount, courseCount)
            .hashCode() + "";
    }

    /*------------------------- Getters -------------------------*/

    public int getId() {
        return id;
    }

    public String getDataSetName() {
        return dataSetName;
    }

    public String getDescription() {
        return description;
    }

    public String getVersion() {
        return version;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public LocalDateTime getLastResetAt() {
        return lastResetAt;
    }

    public boolean isActive() {
        return isActive;
    }

    public String getResetScriptPath() {
        return resetScriptPath;
    }

    public String getValidationScriptPath() {
        return validationScriptPath;
    }

    public int getStudentCount() {
        return studentCount;
    }

    public int getAdminCount() {
        return adminCount;
    }

    public int getFacultyCount() {
        return facultyCount;
    }

    public int getCourseCount() {
        return courseCount;
    }

    public String getDataConsistencyHash() {
        return dataConsistencyHash;
    }

    /*------------------------- Setters -------------------------*/

    public void setId(int id) {
        this.id = id;
    }

    public void setDataSetName(String dataSetName) {
        this.dataSetName = dataSetName;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public void setLastResetAt(LocalDateTime lastResetAt) {
        this.lastResetAt = lastResetAt;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public void setResetScriptPath(String resetScriptPath) {
        this.resetScriptPath = resetScriptPath;
    }

    public void setValidationScriptPath(String validationScriptPath) {
        this.validationScriptPath = validationScriptPath;
    }

    public void setStudentCount(int studentCount) {
        this.studentCount = studentCount;
    }

    public void setAdminCount(int adminCount) {
        this.adminCount = adminCount;
    }

    public void setFacultyCount(int facultyCount) {
        this.facultyCount = facultyCount;
    }

    public void setCourseCount(int courseCount) {
        this.courseCount = courseCount;
    }

    public void setDataConsistencyHash(String dataConsistencyHash) {
        this.dataConsistencyHash = dataConsistencyHash;
    }
}