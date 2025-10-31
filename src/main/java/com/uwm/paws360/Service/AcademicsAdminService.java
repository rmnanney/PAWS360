package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.Academics.DegreeProgram;
import com.uwm.paws360.Entity.Academics.StudentProgram;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.JPARepository.Academics.DegreeProgramRepository;
import com.uwm.paws360.JPARepository.Academics.StudentProgramRepository;
import com.uwm.paws360.JPARepository.User.StudentRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class AcademicsAdminService {

    private final DegreeProgramRepository degreeProgramRepository;
    private final StudentRepository studentRepository;
    private final StudentProgramRepository studentProgramRepository;

    public AcademicsAdminService(DegreeProgramRepository degreeProgramRepository,
                                 StudentRepository studentRepository,
                                 StudentProgramRepository studentProgramRepository) {
        this.degreeProgramRepository = degreeProgramRepository;
        this.studentRepository = studentRepository;
        this.studentProgramRepository = studentProgramRepository;
    }

    public DegreeProgram createOrGetProgram(String code, String name, Integer credits) {
        return degreeProgramRepository.findByCodeIgnoreCase(code)
                .orElseGet(() -> {
                    DegreeProgram p = new DegreeProgram();
                    p.setCode(code);
                    p.setName(name);
                    p.setTotalCreditsRequired(credits);
                    return degreeProgramRepository.save(p);
                });
    }

    public StudentProgram assignProgramToStudent(Integer studentId, Long degreeId,
                                                 String expectedTerm, Integer expectedYear, Boolean primaryFlag) {
        Student student = studentRepository.findById(studentId)
                .orElseThrow(() -> new EntityNotFoundException("Student not found for id " + studentId));
        DegreeProgram program = degreeProgramRepository.findById(degreeId)
                .orElseThrow(() -> new EntityNotFoundException("Degree program not found for id " + degreeId));
        StudentProgram sp = new StudentProgram();
        sp.setStudent(student);
        sp.setProgram(program);
        sp.setExpectedGraduationTerm(expectedTerm);
        sp.setExpectedGraduationYear(expectedYear);
        sp.setPrimary(primaryFlag != null ? primaryFlag : true);
        return studentProgramRepository.save(sp);
    }
}

