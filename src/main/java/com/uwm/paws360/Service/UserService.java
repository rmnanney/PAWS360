package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.User.*;
import com.uwm.paws360.Entity.UserTypes.*;
import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.JPARepository.User.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import com.uwm.paws360.Entity.EntityDomains.User.Role;

@Service
@Transactional
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
    private final AddressRepository addressRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public UserService(UserRepository userRepository, AdvisorRepository advisorRepository,
                       CounselorRepository counselorRepository, FacultyRepository facultyRepository,
                       InstructorRepository instructorRepository, MentorRepository mentorRepository,
                       ProfessorRepository professorRepository, StudentRepository studentRepository,
                       TARepository taRepository, AddressRepository addressRepository
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
        this.addressRepository = addressRepository;
    }

    public UserResponseDTO createUser(CreateUserDTO user){
        Users newUser = new Users(
                user.firstname(),
                user.middlename(),
                user.lastname(),
                user.dob(),
                user.email(),
                hashIfNeeded(user.password()),
                user.countryCode(),
                user.phone(),
                user.status(),
                user.role()
        );

        if (user.addresses() != null) {
            for (var addrDto : user.addresses()) {
                Address addr = new Address();
                addr.setUser(newUser);
                addr.setAddress_type(addrDto.address_type());
                addr.setFirstname(newUser.getFirstname());
                addr.setLastname(newUser.getLastname());
                addr.setStreet_address_1(addrDto.street_address_1());
                addr.setStreet_address_2(addrDto.street_address_2());
                addr.setPo_box(addrDto.po_box());
                addr.setCity(addrDto.city());
                addr.setUs_state(addrDto.us_states());
                addr.setZipcode(addrDto.zipcode());
                newUser.getAddresses().add(addr);
            }
        }

        userRepository.save(newUser);
        switch(newUser.getRole()){
            case ADVISOR: {
                Advisor newAdvisor = new Advisor(newUser);
                advisorRepository.save(newAdvisor);
                break;
            }
            case COUNSELOR: {
                Counselor newCounselor = new Counselor(newUser);
                counselorRepository.save(newCounselor);
                break;
            }
            case FACULTY: {
                Faculty newFaculty = new Faculty(newUser);
                facultyRepository.save(newFaculty);
                break;
            }
            case INSTRUCTOR: {
                Instructor newInstructor = new Instructor(newUser);
                instructorRepository.save(newInstructor);
                break;
            }
            case MENTOR: {
                Mentor newMentor = new Mentor(newUser);
                mentorRepository.save(newMentor);
                break;
            }
            case PROFESSOR: {
                Professor newProfessor = new Professor(newUser);
                professorRepository.save(newProfessor);
                break;
            }
            case STUDENT: {
                Student newStudent = new Student(newUser);
                studentRepository.save(newStudent);
                break;
            }
            case TA: {
                TA newTA = new TA(newUser);
                taRepository.save(newTA);
                break;
            }
            default: {
                break;
            }
        }

        return toUserResponseDTO(newUser);
    }

    public UserResponseDTO editUser(EditUserRequestDTO userDTO){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(userDTO.email());
        if(user == null) return new UserResponseDTO(-1, null, null, null,
                null, null, null, null, null, List.of());
        user.setFirstname(userDTO.firstname());
        user.setMiddlename(userDTO.middlename());
        user.setLastname(userDTO.lastname());
        user.setDob(userDTO.dob());
        user.setPassword(hashIfNeeded(userDTO.password()));
        user.setCountryCode(userDTO.countryCode());
        user.setPhone(userDTO.phone());
        userRepository.save(user);
        return toUserResponseDTO(user);
    }

    public boolean deleteUser(DeleteUserRequestDTO deleteUserRequestDTO){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(deleteUserRequestDTO.email());
        if(user == null) return false;
        // Remove role records first to satisfy FK constraints
        advisorRepository.deleteByUser(user);
        counselorRepository.deleteByUser(user);
        facultyRepository.deleteByUser(user);
        instructorRepository.deleteByUser(user);
        mentorRepository.deleteByUser(user);
        professorRepository.deleteByUser(user);
        studentRepository.deleteByUser(user);
        taRepository.deleteByUser(user);
        // Addresses are cascaded from Users (orphanRemoval = true)
        userRepository.delete(user);
        return true;
    }

    // Address management
    public UserResponseDTO addAddress(AddAddressRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return new UserResponseDTO(-1, null, null, null,
                null, null, null, null, null, List.of());
        Address addr = new Address();
        addr.setUser(user);
        addr.setAddress_type(dto.address().address_type());
        addr.setFirstname(user.getFirstname());
        addr.setLastname(user.getLastname());
        addr.setStreet_address_1(dto.address().street_address_1());
        addr.setStreet_address_2(dto.address().street_address_2());
        addr.setPo_box(dto.address().po_box());
        addr.setCity(dto.address().city());
        addr.setUs_state(dto.address().us_states());
        addr.setZipcode(dto.address().zipcode());
        user.getAddresses().add(addr);
        userRepository.save(user);
        return toUserResponseDTO(user);
    }

    public UserResponseDTO editAddress(EditAddressRequestDTO dto){
        Optional<Address> addressOpt = addressRepository.findById(dto.address_id());
        if (addressOpt.isEmpty()) return new UserResponseDTO(-1, null, null, null,
                null, null, null, null, null, List.of());
        Address addr = addressOpt.get();
        addr.setAddress_type(dto.address().address_type());
        addr.setStreet_address_1(dto.address().street_address_1());
        addr.setStreet_address_2(dto.address().street_address_2());
        addr.setPo_box(dto.address().po_box());
        addr.setCity(dto.address().city());
        addr.setUs_state(dto.address().us_states());
        addr.setZipcode(dto.address().zipcode());
        addressRepository.save(addr);
        return toUserResponseDTO(addr.getUser());
    }

    public boolean deleteAddress(DeleteAddressRequestDTO dto){
        Optional<Address> addressOpt = addressRepository.findById(dto.address_id());
        if (addressOpt.isEmpty()) return false;
        addressRepository.delete(addressOpt.get());
        return true;
    }

    public List<AddressDTO> listAddresses(ListAddressesRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return List.of();
        return toAddressDTOs(user.getAddresses());
    }

    public List<Role> listRoles(ListRolesRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return List.of();
        List<Role> roles = new ArrayList<>();
        if (user.getRole() != null) roles.add(user.getRole());
        if (advisorRepository.findByUser(user).isPresent()) roles.add(Role.ADVISOR);
        if (counselorRepository.findByUser(user).isPresent()) roles.add(Role.COUNSELOR);
        if (facultyRepository.findByUser(user).isPresent()) roles.add(Role.FACULTY);
        if (instructorRepository.findByUser(user).isPresent()) roles.add(Role.INSTRUCTOR);
        if (mentorRepository.findByUser(user).isPresent()) roles.add(Role.MENTOR);
        if (professorRepository.findByUser(user).isPresent()) roles.add(Role.PROFESSOR);
        if (studentRepository.findByUser(user).isPresent()) roles.add(Role.STUDENT);
        if (taRepository.findByUser(user).isPresent()) roles.add(Role.TA);
        return roles;
    }

    // Role management
    public boolean assignRole(ModifyRoleRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return false;
        switch (dto.role()){
            case ADVISOR: {
                if (advisorRepository.findByUser(user).isEmpty()) advisorRepository.save(new Advisor(user));
                break;
            }
            case COUNSELOR: {
                if (counselorRepository.findByUser(user).isEmpty()) counselorRepository.save(new Counselor(user));
                break;
            }
            case FACULTY: {
                if (facultyRepository.findByUser(user).isEmpty()) facultyRepository.save(new Faculty(user));
                break;
            }
            case INSTRUCTOR: {
                if (instructorRepository.findByUser(user).isEmpty()) instructorRepository.save(new Instructor(user));
                break;
            }
            case MENTOR: {
                if (mentorRepository.findByUser(user).isEmpty()) mentorRepository.save(new Mentor(user));
                break;
            }
            case PROFESSOR: {
                if (professorRepository.findByUser(user).isEmpty()) professorRepository.save(new Professor(user));
                break;
            }
            case STUDENT: {
                if (studentRepository.findByUser(user).isEmpty()) studentRepository.save(new Student(user));
                break;
            }
            case TA: {
                if (taRepository.findByUser(user).isEmpty()) taRepository.save(new TA(user));
                break;
            }
            default: {
                break;
            }
        }
        return true;
    }

    public boolean removeRole(ModifyRoleRequestDTO dto){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(dto.email());
        if (user == null) return false;
        switch (dto.role()){
            case ADVISOR: { advisorRepository.deleteByUser(user); break; }
            case COUNSELOR: { counselorRepository.deleteByUser(user); break; }
            case FACULTY: { facultyRepository.deleteByUser(user); break; }
            case INSTRUCTOR: { instructorRepository.deleteByUser(user); break; }
            case MENTOR: { mentorRepository.deleteByUser(user); break; }
            case PROFESSOR: { professorRepository.deleteByUser(user); break; }
            case STUDENT: { studentRepository.deleteByUser(user); break; }
            case TA: { taRepository.deleteByUser(user); break; }
            default: { break; }
        }
        return true;
    }

    // Helpers
    private String hashIfNeeded(String raw){
        if (raw == null) return null;
        if (isBCrypt(raw)) return raw;
        return passwordEncoder.encode(raw);
    }

    private boolean isBCrypt(String value){
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }

    private UserResponseDTO toUserResponseDTO(Users u){
        return new UserResponseDTO(
                u.getId(),
                u.getEmail(),
                u.getFirstname(),
                u.getLastname(),
                u.getRole(),
                u.getStatus(),
                u.getDob(),
                u.getCountryCode(),
                u.getPhone(),
                toAddressDTOs(u.getAddresses())
        );
    }

    private List<AddressDTO> toAddressDTOs(List<Address> addresses){
        List<AddressDTO> list = new ArrayList<>();
        if (addresses == null) return list;
        for (Address a : addresses){
            list.add(new AddressDTO(
                    a.getId(),
                    a.getAddress_type(),
                    a.getStreet_address_1(),
                    a.getStreet_address_2(),
                    a.getPo_box(),
                    a.getCity(),
                    a.getUs_state(),
                    a.getZipcode()
            ));
        }
        return list;
    }
}
