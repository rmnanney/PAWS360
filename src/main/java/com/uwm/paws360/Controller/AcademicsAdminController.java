package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Academics.AssignStudentProgramRequestDTO;
import com.uwm.paws360.DTO.Academics.CreateDegreeProgramRequestDTO;
import com.uwm.paws360.DTO.Academics.CreateDegreeRequirementRequestDTO;
import com.uwm.paws360.Entity.Academics.DegreeRequirement;
import com.uwm.paws360.Entity.Course.Courses;
import com.uwm.paws360.JPARepository.Academics.DegreeProgramRepository;
import com.uwm.paws360.JPARepository.Academics.DegreeRequirementRepository;
import com.uwm.paws360.JPARepository.Course.CourseRepository;
import com.uwm.paws360.Entity.Academics.DegreeProgram;
import com.uwm.paws360.Entity.Academics.StudentProgram;
import com.uwm.paws360.Service.AcademicsAdminService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/academics/admin")
public class AcademicsAdminController {

    private final AcademicsAdminService service;
    private final DegreeProgramRepository degreeProgramRepository;
    private final DegreeRequirementRepository degreeRequirementRepository;
    private final CourseRepository courseRepository;

    public AcademicsAdminController(AcademicsAdminService service,
                                    DegreeProgramRepository degreeProgramRepository,
                                    DegreeRequirementRepository degreeRequirementRepository,
                                    CourseRepository courseRepository) {
        this.service = service;
        this.degreeProgramRepository = degreeProgramRepository;
        this.degreeRequirementRepository = degreeRequirementRepository;
        this.courseRepository = courseRepository;
    }

    @PostMapping("/programs")
    public ResponseEntity<DegreeProgram> createProgram(@Valid @RequestBody CreateDegreeProgramRequestDTO req) {
        DegreeProgram dp = service.createOrGetProgram(req.code(), req.name(), req.totalCreditsRequired());
        return ResponseEntity.ok(dp);
    }

    @PostMapping("/students/{studentId}/program")
    public ResponseEntity<StudentProgram> assignProgram(@PathVariable Integer studentId,
                                                        @Valid @RequestBody AssignStudentProgramRequestDTO req) {
        StudentProgram sp = service.assignProgramToStudent(studentId, req.degreeId(), req.expectedGradTerm(), req.expectedGradYear(), req.primary());
        return ResponseEntity.ok(sp);
    }

    @PostMapping("/programs/{degreeId}/requirements")
    public ResponseEntity<DegreeRequirement> addRequirement(@PathVariable Long degreeId,
                                                            @Valid @RequestBody CreateDegreeRequirementRequestDTO req) {
        var program = degreeProgramRepository.findById(degreeId)
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Degree program not found for id " + degreeId));
        Courses course = courseRepository.findById(req.courseId())
                .orElseThrow(() -> new jakarta.persistence.EntityNotFoundException("Course not found for id " + req.courseId()));
        DegreeRequirement dr = new DegreeRequirement();
        dr.setDegreeProgram(program);
        dr.setCourse(course);
        if (req.required() != null) dr.setRequired(req.required());
        DegreeRequirement saved = degreeRequirementRepository.save(dr);
        return ResponseEntity.ok(saved);
    }
}

