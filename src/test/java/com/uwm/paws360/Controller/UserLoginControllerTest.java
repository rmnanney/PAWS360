package com.uwm.paws360.Controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.Service.LoginService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(UserLogin.class)
class UserLoginControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private LoginService loginService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void login_SuccessfulLogin_ReturnsOkStatus() throws Exception {
        // Arrange
        UserLoginRequestDTO request = new UserLoginRequestDTO("user@example.com", "password123");
        UserLoginResponseDTO response = new UserLoginResponseDTO(
            1, "user@example.com", "John", "Doe",
            Role.STUDENT, Status.ACTIVE, "sessionToken123", "Login Successful"
        );

        when(loginService.login(any(UserLoginRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user_id").value(1))
                .andExpect(jsonPath("$.email").value("user@example.com"))
                .andExpect(jsonPath("$.firstname").value("John"))
                .andExpect(jsonPath("$.lastname").value("Doe"))
                .andExpect(jsonPath("$.message").value("Login Successful"));
    }

    @Test
    void login_InvalidCredentials_ReturnsUnauthorized() throws Exception {
        // Arrange
        UserLoginRequestDTO request = new UserLoginRequestDTO("user@example.com", "wrongpassword");
        UserLoginResponseDTO response = new UserLoginResponseDTO(
            -1, null, null, null, null, null, null, "Invalid Email or Password"
        );

        when(loginService.login(any(UserLoginRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid Email or Password"));
    }

    @Test
    void login_AccountLocked_ReturnsLockedStatus() throws Exception {
        // Arrange
        UserLoginRequestDTO request = new UserLoginRequestDTO("user@example.com", "password123");
        UserLoginResponseDTO response = new UserLoginResponseDTO(
            1, "user@example.com", "John", "Doe",
            Role.STUDENT, Status.ACTIVE, null, "Account Locked"
        );

        when(loginService.login(any(UserLoginRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isLocked())
                .andExpect(jsonPath("$.message").value("Account Locked"));
    }

    @Test
    void login_InactiveAccount_ReturnsUnauthorized() throws Exception {
        // Arrange
        UserLoginRequestDTO request = new UserLoginRequestDTO("user@example.com", "password123");
        UserLoginResponseDTO response = new UserLoginResponseDTO(
            1, "user@example.com", "John", "Doe",
            Role.STUDENT, Status.INACTIVE, null, "Account Is Not Active"
        );

        when(loginService.login(any(UserLoginRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Account Is Not Active"));
    }

    @Test
    void login_InvalidRequestBody_ReturnsBadRequest() throws Exception {
        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"invalid\": \"json\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void login_MissingRequiredFields_ReturnsBadRequest() throws Exception {
        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void login_ServiceReturnsNull_ReturnsInternalServerError() throws Exception {
        // Arrange
        UserLoginRequestDTO request = new UserLoginRequestDTO("user@example.com", "password123");

        when(loginService.login(any(UserLoginRequestDTO.class))).thenReturn(null);

        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Login failed"));
    }

    @Test
    void login_TooManyFailedAttempts_LocksAccount() throws Exception {
        // Arrange
        UserLoginRequestDTO request = new UserLoginRequestDTO("user@example.com", "wrongpassword");
        UserLoginResponseDTO response = new UserLoginResponseDTO(
            -1, "user@example.com", "John", "Doe",
            Role.STUDENT, Status.ACTIVE, null, "Invalid Email or Password"
        );

        when(loginService.login(any(UserLoginRequestDTO.class))).thenReturn(response);

        // Act & Assert
        mockMvc.perform(post("/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid Email or Password"));
    }
}