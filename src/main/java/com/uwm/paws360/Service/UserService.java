package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.UserTypes.Professor;
import com.uwm.paws360.Entity.UserTypes.Student;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.JPARepository.User.*;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final AdvisorRepository advisorRepository;
    private final CounselorRepository counselorRepository;
    private final FacultyRepository facultyRepository;
    private final InstructorRepository instructorRepository;
    private final MentorRepository mentorRepository;
    private final ProfessorRepository professorRepository;
    private final StudentRepository studentRepository;
    private final TARepository taRepository;

    public UserService(UserRepository userRepository, AdvisorRepository advisorRepository,
                       CounselorRepository counselorRepository, FacultyRepository facultyRepository,
                       InstructorRepository instructorRepository, MentorRepository mentorRepository,
                       ProfessorRepository professorRepository, StudentRepository studentRepository,
                       TARepository taRepository
    ) {
        this.userRepository = userRepository;
        this.advisorRepository = advisorRepository;
        this.counselorRepository = counselorRepository;
        this.facultyRepository = facultyRepository;
        this.instructorRepository = instructorRepository;
        this.mentorRepository = mentorRepository;
        this.professorRepository = professorRepository;
        this.studentRepository = studentRepository;
        this.taRepository = taRepository;
    }

    public Users createUser(Users user){
        Users newUser = userRepository.save(user);
        switch(user.getRole()){
            case STUDENT -> {
                Student student = new Student(newUser);
                studentRepository.save(student);
            }
            case PROFESSOR -> {
                Professor professor = new Professor(newUser);
                professorRepository.save(professor);
            }
        }
        return newUser;
    }


}
