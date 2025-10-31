package com.uwm.paws360.Entity.Course;

import com.uwm.paws360.Entity.EntityDomains.SectionEnrollmentStatus;
import com.uwm.paws360.Entity.UserTypes.Student;
import jakarta.persistence.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "course_enrollments", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "student_id", "lecture_section_id" })
})
public class CourseEnrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "enrollment_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lecture_section_id", nullable = false)
    private CourseSection lectureSection;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lab_section_id")
    private CourseSection labSection;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private SectionEnrollmentStatus status = SectionEnrollmentStatus.ENROLLED;

    @Column(name = "waitlist_position")
    private Integer waitlistPosition;

    @Column(name = "enrolled_at", nullable = false)
    private OffsetDateTime enrolledAt = OffsetDateTime.now();

    @Column(name = "waitlisted_at")
    private OffsetDateTime waitlistedAt;

    @Column(name = "dropped_at")
    private OffsetDateTime droppedAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @Column(name = "auto_enrolled_from_waitlist", nullable = false)
    private boolean autoEnrolledFromWaitlist = false;

    // Grade tracking
    @Column(name = "current_percentage")
    private Integer currentPercentage;

    @Column(name = "current_letter", length = 2)
    private String currentLetter;

    @Column(name = "final_letter", length = 2)
    private String finalLetter;

    @Column(name = "last_grade_update")
    private OffsetDateTime lastGradeUpdate;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    public CourseEnrollment() {
    }

    public CourseEnrollment(Student student, CourseSection lectureSection, CourseSection labSection,
            SectionEnrollmentStatus status) {
        this.student = student;
        this.lectureSection = lectureSection;
        this.labSection = labSection;
        this.status = status;
    }

    @PrePersist
    public void onCreate() {
        this.enrolledAt = OffsetDateTime.now();
        this.updatedAt = this.enrolledAt;
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = OffsetDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Student getStudent() {
        return student;
    }

    public void setStudent(Student student) {
        this.student = student;
    }

    public CourseSection getLectureSection() {
        return lectureSection;
    }

    public void setLectureSection(CourseSection lectureSection) {
        this.lectureSection = lectureSection;
    }

    public CourseSection getLabSection() {
        return labSection;
    }

    public void setLabSection(CourseSection labSection) {
        this.labSection = labSection;
    }

    public SectionEnrollmentStatus getStatus() {
        return status;
    }

    public void setStatus(SectionEnrollmentStatus status) {
        this.status = status;
    }

    public Integer getWaitlistPosition() {
        return waitlistPosition;
    }

    public void setWaitlistPosition(Integer waitlistPosition) {
        this.waitlistPosition = waitlistPosition;
    }

    public OffsetDateTime getEnrolledAt() {
        return enrolledAt;
    }

    public void setEnrolledAt(OffsetDateTime enrolledAt) {
        this.enrolledAt = enrolledAt;
    }

    public OffsetDateTime getWaitlistedAt() {
        return waitlistedAt;
    }

    public void setWaitlistedAt(OffsetDateTime waitlistedAt) {
        this.waitlistedAt = waitlistedAt;
    }

    public OffsetDateTime getDroppedAt() {
        return droppedAt;
    }

    public void setDroppedAt(OffsetDateTime droppedAt) {
        this.droppedAt = droppedAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public boolean isAutoEnrolledFromWaitlist() {
        return autoEnrolledFromWaitlist;
    }

    public void setAutoEnrolledFromWaitlist(boolean autoEnrolledFromWaitlist) {
        this.autoEnrolledFromWaitlist = autoEnrolledFromWaitlist;
    }

    public Integer getCurrentPercentage() {
        return currentPercentage;
    }

    public void setCurrentPercentage(Integer currentPercentage) {
        this.currentPercentage = currentPercentage;
    }

    public String getCurrentLetter() {
        return currentLetter;
    }

    public void setCurrentLetter(String currentLetter) {
        this.currentLetter = currentLetter;
    }

    public String getFinalLetter() {
        return finalLetter;
    }

    public void setFinalLetter(String finalLetter) {
        this.finalLetter = finalLetter;
    }

    public OffsetDateTime getLastGradeUpdate() {
        return lastGradeUpdate;
    }

    public void setLastGradeUpdate(OffsetDateTime lastGradeUpdate) {
        this.lastGradeUpdate = lastGradeUpdate;
    }

    public OffsetDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(OffsetDateTime completedAt) {
        this.completedAt = completedAt;
    }
}
