package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.Basic.CreateUserDTO;
import com.uwm.paws360.DTO.Basic.UserResponseDTO;
import com.uwm.paws360.Service.UserService;
import org.springframework.web.bind.annotation.*;

@RestController()
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService){
        this.userService = userService;
    }

    @PostMapping("/create")
    public UserResponseDTO createUser(@RequestBody CreateUserDTO userDTO){
       return userService.createUser(userDTO);
    }

}
