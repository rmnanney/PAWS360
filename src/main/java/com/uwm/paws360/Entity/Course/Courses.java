package com.uwm.paws360.Entity.Course;
import com.uwm.paws360.Entity.EntityDomains.Delivery_Method;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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

    @Enumerated(EnumType.STRING)
    @Column(name = "delivery_method", columnDefinition = "delivery_method DEFAULT 'in_person'")
    private Delivery_Method deliveryMethod = Delivery_Method.IN_PERSON;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "max_enrollment")
    private Integer maxEnrollment;

    @Column(name = "academic_year", nullable = false)
    private Integer academicYear;

    @Column(name = "term", nullable = false, length = 20)
    private String term;

    @Column(name = "created_at", nullable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false, columnDefinition = "TIMESTAMP WITH TIME ZONE")
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CourseSection> sections = new ArrayList<>();

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<CoursePrerequisite> prerequisiteLinks = new HashSet<>();

    /*------------------------- Constructors -------------------------*/

    public Courses() {}

    public Courses(String courseCode, String courseName, String courseDescription,
                  String departmentCode, String courseLevel, BigDecimal creditHours,
                  Delivery_Method deliveryMethod, boolean isActive,
                  Integer maxEnrollment, Integer academicYear, String term) {
        this.courseCode = courseCode;
        this.courseName = courseName;
        this.courseDescription = courseDescription;
        this.departmentCode = departmentCode;
        this.courseLevel = courseLevel;
        this.creditHours = creditHours;
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

    public Delivery_Method getDeliveryMethod() {
        return deliveryMethod;
    }

    public boolean isActive() {
        return isActive;
    }

    public Integer getMaxEnrollment() {
        return maxEnrollment;
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

    public List<CourseSection> getSections() {
        return sections;
    }

    public Set<CoursePrerequisite> getPrerequisiteLinks() {
        return prerequisiteLinks;
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

    public void setDeliveryMethod(Delivery_Method deliveryMethod) {
        this.deliveryMethod = deliveryMethod;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public void setMaxEnrollment(Integer maxEnrollment) {
        this.maxEnrollment = maxEnrollment;
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

    public void addSection(CourseSection section) {
        this.sections.add(section);
        section.setCourse(this);
    }

    public void removeSection(CourseSection section) {
        this.sections.remove(section);
        section.setCourse(null);
    }

    public void addPrerequisiteLink(CoursePrerequisite prerequisite) {
        this.prerequisiteLinks.add(prerequisite);
        prerequisite.setCourse(this);
    }

    public void removePrerequisiteLink(CoursePrerequisite prerequisite) {
        this.prerequisiteLinks.remove(prerequisite);
        prerequisite.setCourse(null);
    }
}
