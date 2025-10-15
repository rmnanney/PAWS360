package com.uwm.paws360.Controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uwm.paws360.DTO.User.CreateUserDTO;
import com.uwm.paws360.DTO.User.EditUserRequestDTO;
import com.uwm.paws360.DTO.User.UserResponseDTO;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createUser_ValidRequest_ReturnsCreatedUser() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO address = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "123 Main St",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "John", "Middle", "Doe", LocalDate.of(1990, 1, 1),
            "john.doe@example.com", "password123", List.of(address),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0123", Status.ACTIVE, Role.STUDENT
        );

        UserResponseDTO response = new UserResponseDTO(
            1, "john.doe@example.com", "John", "Doe",
            Role.STUDENT, Status.ACTIVE, LocalDate.of(1990, 1, 1),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0123",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.email").value("john.doe@example.com"))
                .andExpect(jsonPath("$.firstname").value("John"))
                .andExpect(jsonPath("$.lastname").value("Doe"))
                .andExpect(jsonPath("$.role").value("STUDENT"))
                .andExpect(jsonPath("$.status").value("ACTIVE"));
    }

    @Test
    void createUser_InvalidRequest_ReturnsBadRequest() throws Exception {
        // Arrange - missing required fields
        String invalidRequest = "{}";

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidRequest))
                .andExpect(status().isBadRequest()); // Validation should reject invalid request
    }

    @Test
    void createUser_ProfessorRole_CreatesProfessor() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO professorAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "789 University Ave",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Dr.", "Smith", "Johnson", LocalDate.of(1975, 3, 20),
            "dr.johnson@example.com", "password123", List.of(professorAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0789", Status.ACTIVE, Role.PROFESSOR
        );

        UserResponseDTO response = new UserResponseDTO(
            2, "dr.johnson@example.com", "Dr.", "Johnson",
            Role.PROFESSOR, Status.ACTIVE, LocalDate.of(1975, 3, 20),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0789",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("PROFESSOR"));
    }

    @Test
    void editUser_ValidRequest_ReturnsUpdatedUser() throws Exception {
        // Arrange
        EditUserRequestDTO request = new EditUserRequestDTO(
            "Johnny", "Mid", "Doe Jr.",
            LocalDate.of(1990, 2, 2), "john.doe@example.com", "newpassword123",
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-9999"
        );

        UserResponseDTO response = new UserResponseDTO(
            1, "john.doe@example.com", "Johnny", "Doe Jr.",
            Role.STUDENT, Status.ACTIVE, LocalDate.of(1990, 2, 2),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-9999",
            List.of()
        );

        when(userService.editUser(any(EditUserRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/edit")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.firstname").value("Johnny"))
                .andExpect(jsonPath("$.lastname").value("Doe Jr."));
    }

    @Test
    void editUser_UserNotFound_ReturnsBadRequest() throws Exception {
        // Arrange
        EditUserRequestDTO request = new EditUserRequestDTO(
            "Johnny", "Mid", "Doe Jr.",
            LocalDate.of(1990, 2, 2), "nonexistent@example.com", "newpassword123",
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-9999"
        );

        UserResponseDTO response = new UserResponseDTO(
            -1, null, null, null, null, null, null, null, null, null
        );

        when(userService.editUser(any(EditUserRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/edit")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.user_id").value(-1));
    }

    @Test
    void editUser_InvalidEmail_ReturnsBadRequest() throws Exception {
        // Arrange - missing email field
        String invalidRequest = "{\"firstname\": \"John\", \"lastname\": \"Doe\"}";

        // Act & Assert
        mockMvc.perform(post("/users/edit")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidRequest))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createUser_AdvisorRole_CreatesAdvisor() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO advisorAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "456 Oak St",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Jane", "Advisor", "Smith", LocalDate.of(1985, 5, 15),
            "jane.smith@example.com", "password123", List.of(advisorAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0456", Status.ACTIVE, Role.ADVISOR
        );

        UserResponseDTO response = new UserResponseDTO(
            3, "jane.smith@example.com", "Jane", "Smith",
            Role.ADVISOR, Status.ACTIVE, LocalDate.of(1985, 5, 15),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0456",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("ADVISOR"));
    }

    @Test
    void createUser_CounselorRole_CreatesCounselor() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO counselorAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "321 Counseling St",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Sarah", "Counselor", "Wilson", LocalDate.of(1980, 8, 10),
            "sarah.wilson@example.com", "password123", List.of(counselorAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0321", Status.ACTIVE, Role.COUNSELOR
        );

        UserResponseDTO response = new UserResponseDTO(
            4, "sarah.wilson@example.com", "Sarah", "Wilson",
            Role.COUNSELOR, Status.ACTIVE, LocalDate.of(1980, 8, 10),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0321",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("COUNSELOR"));
    }

    @Test
    void createUser_MentorRole_CreatesMentor() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO mentorAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "654 Mentor Ave",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Mike", "Mentor", "Johnson", LocalDate.of(1982, 11, 25),
            "mike.johnson@example.com", "password123", List.of(mentorAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0654", Status.ACTIVE, Role.MENTOR
        );

        UserResponseDTO response = new UserResponseDTO(
            5, "mike.johnson@example.com", "Mike", "Johnson",
            Role.MENTOR, Status.ACTIVE, LocalDate.of(1982, 11, 25),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0654",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("MENTOR"));
    }

    @Test
    void createUser_InstructorRole_CreatesInstructor() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO instructorAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "987 Instructor Blvd",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Prof", "Instructor", "Davis", LocalDate.of(1978, 7, 12),
            "prof.davis@example.com", "password123", List.of(instructorAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0987", Status.ACTIVE, Role.INSTRUCTOR
        );

        UserResponseDTO response = new UserResponseDTO(
            6, "prof.davis@example.com", "Prof", "Davis",
            Role.INSTRUCTOR, Status.ACTIVE, LocalDate.of(1978, 7, 12),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0987",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("INSTRUCTOR"));
    }

    @Test
    void createUser_FacultyRole_CreatesFaculty() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO facultyAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "147 Faculty St",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Dr", "Faculty", "Wilson", LocalDate.of(1970, 1, 5),
            "dr.wilson@example.com", "password123", List.of(facultyAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0147", Status.ACTIVE, Role.FACULTY
        );

        UserResponseDTO response = new UserResponseDTO(
            7, "dr.wilson@example.com", "Dr", "Wilson",
            Role.FACULTY, Status.ACTIVE, LocalDate.of(1970, 1, 5),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0147",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("FACULTY"));
    }

    @Test
    void createUser_TARole_CreatesTA() throws Exception {
        // Arrange
        com.uwm.paws360.DTO.User.AddressDTO taAddressDTO = new com.uwm.paws360.DTO.User.AddressDTO(
            null,
            com.uwm.paws360.Entity.EntityDomains.User.Address_Type.HOME,
            "258 TA Lane",
            null,
            null,
            "Milwaukee",
            com.uwm.paws360.Entity.EntityDomains.User.US_States.WISCONSIN,
            "53201"
        );

        CreateUserDTO request = new CreateUserDTO(
            "Alex", "TA", "Brown", LocalDate.of(1995, 9, 18),
            "alex.brown@example.com", "password123", List.of(taAddressDTO),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0258", Status.ACTIVE, Role.TA
        );

        UserResponseDTO response = new UserResponseDTO(
            8, "alex.brown@example.com", "Alex", "Brown",
            Role.TA, Status.ACTIVE, LocalDate.of(1995, 9, 18),
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0258",
            List.of()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/users/create")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("TA"));
    }

    @Test
    void editUser_NullRequestBody_ReturnsBadRequest() throws Exception {
        // Act & Assert
        mockMvc.perform(post("/users/edit")
                .contentType(MediaType.APPLICATION_JSON)
                .content(""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void editUser_ServiceReturnsNull_ReturnsInternalServerError() throws Exception {
        // Arrange
        EditUserRequestDTO request = new EditUserRequestDTO(
            "Johnny", "Mid", "Doe Jr.",
            LocalDate.of(1990, 2, 2), "john.doe@example.com", "newpassword123",
            com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-9999"
        );

        when(userService.editUser(any(EditUserRequestDTO.class))).thenReturn(null);

        // Act & Assert
        mockMvc.perform(post("/users/edit")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.user_id").value(-1));
    }
}