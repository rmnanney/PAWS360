package com.uwm.paws360.Service;

import com.uwm.paws360.DTO.Login.UserLoginRequestDTO;
import com.uwm.paws360.DTO.Login.UserLoginResponseDTO;
import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import com.uwm.paws360.JPARepository.User.UserRepository;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;

@Service
public class LoginService {

    private final UserRepository userRepository;
    private final int TOKEN = 32;
    private final String ALPHANUMERIC = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890";

    public LoginService(UserRepository userRepository){
        this.userRepository = userRepository;
    }

    public UserLoginResponseDTO login(UserLoginRequestDTO userLogin){
        Users user = userRepository.findUsersByEmailLikeIgnoreCase(userLogin.email());
        if (user == null) return new UserLoginResponseDTO(-1, null, null, null,
                null, null, null,"Invalid Email or Password");
        if(user.isAccount_locked()) return new UserLoginResponseDTO(user.getId(), user.getEmail(),
                user.getFirstname(), user.getLastname(), user.getRole(), user.getStatus(), null, "Account Locked");
        if(!user.getStatus().equals(Status.ACTIVE)) return new UserLoginResponseDTO(user.getId(), user.getEmail(),
                user.getFirstname(), user.getLastname(), user.getRole(), user.getStatus(), null,"Account Is Not Active");
        if(!user.getPassword().equals(userLogin.password())){
            user.setFailed_attempts(user.getFailed_attempts() + 1);
            if(user.getFailed_attempts() >= 5) user.setAccount_locked(true);
            userRepository.save(user);
        }
        user.setFailed_attempts(0);
        user.setSession_token(generateAuthenticationToken());
        userRepository.save(user);
        return new UserLoginResponseDTO(
                user.getId(),
                user.getEmail(),
                user.getFirstname(),
                user.getLastname(),
                user.getRole(),
                user.getStatus(),
                user.getSession_token(),
                "Login Successful"
        );
    }

    private String generateAuthenticationToken(){
        SecureRandom secureRandom = new SecureRandom();
        StringBuilder tokenBuilder = new StringBuilder(TOKEN);
        for(int i = 0; i < TOKEN; i++){
            int randomIndex = secureRandom.nextInt(ALPHANUMERIC.length());
            tokenBuilder.append(ALPHANUMERIC.charAt(randomIndex));
        }
        return tokenBuilder.toString();
    }

}
