package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Academics.AssignStudentProgramRequestDTO;
import com.uwm.paws360.DTO.Academics.CreateDegreeProgramRequestDTO;
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

    public AcademicsAdminController(AcademicsAdminService service) {
        this.service = service;
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
}

