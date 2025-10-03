package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.User.CreateUserDTO;
import com.uwm.paws360.DTO.User.DeleteUserRequestDTO;
import com.uwm.paws360.DTO.User.EditUserRequestDTO;
import com.uwm.paws360.DTO.User.UserResponseDTO;
import com.uwm.paws360.Service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController()
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/create")
    public UserResponseDTO createUser(@RequestBody CreateUserDTO userDTO) {
        return userService.createUser(userDTO);
    }

    @PostMapping("/edit")
    public ResponseEntity<UserResponseDTO> editUser(@RequestBody EditUserRequestDTO userDTO) {
        UserResponseDTO response = userService.editUser(userDTO);
        if (response.user_id() == -1) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @PostMapping("/delete")
    public ResponseEntity<String> deleteUser(@RequestBody DeleteUserRequestDTO deleteUserRequestDTO) {
        boolean isDeleted = userService.deleteUser(deleteUserRequestDTO);
        if (isDeleted) return ResponseEntity.status(HttpStatus.OK).body("User deleted successfully");
        else return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("User deletion failed");
    }
}
