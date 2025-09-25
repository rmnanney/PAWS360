package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.UserRole.Professor;
import com.uwm.paws360.Entity.UserRole.Student;
import com.uwm.paws360.Entity.Users;
import com.uwm.paws360.JPARepository.ProfessorRepository;
import com.uwm.paws360.JPARepository.StudentRepository;
import com.uwm.paws360.JPARepository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final StudentRepository studentRepository;
    private final ProfessorRepository professorRepository;

    public UserService(
            UserRepository userRepository,
            StudentRepository studentRepository,
            ProfessorRepository professorRepository
    ){
        this.userRepository = userRepository;
        this.studentRepository = studentRepository;
        this.professorRepository = professorRepository;
    }

    public Users createUser(Users user){
        Users newUser = userRepository.save(user);
        switch(user.getRoles()){
            case STUDENT -> {
                Student student = new Student(newUser, 0);
                studentRepository.save(student);
                break;
            }
            case PROFESSOR -> {
                Professor professor = new Professor(newUser, 0);
                professorRepository.save(professor);
                break;
            }
        }
        return newUser;
    }


}
