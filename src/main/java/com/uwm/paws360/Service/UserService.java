package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.UserTypes.*;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.JPARepository.User.*;
import org.springframework.stereotype.Service;
import com.uwm.paws360.DTO.Basic.CreateUserDTO;
import com.uwm.paws360.DTO.Basic.UserResponseDTO;

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

    public UserResponseDTO createUser(CreateUserDTO user){
        Users newUser = new Users(
                user.firstname(),
                user.middlename(),
                user.lastname(),
                user.dob(),
                user.email(),
                user.password(),
                user.address(),
                user.countryCode(),
                user.phone(),
                user.status(),
                user.role()
        );

        userRepository.save(newUser);
        switch(newUser.getRole()){
            case ADVISOR:
                Advisor newAdvisor = new Advisor(newUser);
                advisorRepository.save(newAdvisor);
            case COUNSELOR:
                Counselor newCounselor = new Counselor(newUser);
                counselorRepository.save(newCounselor);
            case FACULTY:
                Faculty newFaculty = new Faculty(newUser);
                facultyRepository.save(newFaculty);
            case INSTRUCTOR:
                Instructor newInstructor = new Instructor(newUser);
                instructorRepository.save(newInstructor);
            case MENTOR:
                Mentor newMentor = new Mentor(newUser);
                mentorRepository.save(newMentor);
            case PROFESSOR:
                Professor newProfessor = new Professor(newUser);
                professorRepository.save(newProfessor);
            case STUDENT:
                Student newStudent = new Student(newUser);
                studentRepository.save(newStudent);
            case TA:
                TA newTA = new TA(newUser);
                taRepository.save(newTA);
        }

        return new UserResponseDTO(
                newUser.getId(),
                newUser.getEmail(),
                newUser.getFirstname(),
                newUser.getLastname(),
                newUser.getRole(),
                newUser.getStatus(),
                newUser.getDob(),
                newUser.getCountryCode(),
                newUser.getPhone()
        );
    }


}
