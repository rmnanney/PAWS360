package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Course.*;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.Course.*;
import com.uwm.paws360.Entity.EntityDomains.InstructionalRole;
import com.uwm.paws360.Entity.EntityDomains.SectionType;
import com.uwm.paws360.JPARepository.Course.*;
import com.uwm.paws360.JPARepository.User.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class CourseCatalogService {

    private final BuildingRepository buildingRepository;
    private final ClassroomRepository classroomRepository;
    private final CourseRepository courseRepository;
    private final CourseSectionRepository courseSectionRepository;
    private final CoursePrerequisiteRepository coursePrerequisiteRepository;
    private final SectionStaffAssignmentRepository sectionStaffAssignmentRepository;
    private final UserRepository userRepository;

    public CourseCatalogService(BuildingRepository buildingRepository,
                                ClassroomRepository classroomRepository,
                                CourseRepository courseRepository,
                                CourseSectionRepository courseSectionRepository,
                                CoursePrerequisiteRepository coursePrerequisiteRepository,
                                SectionStaffAssignmentRepository sectionStaffAssignmentRepository,
                                UserRepository userRepository) {
        this.buildingRepository = buildingRepository;
        this.classroomRepository = classroomRepository;
        this.courseRepository = courseRepository;
        this.courseSectionRepository = courseSectionRepository;
        this.coursePrerequisiteRepository = coursePrerequisiteRepository;
        this.sectionStaffAssignmentRepository = sectionStaffAssignmentRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public Building createBuilding(BuildingDTO request) {
        buildingRepository.findByCodeIgnoreCase(request.code())
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("Building code already exists: " + request.code());
                });

        Building building = new Building(request.code(), request.name(), request.campus(), request.accessible(), request.notes());
        return buildingRepository.save(building);
    }

    @Transactional
    public Classroom createClassroom(ClassroomDTO request) {
        Building building = buildingRepository.findById(request.buildingId())
                .orElseThrow(() -> new EntityNotFoundException("Building not found for id " + request.buildingId()));

        classroomRepository.findByBuildingIdAndRoomNumberIgnoreCase(request.buildingId(), request.roomNumber())
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("Classroom already exists for building: " + request.roomNumber());
                });

        Classroom classroom = new Classroom(building, request.roomNumber(), request.capacity(), request.roomType(), request.features());
        return classroomRepository.save(classroom);
    }

    @Transactional
    public Courses createOrUpdateCourse(CourseCatalogRequestDTO request) {
        Courses course = courseRepository.findByCourseCodeIgnoreCase(request.courseCode())
                .orElse(new Courses());

        course.setCourseCode(request.courseCode());
        course.setCourseName(request.courseName());
        course.setCourseDescription(request.courseDescription());
        course.setDepartment(request.department());
        course.setCourseLevel(request.courseLevel());
        course.setCreditHours(request.creditHours());
        if (request.courseCost() != null) {
            course.setCourseCost(request.courseCost());
        } else if (course.getCourseCost() == null && request.creditHours() != null) {
            // Default cost: $400 per credit if not provided
            java.math.BigDecimal perCredit = new java.math.BigDecimal("100.00");
            course.setCourseCost(perCredit.multiply(request.creditHours()));
        }
        if (request.deliveryMethod() != null) {
            course.setDeliveryMethod(request.deliveryMethod());
        }
        course.setActive(request.active());
        course.setMaxEnrollment(request.catalogMaxEnrollment());
        course.setAcademicYear(request.academicYear());
        course.setTerm(request.term());

        return courseRepository.save(course);
    }

    @Transactional
    public CourseSection createOrUpdateSection(CourseSectionRequestDTO request) {
        Courses course = courseRepository.findById(request.courseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found for id " + request.courseId()));

        CourseSection section;
        if (request.sectionId() != null) {
            section = courseSectionRepository.findById(request.sectionId())
                    .orElseThrow(() -> new EntityNotFoundException("Section not found for id " + request.sectionId()));
        } else {
            // Idempotent upsert by unique natural key to avoid duplicate constraint failures when seeding
            section = courseSectionRepository
                    .findFirstByCourseAndSectionCodeIgnoreCaseAndTermIgnoreCaseAndAcademicYearAndSectionType(
                            course, request.sectionCode(), request.term(), request.academicYear(), request.sectionType())
                    .orElse(new CourseSection());
        }

        section.setCourse(course);
        if (section.getId() == null && !course.getSections().contains(section)) {
            course.addSection(section);
        }
        section.setSectionCode(request.sectionCode());
        section.setSectionType(request.sectionType());

        if (request.sectionType() == SectionType.LAB && request.parentSectionId() == null) {
            throw new IllegalArgumentException("Lab sections must reference a parent lecture section");
        }

        if (request.sectionType() == SectionType.LECTURE && request.parentSectionId() != null) {
            throw new IllegalArgumentException("Lecture sections cannot specify a parent section");
        }

        CourseSection previousParent = section.getParentSection();
        if (previousParent != null && (request.parentSectionId() == null || !previousParent.getId().equals(request.parentSectionId()))) {
            previousParent.removeChildSection(section);
        }

        if (request.parentSectionId() != null) {
            CourseSection parent = courseSectionRepository.findById(request.parentSectionId())
                    .orElseThrow(() -> new EntityNotFoundException("Parent section not found for id " + request.parentSectionId()));
            if (parent.getCourse() == null || parent.getCourse().getCourseId() != course.getCourseId()) {
                throw new IllegalArgumentException("Parent section must belong to the same course");
            }
            if (!parent.getChildSections().contains(section)) {
                parent.addChildSection(section);
            } else {
                section.setParentSection(parent);
            }
        } else {
            section.setParentSection(null);
        }

        if (request.buildingId() != null) {
            Building building = buildingRepository.findById(request.buildingId())
                    .orElseThrow(() -> new EntityNotFoundException("Building not found for id " + request.buildingId()));
            section.setBuilding(building);
        } else {
            section.setBuilding(null);
        }

        if (request.classroomId() != null) {
            Classroom classroom = classroomRepository.findById(request.classroomId())
                    .orElseThrow(() -> new EntityNotFoundException("Classroom not found for id " + request.classroomId()));
            section.setClassroom(classroom);
        } else {
            section.setClassroom(null);
        }

        section.setMeetingDays(request.meetingDays());
        section.setStartTime(request.startTime());
        section.setEndTime(request.endTime());
        section.setMaxEnrollment(request.maxEnrollment());
        section.setWaitlistCapacity(request.waitlistCapacity());
        section.setAutoEnrollWaitlist(request.autoEnrollWaitlist());
        section.setConsentRequired(request.consentRequired());
        section.setTerm(request.term());
        section.setAcademicYear(request.academicYear());

        return courseSectionRepository.save(section);
    }

    @Transactional
    public CoursePrerequisite addPrerequisite(CoursePrerequisiteRequestDTO request) {
        Courses course = courseRepository.findById(request.courseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found for id " + request.courseId()));
        Courses prerequisite = courseRepository.findById(request.prerequisiteCourseId())
                .orElseThrow(() -> new EntityNotFoundException("Prerequisite course not found for id " + request.prerequisiteCourseId()));

        if (course.getCourseId() == prerequisite.getCourseId()) {
            throw new IllegalArgumentException("Course cannot be a prerequisite of itself");
        }

        CoursePrerequisite prerequisiteLink = new CoursePrerequisite(course, prerequisite, request.minimumGrade(), request.concurrentAllowed());
        return coursePrerequisiteRepository.save(prerequisiteLink);
    }

    @Transactional
    public SectionStaffAssignment assignStaff(SectionStaffAssignmentRequestDTO request) {
        CourseSection section = courseSectionRepository.findById(request.sectionId())
                .orElseThrow(() -> new EntityNotFoundException("Section not found for id " + request.sectionId()));
        Users staff = userRepository.findById(request.userId())
                .orElseThrow(() -> new EntityNotFoundException("User not found for id " + request.userId()));

        InstructionalRole role = request.role();
        if (!isValidInstructionalRole(staff.getRole(), role)) {
            throw new IllegalArgumentException("User does not have the correct institutional role for assignment");
        }

        if (sectionStaffAssignmentRepository.existsBySectionAndStaffAndRole(section, staff, role)) {
            throw new IllegalStateException("Staff member is already assigned to this section in the specified role");
        }

        SectionStaffAssignment assignment = new SectionStaffAssignment(section, staff, role);
        return sectionStaffAssignmentRepository.save(assignment);
    }

    public CourseCatalogResponseDTO toCourseResponse(Courses course) {
        List<CourseSection> sections = courseSectionRepository.findByCourse(course);
        List<CourseSectionResponseDTO> sectionResponses = sections.stream()
                .map(this::toSectionResponse)
                .collect(Collectors.toList());

        return new CourseCatalogResponseDTO(
                course.getCourseId(),
                course.getCourseCode(),
                course.getCourseName(),
                course.getCourseDescription(),
                course.getDepartment(),
                course.getCourseLevel(),
                course.getCreditHours(),
                course.getDeliveryMethod(),
                course.isActive(),
                course.getMaxEnrollment(),
                course.getAcademicYear(),
                course.getTerm(),
                sectionResponses
        );
    }

    public CourseSectionResponseDTO toSectionResponse(CourseSection section) {
        Long parentId = section.getParentSection() != null ? section.getParentSection().getId() : null;
        Long buildingId = section.getBuilding() != null ? section.getBuilding().getId() : null;
        Long classroomId = section.getClassroom() != null ? section.getClassroom().getId() : null;
        Set<DayOfWeek> meetingDays = section.getMeetingDays();

        return new CourseSectionResponseDTO(
                section.getId(),
                section.getSectionType(),
                section.getSectionCode(),
                parentId,
                buildingId,
                classroomId,
                meetingDays,
                section.getStartTime(),
                section.getEndTime(),
                section.getMaxEnrollment(),
                section.getCurrentEnrollment(),
                section.getWaitlistCapacity(),
                section.getCurrentWaitlist(),
                section.isAutoEnrollWaitlist(),
                section.isConsentRequired(),
                section.getTerm(),
                section.getAcademicYear()
        );
    }

    public Courses getCourse(Integer courseId) {
        return courseRepository.findById(courseId)
                .orElseThrow(() -> new EntityNotFoundException("Course not found for id " + courseId));
    }

    public java.util.List<Courses> listAllCourses() {
        return courseRepository.findAll();
    }

    private boolean isValidInstructionalRole(com.uwm.paws360.Entity.EntityDomains.User.Role userRole, InstructionalRole assignmentRole) {
        return switch (assignmentRole) {
            case PROFESSOR -> userRole == com.uwm.paws360.Entity.EntityDomains.User.Role.PROFESSOR;
            case INSTRUCTOR -> userRole == com.uwm.paws360.Entity.EntityDomains.User.Role.INSTRUCTOR || userRole == com.uwm.paws360.Entity.EntityDomains.User.Role.PROFESSOR;
            case TEACHING_ASSISTANT -> userRole == com.uwm.paws360.Entity.EntityDomains.User.Role.TA;
        };
    }
}
