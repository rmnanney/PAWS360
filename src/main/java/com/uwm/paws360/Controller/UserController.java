package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.User.*;
import com.uwm.paws360.Service.UserService;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController()
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/create")
    public UserResponseDTO createUser(@Valid @RequestBody CreateUserDTO userDTO) {
        return userService.createUser(userDTO);
    }

    @PostMapping("/edit")
    public ResponseEntity<UserResponseDTO> editUser(@Valid @RequestBody EditUserRequestDTO userDTO) {
        UserResponseDTO response = userService.editUser(userDTO);
        if (response == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null));
        }
        if (response.user_id() == -1) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }

    @PostMapping("/delete")
    public ResponseEntity<String> deleteUser(@Valid @RequestBody DeleteUserRequestDTO deleteUserRequestDTO) {
        boolean isDeleted = userService.deleteUser(deleteUserRequestDTO);
        if (isDeleted)
            return ResponseEntity.status(HttpStatus.OK).body("User deleted successfully");
        else
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("User deletion failed");
    }

    // Address endpoints
    @PostMapping("/addresses/add")
    public ResponseEntity<UserResponseDTO> addAddress(@Valid @RequestBody AddAddressRequestDTO dto) {
        UserResponseDTO res = userService.addAddress(dto);
        if (res.user_id() == -1)
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(res);
        return ResponseEntity.ok(res);
    }

    @PostMapping("/addresses/edit")
    public ResponseEntity<UserResponseDTO> editAddress(@Valid @RequestBody EditAddressRequestDTO dto) {
        UserResponseDTO res = userService.editAddress(dto);
        if (res.user_id() == -1)
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(res);
        return ResponseEntity.ok(res);
    }

    @PostMapping("/addresses/delete")
    public ResponseEntity<String> deleteAddress(@Valid @RequestBody DeleteAddressRequestDTO dto) {
        boolean ok = userService.deleteAddress(dto);
        if (ok)
            return ResponseEntity.ok("Address deleted successfully");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Address deletion failed");
    }

    @PostMapping("/addresses/list")
    public List<AddressDTO> listAddresses(@Valid @RequestBody ListAddressesRequestDTO dto) {
        return userService.listAddresses(dto);
    }

    // Role endpoints
    @PostMapping("/roles/assign")
    public ResponseEntity<String> assignRole(@Valid @RequestBody ModifyRoleRequestDTO dto) {
        boolean ok = userService.assignRole(dto);
        if (ok)
            return ResponseEntity.ok("Role assigned successfully");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Role assignment failed");
    }

    @PostMapping("/roles/remove")
    public ResponseEntity<String> removeRole(@Valid @RequestBody ModifyRoleRequestDTO dto) {
        boolean ok = userService.removeRole(dto);
        if (ok)
            return ResponseEntity.ok("Role removed successfully");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Role removal failed");
    }

    @PostMapping("/roles/list")
    public List<Role> listRoles(@Valid @RequestBody ListRolesRequestDTO dto) {
        return userService.listRoles(dto);
    }

    @PostMapping("/get")
    public ResponseEntity<UserResponseDTO> getUser(@Valid @RequestBody GetUserRequestDTO dto) {
        UserResponseDTO res = userService.getUser(dto);
        if (res.user_id() == -1)
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(res);
        return ResponseEntity.ok(res);
    }

    @GetMapping("/get")
    public ResponseEntity<UserResponseDTO> getUserByQuery(@RequestParam("email") String email) {
        UserResponseDTO res = userService.getUser(new GetUserRequestDTO(email));
        if (res.user_id() == -1)
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(res);
        return ResponseEntity.ok(res);
    }
}
