package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Course.*;
import com.uwm.paws360.Entity.Course.Building;
import com.uwm.paws360.Entity.Course.Classroom;
import com.uwm.paws360.Entity.Course.CoursePrerequisite;
import com.uwm.paws360.Entity.Course.CourseSection;
import com.uwm.paws360.Entity.Course.Courses;
import com.uwm.paws360.Entity.Course.SectionStaffAssignment;
import com.uwm.paws360.Service.CourseCatalogService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/courses")
public class CourseController {

    private final CourseCatalogService courseCatalogService;

    public CourseController(CourseCatalogService courseCatalogService) {
        this.courseCatalogService = courseCatalogService;
    }

    @PostMapping
    public ResponseEntity<CourseCatalogResponse> createOrUpdateCourse(@Valid @RequestBody CourseCatalogRequest request) {
        Courses course = courseCatalogService.createOrUpdateCourse(request);
        return ResponseEntity.ok(courseCatalogService.toCourseResponse(course));
    }

    @GetMapping("/{courseId}")
    public ResponseEntity<CourseCatalogResponse> getCourse(@PathVariable Integer courseId) {
        Courses course = courseCatalogService.getCourse(courseId);
        return ResponseEntity.ok(courseCatalogService.toCourseResponse(course));
    }

    @PostMapping("/buildings")
    public ResponseEntity<Building> createBuilding(@Valid @RequestBody BuildingDTO request) {
        Building building = courseCatalogService.createBuilding(request);
        return ResponseEntity.ok(building);
    }

    @PostMapping("/classrooms")
    public ResponseEntity<Classroom> createClassroom(@Valid @RequestBody ClassroomDTO request) {
        Classroom classroom = courseCatalogService.createClassroom(request);
        return ResponseEntity.ok(classroom);
    }

    @PostMapping("/sections")
    public ResponseEntity<CourseSectionResponse> createOrUpdateSection(@Valid @RequestBody CourseSectionRequest request) {
        CourseSection section = courseCatalogService.createOrUpdateSection(request);
        return ResponseEntity.ok(courseCatalogService.toSectionResponse(section));
    }

    @PostMapping("/prerequisites")
    public ResponseEntity<CoursePrerequisite> addPrerequisite(@Valid @RequestBody CoursePrerequisiteRequest request) {
        CoursePrerequisite prerequisite = courseCatalogService.addPrerequisite(request);
        return ResponseEntity.ok(prerequisite);
    }

    @PostMapping("/sections/assign-staff")
    public ResponseEntity<SectionStaffAssignmentResponse> assignStaff(@Valid @RequestBody SectionStaffAssignmentRequest request) {
        SectionStaffAssignment assignment = courseCatalogService.assignStaff(request);
        SectionStaffAssignmentResponse response = new SectionStaffAssignmentResponse(
                assignment.getId(),
                assignment.getSection().getId(),
                assignment.getStaff().getId(),
                assignment.getRole(),
                assignment.getAssignedAt()
        );
        return ResponseEntity.ok(response);
    }
}
