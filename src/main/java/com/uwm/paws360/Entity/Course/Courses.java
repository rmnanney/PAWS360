package com.uwm.paws360.Entity.Course;
import com.uwm.paws360.Entity.EntityDomains.Delivery_Method;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
        name = "courses",
        schema = "paws360",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = "course_code")
        }
)
public class Courses {

    /*------------------------- Fields -------------------------*/

    @Id
    @GeneratedValue
    @Column(name = "course_id", updatable = false, nullable = false)
    private int courseId;

    @Column(name = "course_code", nullable = false, length = 20, unique = true)
    private String courseCode;

    @Column(name = "course_name", nullable = false, length = 200)
    private String courseName;

    @Column(name = "course_description", columnDefinition = "TEXT")
    private String courseDescription;

    @Column(name = "department_code", nullable = false, length = 10)
    private String departmentCode;

    @Column(name = "course_level", length = 10)
    private String courseLevel; // e.g., 100, 200, 300, etc.

    @Column(name = "credit_hours", nullable = false, precision = 3, scale = 1)
    private BigDecimal creditHours;

    @Column(name = "prerequisites", columnDefinition = "TEXT")
    private String prerequisites;

    @Enumerated(EnumType.STRING)
    @Column(name = "delivery_method", columnDefinition = "VARCHAR(20) DEFAULT 'IN_PERSON'")
    private Delivery_Method deliveryMethod = Delivery_Method.IN_PERSON;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "max_enrollment")
    private Integer maxEnrollment;

    @Column(name = "current_enrollment")
    private Integer currentEnrollment = 0;

    @Column(name = "academic_year", nullable = false)
    private Integer academicYear;

    @Column(name = "term", nullable = false, length = 20)
    private String term;

    @Column(name = "created_at", nullable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE")
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    /*------------------------- Constructors -------------------------*/

    public Courses() {}

    public Courses(String courseCode, String courseName, String courseDescription,
                  String departmentCode, String courseLevel, BigDecimal creditHours,
                  String prerequisites, Delivery_Method deliveryMethod, boolean isActive,
                  Integer maxEnrollment, Integer academicYear, String term) {
        this.courseCode = courseCode;
        this.courseName = courseName;
        this.courseDescription = courseDescription;
        this.departmentCode = departmentCode;
        this.courseLevel = courseLevel;
        this.creditHours = creditHours;
        this.prerequisites = prerequisites;
        this.deliveryMethod = deliveryMethod;
        this.isActive = isActive;
        this.maxEnrollment = maxEnrollment;
        this.academicYear = academicYear;
        this.term = term;
    }

    /*------------------------- Lifecycle Hooks -------------------------*/

    @PrePersist
    protected void onCreate() {
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    /*------------------------- Getters -------------------------*/

    public int getCourseId() {
        return courseId;
    }

    public String getCourseCode() {
        return courseCode;
    }

    public String getCourseName() {
        return courseName;
    }

    public String getCourseDescription() {
        return courseDescription;
    }

    public String getDepartmentCode() {
        return departmentCode;
    }

    public String getCourseLevel() {
        return courseLevel;
    }

    public BigDecimal getCreditHours() {
        return creditHours;
    }

    public String getPrerequisites() {
        return prerequisites;
    }

    public Delivery_Method getDeliveryMethod() {
        return deliveryMethod;
    }

    public boolean isActive() {
        return isActive;
    }

    public Integer getMaxEnrollment() {
        return maxEnrollment;
    }

    public Integer getCurrentEnrollment() {
        return currentEnrollment;
    }

    public Integer getAcademicYear() {
        return academicYear;
    }

    public String getTerm() {
        return term;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    /*------------------------- Setters -------------------------*/

    public void setCourseCode(String courseCode) {
        this.courseCode = courseCode;
    }

    public void setCourseName(String courseName) {
        this.courseName = courseName;
    }

    public void setCourseDescription(String courseDescription) {
        this.courseDescription = courseDescription;
    }

    public void setDepartmentCode(String departmentCode) {
        this.departmentCode = departmentCode;
    }

    public void setCourseLevel(String courseLevel) {
        this.courseLevel = courseLevel;
    }

    public void setCreditHours(BigDecimal creditHours) {
        this.creditHours = creditHours;
    }

    public void setPrerequisites(String prerequisites) {
        this.prerequisites = prerequisites;
    }

    public void setDeliveryMethod(Delivery_Method deliveryMethod) {
        this.deliveryMethod = deliveryMethod;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public void setMaxEnrollment(Integer maxEnrollment) {
        this.maxEnrollment = maxEnrollment;
    }

    public void setCurrentEnrollment(Integer currentEnrollment) {
        this.currentEnrollment = currentEnrollment;
    }

    public void setAcademicYear(Integer academicYear) {
        this.academicYear = academicYear;
    }

    public void setTerm(String term) {
        this.term = term;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
