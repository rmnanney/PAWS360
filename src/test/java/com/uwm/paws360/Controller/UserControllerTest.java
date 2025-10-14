package com.uwm.paws360.Controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uwm.paws360.DTO.User.AddressDTO;
import com.uwm.paws360.DTO.User.CreateUserDTO;
import com.uwm.paws360.DTO.User.EditUserRequestDTO;
import com.uwm.paws360.DTO.User.UserResponseDTO;
import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
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

    private List<AddressDTO> sampleAddressList() {
        AddressDTO addr = new AddressDTO(
                1,
                Address_Type.HOME,
                "123 Main St",
                null,
                null,
                "Milwaukee",
                US_States.WISCONSIN,
                "53201"
        );
        return List.of(addr);
    }

    @Test
    void createUser_ValidRequest_ReturnsCreatedUser() throws Exception {
        CreateUserDTO request = new CreateUserDTO(
                "John", "Middle", "Doe", LocalDate.of(1990, 1, 1),
                "john.doe@example.com", "password123", sampleAddressList(),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0123", Status.ACTIVE, Role.STUDENT
        );

        UserResponseDTO response = new UserResponseDTO(
                1, "john.doe@example.com", "John", "Doe",
                Role.STUDENT, Status.ACTIVE, LocalDate.of(1990, 1, 1),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0123", sampleAddressList()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        mockMvc.perform(post("/users/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.email").value("john.doe@example.com"))
                .andExpect(jsonPath("$.firstname").value("John"))
                .andExpect(jsonPath("$.lastname").value("Doe"))
                .andExpect(jsonPath("$.role").value("STUDENT"))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.addresses[0].street_address_1").value("123 Main St"));
    }

    @Test
    void createUser_InvalidRequest_ReturnsBadRequest() throws Exception {
        String invalidRequest = "{}";

        mockMvc.perform(post("/users/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidRequest))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createUser_ProfessorRole_CreatesProfessor() throws Exception {
        CreateUserDTO request = new CreateUserDTO(
                "Dr.", "Smith", "Johnson", LocalDate.of(1975, 3, 20),
                "dr.johnson@example.com", "password123", sampleAddressList(),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0789", Status.ACTIVE, Role.PROFESSOR
        );

        UserResponseDTO response = new UserResponseDTO(
                2, "dr.johnson@example.com", "Dr.", "Johnson",
                Role.PROFESSOR, Status.ACTIVE, LocalDate.of(1975, 3, 20),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0789", sampleAddressList()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        mockMvc.perform(post("/users/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("PROFESSOR"));
    }

    @Test
    void createUser_InstructorRole_CreatesInstructor() throws Exception {
        CreateUserDTO request = new CreateUserDTO(
                "Prof", "Instructor", "Davis", LocalDate.of(1978, 7, 12),
                "prof.davis@example.com", "password123", sampleAddressList(),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0987", Status.ACTIVE, Role.INSTRUCTOR
        );

        UserResponseDTO response = new UserResponseDTO(
                6, "prof.davis@example.com", "Prof", "Davis",
                Role.INSTRUCTOR, Status.ACTIVE, LocalDate.of(1978, 7, 12),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0987", sampleAddressList()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        mockMvc.perform(post("/users/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("INSTRUCTOR"));
    }

    @Test
    void createUser_FacultyRole_CreatesFaculty() throws Exception {
        CreateUserDTO request = new CreateUserDTO(
                "Dr", "Faculty", "Wilson", LocalDate.of(1970, 1, 5),
                "dr.wilson@example.com", "password123", sampleAddressList(),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0147", Status.ACTIVE, Role.FACULTY
        );

        UserResponseDTO response = new UserResponseDTO(
                7, "dr.wilson@example.com", "Dr", "Wilson",
                Role.FACULTY, Status.ACTIVE, LocalDate.of(1970, 1, 5),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0147", sampleAddressList()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        mockMvc.perform(post("/users/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("FACULTY"));
    }

    @Test
    void createUser_TARole_CreatesTA() throws Exception {
        CreateUserDTO request = new CreateUserDTO(
                "Alex", "TA", "Brown", LocalDate.of(1995, 9, 18),
                "alex.brown@example.com", "password123", sampleAddressList(),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0258", Status.ACTIVE, Role.TA
        );

        UserResponseDTO response = new UserResponseDTO(
                8, "alex.brown@example.com", "Alex", "Brown",
                Role.TA, Status.ACTIVE, LocalDate.of(1995, 9, 18),
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-0258", sampleAddressList()
        );

        when(userService.createUser(any(CreateUserDTO.class))).thenReturn(response);

        mockMvc.perform(post("/users/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role").value("TA"));
    }

    @Test
    void editUser_NullRequestBody_ReturnsBadRequest() throws Exception {
        mockMvc.perform(post("/users/edit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void editUser_UserNotFound_ReturnsBadRequest() throws Exception {
        EditUserRequestDTO request = new EditUserRequestDTO(
                "Johnny", "Mid", "Doe Jr.",
                LocalDate.of(1990, 2, 2), "john.doe@example.com", "newpassword123",
                com.uwm.paws360.Entity.EntityDomains.User.Country_Code.US, "555-9999"
        );

        UserResponseDTO notFound = new UserResponseDTO(-1, null, null, null, null, null, null, null, null, List.of());
        when(userService.editUser(any(EditUserRequestDTO.class))).thenReturn(notFound);

        mockMvc.perform(post("/users/edit")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.user_id").value(-1));
    }
}

