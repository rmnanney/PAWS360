package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Service.LoginService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController()
@RequestMapping()
public class UserLogin {

    private final LoginService loginService;

    public UserLogin(LoginService loginService){
        this.loginService = loginService;
    }

    @PostMapping("/login")
    public ResponseEntity<UserLoginResponseDTO> login(@RequestBody UserLoginRequestDTO loginDTO){
        if(loginDTO == null || loginDTO.email() == null || loginDTO.password() == null) {
            UserLoginResponseDTO errorResponse = new UserLoginResponseDTO(-1, null, null, null, null, null, null, "Invalid request body");
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        }
        UserLoginResponseDTO response = loginService.login(loginDTO);
        if(response == null) {
            UserLoginResponseDTO errorResponse = new UserLoginResponseDTO(-1, null, null, null, null, null, null, "Login failed");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
        if(response.message().equals("Login Successful")){
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
        if(response.message().contains("Locked")){
            return ResponseEntity.status(HttpStatus.LOCKED).body(response);
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
    }

}
