package com.uwm.paws360.DTO.Login;

import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import java.time.LocalDateTime;

public record UserLoginResponseDTO(
        int user_id,
        String email,
        String firstname,
        String lastname,
        Role role,
        Status status,
        String session_token,
        LocalDateTime session_expiration,
        String message
) {
}
