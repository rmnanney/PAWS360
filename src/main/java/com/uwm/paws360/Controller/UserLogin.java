package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Service.LoginService;
import jakarta.validation.Valid;
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
    public ResponseEntity<UserLoginResponseDTO> login(@Valid @RequestBody UserLoginRequestDTO loginDTO){
        UserLoginResponseDTO response = loginService.login(loginDTO);
        if (response == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new UserLoginResponseDTO(-1, null, null, null, null, null, null, null, "Login failed"));
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
