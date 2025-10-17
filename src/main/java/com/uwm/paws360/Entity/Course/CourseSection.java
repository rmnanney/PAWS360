package com.uwm.paws360.Entity.Course;

import com.uwm.paws360.Entity.EntityDomains.SectionType;
import jakarta.persistence.*;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(
        name = "course_sections",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"course_id", "section_code", "term", "academic_year", "section_type"})
        }
)
public class CourseSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "section_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Courses course;

    @Column(name = "section_code", nullable = false, length = 15)
    private String sectionCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "section_type", nullable = false, length = 20)
    private SectionType sectionType;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_section_id")
    private CourseSection parentSection;

    @OneToMany(mappedBy = "parentSection", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CourseSection> childSections = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id")
    private Building building;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classroom_id")
    private Classroom classroom;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "course_section_meeting_days", joinColumns = @JoinColumn(name = "section_id"))
    @Column(name = "meeting_day", nullable = false)
    @Enumerated(EnumType.STRING)
    private Set<DayOfWeek> meetingDays = EnumSet.noneOf(DayOfWeek.class);

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Column(name = "max_enrollment")
    private Integer maxEnrollment;

    @Column(name = "current_enrollment")
    private Integer currentEnrollment = 0;

    @Column(name = "waitlist_capacity")
    private Integer waitlistCapacity = 0;

    @Column(name = "current_waitlist")
    private Integer currentWaitlist = 0;

    @Column(name = "auto_enroll_waitlist", nullable = false)
    private boolean autoEnrollWaitlist = true;

    @Column(name = "consent_required", nullable = false)
    private boolean consentRequired = false;

    @Column(name = "term", nullable = false, length = 20)
    private String term;

    @Column(name = "academic_year", nullable = false)
    private Integer academicYear;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @OneToMany(mappedBy = "section", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<SectionStaffAssignment> staffAssignments = new HashSet<>();

    public CourseSection() {
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

    public Courses getCourse() {
        return course;
    }

    public void setCourse(Courses course) {
        this.course = course;
    }

    public String getSectionCode() {
        return sectionCode;
    }

    public void setSectionCode(String sectionCode) {
        this.sectionCode = sectionCode;
    }

    public SectionType getSectionType() {
        return sectionType;
    }

    public void setSectionType(SectionType sectionType) {
        this.sectionType = sectionType;
    }

    public CourseSection getParentSection() {
        return parentSection;
    }

    public void setParentSection(CourseSection parentSection) {
        this.parentSection = parentSection;
    }

    public List<CourseSection> getChildSections() {
        return childSections;
    }

    public Building getBuilding() {
        return building;
    }

    public void setBuilding(Building building) {
        this.building = building;
    }

    public Classroom getClassroom() {
        return classroom;
    }

    public void setClassroom(Classroom classroom) {
        this.classroom = classroom;
    }

    public Set<DayOfWeek> getMeetingDays() {
        return meetingDays;
    }

    public void setMeetingDays(Set<DayOfWeek> meetingDays) {
        if (meetingDays == null || meetingDays.isEmpty()) {
            this.meetingDays = EnumSet.noneOf(DayOfWeek.class);
        } else {
            this.meetingDays = EnumSet.copyOf(meetingDays);
        }
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalTime startTime) {
        this.startTime = startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalTime endTime) {
        this.endTime = endTime;
    }

    public Integer getMaxEnrollment() {
        return maxEnrollment;
    }

    public void setMaxEnrollment(Integer maxEnrollment) {
        this.maxEnrollment = maxEnrollment;
    }

    public Integer getCurrentEnrollment() {
        return currentEnrollment;
    }

    public void setCurrentEnrollment(Integer currentEnrollment) {
        this.currentEnrollment = currentEnrollment;
    }

    public Integer getWaitlistCapacity() {
        return waitlistCapacity;
    }

    public void setWaitlistCapacity(Integer waitlistCapacity) {
        this.waitlistCapacity = waitlistCapacity;
    }

    public Integer getCurrentWaitlist() {
        return currentWaitlist;
    }

    public void setCurrentWaitlist(Integer currentWaitlist) {
        this.currentWaitlist = currentWaitlist;
    }

    public boolean isAutoEnrollWaitlist() {
        return autoEnrollWaitlist;
    }

    public void setAutoEnrollWaitlist(boolean autoEnrollWaitlist) {
        this.autoEnrollWaitlist = autoEnrollWaitlist;
    }

    public boolean isConsentRequired() {
        return consentRequired;
    }

    public void setConsentRequired(boolean consentRequired) {
        this.consentRequired = consentRequired;
    }

    public String getTerm() {
        return term;
    }

    public void setTerm(String term) {
        this.term = term;
    }

    public Integer getAcademicYear() {
        return academicYear;
    }

    public void setAcademicYear(Integer academicYear) {
        this.academicYear = academicYear;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public Set<SectionStaffAssignment> getStaffAssignments() {
        return staffAssignments;
    }

    public void addChildSection(CourseSection child) {
        this.childSections.add(child);
        child.setParentSection(this);
    }

    public void removeChildSection(CourseSection child) {
        this.childSections.remove(child);
        child.setParentSection(null);
    }

    public void addStaffAssignment(SectionStaffAssignment assignment) {
        this.staffAssignments.add(assignment);
        assignment.setSection(this);
    }

    public void removeStaffAssignment(SectionStaffAssignment assignment) {
        this.staffAssignments.remove(assignment);
        assignment.setSection(null);
    }

    public void incrementEnrollment() {
        if (currentEnrollment == null) {
            currentEnrollment = 0;
        }
        currentEnrollment++;
    }

    public void decrementEnrollment() {
        if (currentEnrollment == null || currentEnrollment == 0) {
            currentEnrollment = 0;
            return;
        }
        currentEnrollment--;
    }

    public void incrementWaitlist() {
        if (currentWaitlist == null) {
            currentWaitlist = 0;
        }
        currentWaitlist++;
    }

    public void decrementWaitlist() {
        if (currentWaitlist == null || currentWaitlist == 0) {
            currentWaitlist = 0;
            return;
        }
        currentWaitlist--;
    }
}
