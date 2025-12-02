package com.uwm.paws360.Controller;

import com.uwm.paws360.DTO.User.*;
import com.uwm.paws360.Service.UserService;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.MediaType;

import java.util.List;

@RestController()
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping(value = "/profile-picture", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UploadProfilePictureResponseDTO> uploadProfilePicture(
            @RequestParam("email") String email,
            @RequestPart("file") MultipartFile file
    ) {
        try {
            String url = userService.uploadProfilePicture(email, file);
            if (url == null) return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            return ResponseEntity.ok(new UploadProfilePictureResponseDTO(url));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new UploadProfilePictureResponseDTO(null));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new UploadProfilePictureResponseDTO(null));
        }
    }

    @PostMapping("/create")
    public UserResponseDTO createUser(@Valid @RequestBody CreateUserDTO userDTO) {
        return userService.createUser(userDTO);
    }

    @PostMapping("/edit")
    public ResponseEntity<UserResponseDTO> editUser(@Valid @RequestBody EditUserRequestDTO userDTO) {
        UserResponseDTO response = userService.editUser(userDTO);
        if (response == null) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new UserResponseDTO(-1, null, null, null, null, null, null, null, null, null, null, null, null, List.of()));
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

    // Resolve Student.id by email for enrollment automation
    @GetMapping("/student-id")
    public ResponseEntity<GetStudentIdResponseDTO> getStudentIdByEmail(@RequestParam("email") String email) {
        int sid = userService.getStudentIdByEmail(email);
        GetStudentIdResponseDTO body = new GetStudentIdResponseDTO(sid, email);
        if (sid == -1) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
        }
        return ResponseEntity.ok(body);
    }

    // Preferences and privacy
    @GetMapping("/preferences")
    public ResponseEntity<UserPreferencesResponseDTO> getPreferences(@RequestParam("email") String email){
        return ResponseEntity.ok(userService.getPreferences(email));
    }

    @PostMapping("/preferences")
    public ResponseEntity<UserPreferencesResponseDTO> updatePreferences(@Valid @RequestBody UpdatePrivacyRequestDTO dto){
        return ResponseEntity.ok(userService.updatePreferences(dto));
    }

    // Contact info (phone)
    @PostMapping("/contact")
    public ResponseEntity<String> updateContact(@Valid @RequestBody UpdateContactInfoRequestDTO dto){
        boolean ok = userService.updateContactInfo(dto);
        return ok ? ResponseEntity.ok("Updated") : ResponseEntity.status(HttpStatus.BAD_REQUEST).body("User not found");
    }

    // Personal details (subset update)
    @PostMapping("/personal")
    public ResponseEntity<UserResponseDTO> updatePersonal(@Valid @RequestBody UpdatePersonalDetailsRequestDTO dto){
        UserResponseDTO res = userService.updatePersonalDetails(dto);
        if (res.user_id() == -1) return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(res);
        return ResponseEntity.ok(res);
    }

    // SSN last 4 only
    @GetMapping("/ssn-last4")
    public ResponseEntity<SsnLast4ResponseDTO> getSsnLast4(@RequestParam("email") String email){
        return ResponseEntity.ok(userService.getSsnLast4(email));
    }

    // Emergency contacts
    @GetMapping("/emergency-contacts")
    public ResponseEntity<List<EmergencyContactDTO>> emergencyContacts(@RequestParam("email") String email){
        return ResponseEntity.ok(userService.listEmergencyContacts(email));
    }

    @PostMapping("/emergency-contacts")
    public ResponseEntity<EmergencyContactDTO> upsertEmergency(@Valid @RequestBody UpsertEmergencyContactRequestDTO dto){
        EmergencyContactDTO res = userService.upsertEmergencyContact(dto);
        if (res == null) return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        return ResponseEntity.ok(res);
    }

    @PostMapping("/emergency-contacts/delete")
    public ResponseEntity<String> deleteEmergency(@Valid @RequestBody DeleteEmergencyContactRequestDTO dto){
        boolean ok = userService.deleteEmergencyContact(dto);
        return ok ? ResponseEntity.ok("Deleted") : ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Not found");
    }
}
