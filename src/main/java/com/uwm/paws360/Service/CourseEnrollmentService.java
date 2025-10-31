package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Course.CourseEnrollmentRequestDTO;
import com.uwm.paws360.DTO.Course.CourseEnrollmentResponseDTO;
import com.uwm.paws360.DTO.Course.DropEnrollmentRequestDTO;
import com.uwm.paws360.DTO.Course.SwitchLabRequestDTO;
import com.uwm.paws360.DTO.Course.FinalizeGradeRequestDTO;
import com.uwm.paws360.DTO.Course.GradeUpdateRequestDTO;
import com.uwm.paws360.Entity.Course.CourseEnrollment;
import com.uwm.paws360.Entity.Course.CourseSection;
import com.uwm.paws360.Entity.EntityDomains.SectionEnrollmentStatus;
import com.uwm.paws360.Entity.EntityDomains.SectionType;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Course.CourseEnrollmentRepository;
import com.uwm.paws360.JPARepository.Course.CourseSectionRepository;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CourseEnrollmentService {

    private final CourseEnrollmentRepository courseEnrollmentRepository;
    private final CourseSectionRepository courseSectionRepository;
    private final StudentRepository studentRepository;

    public CourseEnrollmentService(CourseEnrollmentRepository courseEnrollmentRepository,
                                   CourseSectionRepository courseSectionRepository,
                                   StudentRepository studentRepository) {
        this.courseEnrollmentRepository = courseEnrollmentRepository;
        this.courseSectionRepository = courseSectionRepository;
        this.studentRepository = studentRepository;
    }

    @Transactional
    public CourseEnrollmentResponseDTO enrollStudent(CourseEnrollmentRequestDTO request) {
        Student student = studentRepository.findById(request.studentId())
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + request.studentId()));

        CourseSection lectureSection = courseSectionRepository.findById(request.lectureSectionId())
                .orElseThrow(() -> new EntityNotFoundException("Lecture section not found for id " + request.lectureSectionId()));

        if (lectureSection.getSectionType() != SectionType.LECTURE) {
            throw new IllegalArgumentException("Lecture section id must reference a lecture");
        }

        CourseSection labSection = null;
        List<CourseSection> labOptions = courseSectionRepository.findByParentSection(lectureSection);
        if (!labOptions.isEmpty()) {
            if (request.labSectionId() == null) {
                throw new IllegalArgumentException("Lab selection is required for this course");
            }
            labSection = courseSectionRepository.findById(request.labSectionId())
                    .orElseThrow(() -> new EntityNotFoundException("Lab section not found for id " + request.labSectionId()));
            if (labSection.getSectionType() != SectionType.LAB || labSection.getParentSection() == null || !labSection.getParentSection().getId().equals(lectureSection.getId())) {
                throw new IllegalArgumentException("Selected lab section does not belong to the chosen lecture");
            }
        } else if (request.labSectionId() != null) {
            throw new IllegalArgumentException("Lecture does not have lab options but lab section id was provided");
        }

        CourseEnrollment existingEnrollment = courseEnrollmentRepository
                .findByStudentIdAndLectureSectionId(request.studentId(), request.lectureSectionId())
                .orElse(null);

        if (existingEnrollment != null && existingEnrollment.getStatus() != SectionEnrollmentStatus.DROPPED) {
            throw new IllegalStateException("Student is already enrolled or waitlisted for this lecture");
        }

        boolean hasLectureCapacity = hasCapacity(lectureSection);
        boolean hasLabCapacity = labSection == null || hasCapacity(labSection);

        CourseEnrollment enrollment;
        if (hasLectureCapacity && hasLabCapacity) {
            enrollment = existingEnrollment != null
                    ? existingEnrollment
                    : new CourseEnrollment(student, lectureSection, labSection, SectionEnrollmentStatus.ENROLLED);
            enrollment.setStudent(student);
            enrollment.setLectureSection(lectureSection);
            enrollment.setLabSection(labSection);
            enrollment.setStatus(SectionEnrollmentStatus.ENROLLED);
            enrollment.setAutoEnrolledFromWaitlist(false);
            enrollment.setWaitlistPosition(null);
            enrollment.setWaitlistedAt(null);
            enrollment.setDroppedAt(null);
            enrollment.setEnrolledAt(OffsetDateTime.now());
            lectureSection.incrementEnrollment();
            if (labSection != null) {
                labSection.incrementEnrollment();
            }
        } else {
            if (!hasWaitlistCapacity(lectureSection)) {
                throw new IllegalStateException("Both the lecture and its waitlist are full");
            }
            enrollment = existingEnrollment != null
                    ? existingEnrollment
                    : new CourseEnrollment(student, lectureSection, labSection, SectionEnrollmentStatus.WAITLISTED);
            enrollment.setStudent(student);
            enrollment.setLectureSection(lectureSection);
            enrollment.setLabSection(labSection);
            enrollment.setStatus(SectionEnrollmentStatus.WAITLISTED);
            enrollment.setWaitlistedAt(OffsetDateTime.now());
            enrollment.setWaitlistPosition(nextWaitlistPosition(lectureSection));
            enrollment.setDroppedAt(null);
            enrollment.setAutoEnrolledFromWaitlist(false);
            enrollment.setEnrolledAt(null);
            lectureSection.incrementWaitlist();
        }

        CourseEnrollment saved = courseEnrollmentRepository.save(enrollment);
        return toResponse(saved);
    }

    @Transactional
    public CourseEnrollmentResponseDTO dropEnrollment(DropEnrollmentRequestDTO request) {
        CourseEnrollment enrollment = courseEnrollmentRepository.findByStudentIdAndLectureSectionId(request.studentId(), request.lectureSectionId())
                .orElseThrow(() -> new EntityNotFoundException("Enrollment not found for student " + request.studentId()));

        CourseSection lectureSection = enrollment.getLectureSection();
        CourseSection labSection = enrollment.getLabSection();

        if (enrollment.getStatus() == SectionEnrollmentStatus.DROPPED) {
            return toResponse(enrollment);
        }

        if (enrollment.getStatus() == SectionEnrollmentStatus.WAITLISTED) {
            lectureSection.decrementWaitlist();
            enrollment.setWaitlistPosition(null);
            enrollment.setWaitlistedAt(null);
        } else if (enrollment.getStatus() == SectionEnrollmentStatus.ENROLLED) {
            lectureSection.decrementEnrollment();
            if (labSection != null) {
                labSection.decrementEnrollment();
            }
            promoteWaitlistedStudents(lectureSection);
        }

        enrollment.setStatus(SectionEnrollmentStatus.DROPPED);
        enrollment.setDroppedAt(OffsetDateTime.now());

        CourseEnrollment saved = courseEnrollmentRepository.save(enrollment);
        rebalanceWaitlistPositions(lectureSection);
        return toResponse(saved);
    }

    @Transactional
    public CourseEnrollmentResponseDTO switchLab(SwitchLabRequestDTO request) {
        CourseEnrollment enrollment = courseEnrollmentRepository.findByStudentIdAndLectureSectionId(request.studentId(), request.lectureSectionId())
                .orElseThrow(() -> new EntityNotFoundException("Enrollment not found for student " + request.studentId()));

        if (enrollment.getStatus() != SectionEnrollmentStatus.ENROLLED) {
            throw new IllegalStateException("Only actively enrolled students can switch labs");
        }

        CourseSection lectureSection = enrollment.getLectureSection();
        CourseSection currentLab = enrollment.getLabSection();

        CourseSection newLab = courseSectionRepository.findById(request.newLabSectionId())
                .orElseThrow(() -> new EntityNotFoundException("Lab section not found for id " + request.newLabSectionId()));

        if (currentLab != null && currentLab.getId().equals(newLab.getId())) {
            return toResponse(enrollment);
        }

        if (newLab.getSectionType() != SectionType.LAB || newLab.getParentSection() == null || !newLab.getParentSection().getId().equals(lectureSection.getId())) {
            throw new IllegalArgumentException("Selected lab does not belong to the same lecture");
        }

        if (!hasCapacity(newLab)) {
            throw new IllegalStateException("Selected lab is full");
        }

        if (currentLab != null) {
            currentLab.decrementEnrollment();
        }

        newLab.incrementEnrollment();
        enrollment.setLabSection(newLab);

        CourseEnrollment saved = courseEnrollmentRepository.save(enrollment);
        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<CourseEnrollmentResponseDTO> listEnrollmentsForStudent(Integer studentId) {
        // Ensure the student exists (consistent with other service methods)
        studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));

        List<CourseEnrollment> enrollments = courseEnrollmentRepository.findByStudentId(studentId);
        // "Signed up for" implies active or waitlisted; exclude DROPPED
        return enrollments.stream()
                .filter(e -> e.getStatus() != SectionEnrollmentStatus.DROPPED)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<com.uwm.paws360.DTO.Course.TodayScheduleItemDTO> todaySchedule(Integer studentId) {
        studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        DayOfWeek today = java.time.OffsetDateTime.now().getDayOfWeek();
        return courseEnrollmentRepository.findByStudentId(studentId).stream()
                .filter(e -> e.getStatus() == SectionEnrollmentStatus.ENROLLED)
                .map(CourseEnrollment::getLectureSection)
                .filter(s -> s.getMeetingDays() != null && s.getMeetingDays().contains(today))
                .map(s -> {
                    String room = null;
                    if (s.getClassroom() != null && s.getBuilding() != null) {
                        room = s.getBuilding().getCode() + " " + s.getClassroom().getRoomNumber();
                    } else {
                        room = "TBD";
                    }
                    LocalTime st = s.getStartTime();
                    LocalTime et = s.getEndTime();
                    return new com.uwm.paws360.DTO.Course.TodayScheduleItemDTO(
                            s.getCourse().getCourseCode(),
                            s.getCourse().getCourseName(),
                            st, et, room
                    );
                })
                .sorted(java.util.Comparator.comparing(com.uwm.paws360.DTO.Course.TodayScheduleItemDTO::startTime))
                .collect(Collectors.toList());
    }

    private boolean hasCapacity(CourseSection section) {
        Integer max = section.getMaxEnrollment();
        return max == null || section.getCurrentEnrollment() < max;
    }

    private boolean hasWaitlistCapacity(CourseSection section) {
        Integer capacity = section.getWaitlistCapacity();
        return capacity == null || section.getCurrentWaitlist() < capacity;
    }

    private int nextWaitlistPosition(CourseSection section) {
        return section.getCurrentWaitlist() == null ? 1 : section.getCurrentWaitlist() + 1;
    }

    private void promoteWaitlistedStudents(CourseSection lectureSection) {
        if (!lectureSection.isAutoEnrollWaitlist()) {
            return;
        }

        List<CourseEnrollment> waitlisted = courseEnrollmentRepository
                .findByLectureSectionAndStatusOrderByWaitlistPositionAsc(lectureSection, SectionEnrollmentStatus.WAITLISTED);

        for (CourseEnrollment candidate : waitlisted) {
            if (!hasCapacity(lectureSection)) {
                break;
            }

            CourseSection labSection = candidate.getLabSection();
            if (labSection != null && !hasCapacity(labSection)) {
                continue;
            }

            lectureSection.incrementEnrollment();
            lectureSection.decrementWaitlist();
            if (labSection != null) {
                labSection.incrementEnrollment();
            }

            candidate.setStatus(SectionEnrollmentStatus.ENROLLED);
            candidate.setWaitlistPosition(null);
            candidate.setWaitlistedAt(null);
            candidate.setAutoEnrolledFromWaitlist(true);
            candidate.setEnrolledAt(OffsetDateTime.now());
            courseEnrollmentRepository.save(candidate);
        }
    }

    private void rebalanceWaitlistPositions(CourseSection lectureSection) {
        List<CourseEnrollment> waitlisted = courseEnrollmentRepository
                .findByLectureSectionAndStatusOrderByWaitlistPositionAsc(lectureSection, SectionEnrollmentStatus.WAITLISTED);

        int position = 1;
        for (CourseEnrollment enrollment : waitlisted) {
            enrollment.setWaitlistPosition(position++);
            courseEnrollmentRepository.save(enrollment);
        }
    }

    public CourseEnrollmentResponseDTO toResponse(CourseEnrollment enrollment) {
        Long labId = enrollment.getLabSection() != null ? enrollment.getLabSection().getId() : null;
        return new CourseEnrollmentResponseDTO(
                enrollment.getId(),
                enrollment.getStudent().getId(),
                enrollment.getLectureSection().getId(),
                labId,
                enrollment.getStatus(),
                enrollment.getWaitlistPosition(),
                enrollment.isAutoEnrolledFromWaitlist(),
                enrollment.getEnrolledAt(),
                enrollment.getWaitlistedAt(),
                enrollment.getDroppedAt()
        );
    }

    // Grade updates
    @Transactional
    public CourseEnrollmentResponseDTO updateCurrentGrade(GradeUpdateRequestDTO request) {
        CourseEnrollment enrollment = courseEnrollmentRepository
                .findByStudentIdAndLectureSectionId(request.studentId(), request.lectureSectionId())
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Enrollment not found for student " + request.studentId()));
        if (request.currentLetter() != null) {
            enrollment.setCurrentLetter(request.currentLetter());
        }
        if (request.currentPercentage() != 0) {
            enrollment.setCurrentPercentage(request.currentPercentage());
        }
        enrollment.setLastGradeUpdate(java.time.OffsetDateTime.now());
        CourseEnrollment saved = courseEnrollmentRepository.save(enrollment);
        return toResponse(saved);
    }

    @Transactional
    public CourseEnrollmentResponseDTO finalizeGrade(FinalizeGradeRequestDTO request) {
        CourseEnrollment enrollment = courseEnrollmentRepository
                .findByStudentIdAndLectureSectionId(request.studentId(), request.lectureSectionId())
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Enrollment not found for student " + request.studentId()));
        enrollment.setFinalLetter(request.finalLetter());
        enrollment.setStatus(com.uwm.paws360.Entity.EntityDomains.SectionEnrollmentStatus.COMPLETED);
        enrollment.setCompletedAt(java.time.OffsetDateTime.now());
        CourseEnrollment saved = courseEnrollmentRepository.save(enrollment);
        return toResponse(saved);
    }
}
