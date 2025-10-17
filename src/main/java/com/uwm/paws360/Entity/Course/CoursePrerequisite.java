package com.uwm.paws360.Entity.Course;

import jakarta.persistence.*;

@Entity
@Table(name = "course_prerequisites", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "course_id", "prerequisite_course_id" })
})
public class CoursePrerequisite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "course_prerequisite_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Courses course;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prerequisite_course_id", nullable = false)
    private Courses prerequisiteCourse;

    @Column(name = "minimum_grade", length = 4)
    private String minimumGrade;

    @Column(name = "concurrent_allowed", nullable = false)
    private boolean concurrentAllowed = false;

    public CoursePrerequisite() {
    }

    public CoursePrerequisite(Courses course, Courses prerequisiteCourse, String minimumGrade,
            boolean concurrentAllowed) {
        this.course = course;
        this.prerequisiteCourse = prerequisiteCourse;
        this.minimumGrade = minimumGrade;
        this.concurrentAllowed = concurrentAllowed;
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

    public Courses getPrerequisiteCourse() {
        return prerequisiteCourse;
    }

    public void setPrerequisiteCourse(Courses prerequisiteCourse) {
        this.prerequisiteCourse = prerequisiteCourse;
    }

    public String getMinimumGrade() {
        return minimumGrade;
    }

    public void setMinimumGrade(String minimumGrade) {
        this.minimumGrade = minimumGrade;
    }

    public boolean isConcurrentAllowed() {
        return concurrentAllowed;
    }

    public void setConcurrentAllowed(boolean concurrentAllowed) {
        this.concurrentAllowed = concurrentAllowed;
    }
}
