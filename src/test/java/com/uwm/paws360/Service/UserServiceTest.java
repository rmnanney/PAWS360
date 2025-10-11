package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.User.CreateUserDTO;
import com.uwm.paws360.DTO.User.EditUserRequestDTO;
import com.uwm.paws360.DTO.User.UserResponseDTO;
import com.uwm.paws360.Entity.Base.Address;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Entity.UserTypes.*;
import com.uwm.paws360.JPARepository.User.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private AdvisorRepository advisorRepository;
    @Mock
    private CounselorRepository counselorRepository;
    @Mock
    private FacultyRepository facultyRepository;
    @Mock
    private InstructorRepository instructorRepository;
    @Mock
    private MentorRepository mentorRepository;
    @Mock
    private ProfessorRepository professorRepository;
    @Mock
    private StudentRepository studentRepository;
    @Mock
    private TARepository taRepository;

    @InjectMocks
    private UserService userService;

    private CreateUserDTO createUserDTO;
    private Users savedUser;

    @BeforeEach
    void setUp() {
        // Create a proper Address object
        Address address = new Address();
        address.setAddress_type(com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME);
        address.setStreet_address_1("123 Main St");
        address.setCity("Milwaukee");
        address.setUs_state(com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN);
        address.setZipcode("53201");

        createUserDTO = new CreateUserDTO(
            "John",
            "Middle",
            "Doe",
            LocalDate.of(1990, 1, 1),
            "john.doe@example.com",
            "password123",
            address,
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US,
            "555-0123",
            Status.ACTIVE,
            Role.STUDENT
        );

        savedUser = new Users();
        savedUser.setFirstname("John");
        savedUser.setMiddlename("Middle");
        savedUser.setLastname("Doe");
        savedUser.setDob(LocalDate.of(1990, 1, 1));
        savedUser.setEmail("john.doe@example.com");
        savedUser.setPassword("password123");
        savedUser.setAddress(address);
        savedUser.setCountryCode(com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US);
        savedUser.setPhone("555-0123");
        savedUser.setStatus(Status.ACTIVE);
        savedUser.setRole(Role.STUDENT);
        savedUser.setFailed_attempts(0);
        savedUser.setAccount_locked(false);
        savedUser.setFerpa_compliance(com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED);
    }

    @Test
    void createUser_StudentRole_CreatesUserAndStudent() {
        // Arrange
        when(userRepository.save(any(Users.class))).thenReturn(savedUser);
        when(studentRepository.save(any(Student.class))).thenReturn(new Student(savedUser));

        // Act
        UserResponseDTO response = userService.createUser(createUserDTO);

        // Assert
        assertEquals(0, response.user_id()); // Default int value since not set
        assertEquals("john.doe@example.com", response.email());
        assertEquals("John", response.firstname());
        assertEquals("Doe", response.lastname());
        assertEquals(Role.STUDENT, response.role());
        assertEquals(Status.ACTIVE, response.status());

        verify(userRepository).save(any(Users.class));
        verify(studentRepository).save(any(Student.class));
    }

    @Test
    void createUser_AdvisorRole_CreatesUserAndAdvisor() {
        // Arrange
        Address advisorAddress = new Address();
        advisorAddress.setAddress_type(com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME);
        advisorAddress.setStreet_address_1("456 Oak St");
        advisorAddress.setCity("Milwaukee");
        advisorAddress.setUs_state(com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN);
        advisorAddress.setZipcode("53201");

        CreateUserDTO advisorDTO = new CreateUserDTO(
            "Jane", "M", "Smith", LocalDate.of(1985, 5, 15),
            "jane.smith@example.com", "password123", advisorAddress,
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0456", Status.ACTIVE, Role.ADVISOR
        );

        Users advisorUser = new Users();
        advisorUser.setRole(Role.ADVISOR);
        advisorUser.setEmail("jane.smith@example.com");
        advisorUser.setFirstname("Jane");
        advisorUser.setLastname("Smith");
        advisorUser.setStatus(Status.ACTIVE);
        advisorUser.setFailed_attempts(0);
        advisorUser.setAccount_locked(false);
        advisorUser.setFerpa_compliance(com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED);

        when(userRepository.save(any(Users.class))).thenReturn(advisorUser);
        when(advisorRepository.save(any(Advisor.class))).thenReturn(new Advisor(advisorUser));

        // Act
        UserResponseDTO response = userService.createUser(advisorDTO);

        // Assert
        assertEquals(0, response.user_id()); // Default int value since not set
        assertEquals(Role.ADVISOR, response.role());

        verify(advisorRepository).save(any(Advisor.class));
    }

    @Test
    void createUser_ProfessorRole_CreatesUserAndProfessor() {
        // Arrange
        Address professorAddress = new Address();
        professorAddress.setAddress_type(com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME);
        professorAddress.setStreet_address_1("789 University Ave");
        professorAddress.setCity("Milwaukee");
        professorAddress.setUs_state(com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN);
        professorAddress.setZipcode("53201");

        CreateUserDTO professorDTO = new CreateUserDTO(
            "Dr.", "A", "Johnson", LocalDate.of(1975, 3, 20),
            "dr.johnson@example.com", "password123", professorAddress,
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0789", Status.ACTIVE, Role.PROFESSOR
        );

        Users professorUser = new Users();
        professorUser.setRole(Role.PROFESSOR);
        professorUser.setEmail("dr.johnson@example.com");
        professorUser.setFirstname("Dr.");
        professorUser.setLastname("Johnson");
        professorUser.setStatus(Status.ACTIVE);
        professorUser.setFailed_attempts(0);
        professorUser.setAccount_locked(false);
        professorUser.setFerpa_compliance(com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED);

        when(userRepository.save(any(Users.class))).thenReturn(professorUser);
        when(professorRepository.save(any(Professor.class))).thenReturn(new Professor(professorUser));

        // Act
        UserResponseDTO response = userService.createUser(professorDTO);

        // Assert
        assertEquals(0, response.user_id()); // Default int value since not set
        assertEquals(Role.PROFESSOR, response.role());

        verify(professorRepository).save(any(Professor.class));
    }

    @Test
    void createUser_AllFieldsMappedCorrectly() {
        // Arrange
        when(userRepository.save(any(Users.class))).thenReturn(savedUser);
        when(studentRepository.save(any(Student.class))).thenReturn(new Student(savedUser));

        // Act
        UserResponseDTO response = userService.createUser(createUserDTO);

        // Assert
        assertEquals(savedUser.getId(), response.user_id());
        assertEquals(savedUser.getEmail(), response.email());
        assertEquals(savedUser.getFirstname(), response.firstname());
        assertEquals(savedUser.getLastname(), response.lastname());
        assertEquals(savedUser.getRole(), response.role());
        assertEquals(savedUser.getStatus(), response.status());
        assertEquals(savedUser.getDob(), response.dob());
        assertEquals(savedUser.getCountryCode(), response.country_code());
        assertEquals(savedUser.getPhone(), response.phone());
    }

    @Test
    void editUser_UserExists_UpdatesAndReturnsUser() {
        // Arrange
        EditUserRequestDTO editDTO = new EditUserRequestDTO(
            "Johnny",
            "Mid",
            "Doe Jr.",
            LocalDate.of(1990, 2, 2),
            "john.doe@example.com",
            "newpassword123",
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US,
            "555-9999"
        );

        when(userRepository.findUsersByEmailLikeIgnoreCase("john.doe@example.com")).thenReturn(savedUser);
        when(userRepository.save(any(Users.class))).thenReturn(savedUser);

        // Act
        UserResponseDTO response = userService.editUser(editDTO);

        // Assert
        assertEquals(0, response.user_id()); // Default int value since not set
        assertEquals("john.doe@example.com", response.email());
        assertEquals("Johnny", response.firstname());
        assertEquals("Doe Jr.", response.lastname());

        verify(userRepository).findUsersByEmailLikeIgnoreCase("john.doe@example.com");
        verify(userRepository).save(savedUser);
    }

    @Test
    void editUser_UserNotFound_ReturnsErrorResponse() {
        // Arrange
        EditUserRequestDTO editDTO = new EditUserRequestDTO(
            "Johnny", "Mid", "Doe Jr.",
            LocalDate.of(1990, 2, 2),
            "nonexistent@example.com",
            "newpassword123",
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US,
            "555-9999"
        );

        when(userRepository.findUsersByEmailLikeIgnoreCase("nonexistent@example.com")).thenReturn(null);

        // Act
        UserResponseDTO response = userService.editUser(editDTO);

        // Assert
        assertEquals(-1, response.user_id());
        assertNull(response.email());
        assertNull(response.firstname());
        assertNull(response.lastname());

        verify(userRepository).findUsersByEmailLikeIgnoreCase("nonexistent@example.com");
        verify(userRepository, never()).save(any(Users.class));
    }

    @Test
    void editUser_AllFieldsUpdatedCorrectly() {
        // Arrange
        EditUserRequestDTO editDTO = new EditUserRequestDTO(
            "UpdatedFirst",
            "UpdatedMiddle",
            "UpdatedLast",
            LocalDate.of(1995, 5, 5),
            "john.doe@example.com",
            "updatedpassword",
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.GB,
            "777-8888"
        );

        when(userRepository.findUsersByEmailLikeIgnoreCase("john.doe@example.com")).thenReturn(savedUser);
        when(userRepository.save(any(Users.class))).thenReturn(savedUser);

        // Act
        userService.editUser(editDTO);

        // Assert
        verify(userRepository).save(argThat(user -> {
            return "UpdatedFirst".equals(user.getFirstname()) &&
                   "UpdatedMiddle".equals(user.getMiddlename()) &&
                   "UpdatedLast".equals(user.getLastname()) &&
                   "updatedpassword".equals(user.getPassword()) &&
                   com.uwm.paws360.Entity.EntityDomains.User.Country_Code.GB.equals(user.getCountryCode()) &&
                   "777-8888".equals(user.getPhone()) &&
                   LocalDate.of(1995, 5, 5).equals(user.getDob());
        }));
    }

    @Test
    void createUser_CounselorRole_CreatesUserAndCounselor() {
        // Arrange
        Address counselorAddress = new Address();
        counselorAddress.setAddress_type(com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME);
        counselorAddress.setStreet_address_1("321 Counseling St");
        counselorAddress.setCity("Milwaukee");
        counselorAddress.setUs_state(com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN);
        counselorAddress.setZipcode("53201");

        CreateUserDTO counselorDTO = new CreateUserDTO(
            "Sarah", "L", "Wilson", LocalDate.of(1980, 8, 10),
            "sarah.wilson@example.com", "password123", counselorAddress,
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0321", Status.ACTIVE, Role.COUNSELOR
        );

        Users counselorUser = new Users();
        counselorUser.setRole(Role.COUNSELOR);
        counselorUser.setFailed_attempts(0);
        counselorUser.setAccount_locked(false);
        counselorUser.setFerpa_compliance(com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED);

        when(userRepository.save(any(Users.class))).thenReturn(counselorUser);
        when(counselorRepository.save(any(Counselor.class))).thenReturn(new Counselor(counselorUser));

        // Act
        UserResponseDTO response = userService.createUser(counselorDTO);

        // Assert
        assertEquals(0, response.user_id()); // Default int value since not set
        assertEquals(Role.COUNSELOR, response.role());

        verify(counselorRepository).save(any(Counselor.class));
    }

    @Test
    void createUser_InstructorRole_CreatesUserAndInstructor() {
        // Arrange
        Address instructorAddress = new Address();
        instructorAddress.setAddress_type(com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME);
        instructorAddress.setStreet_address_1("654 Teaching Ave");
        instructorAddress.setCity("Milwaukee");
        instructorAddress.setUs_state(com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN);
        instructorAddress.setZipcode("53201");

        CreateUserDTO instructorDTO = new CreateUserDTO(
            "Mike", "T", "Brown", LocalDate.of(1982, 11, 25),
            "mike.brown@example.com", "password123", instructorAddress,
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0654", Status.ACTIVE, Role.INSTRUCTOR
        );

        Users instructorUser = new Users();
        instructorUser.setRole(Role.INSTRUCTOR);
        instructorUser.setFailed_attempts(0);
        instructorUser.setAccount_locked(false);
        instructorUser.setFerpa_compliance(com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance.RESTRICTED);

        when(userRepository.save(any(Users.class))).thenReturn(instructorUser);
        when(instructorRepository.save(any(Instructor.class))).thenReturn(new Instructor(instructorUser));

        // Act
        UserResponseDTO response = userService.createUser(instructorDTO);

        // Assert
        assertEquals(0, response.user_id()); // Default int value since not set
        assertEquals(Role.INSTRUCTOR, response.role());

        verify(instructorRepository).save(any(Instructor.class));
    }
}