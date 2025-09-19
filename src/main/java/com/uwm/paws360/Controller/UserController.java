package com.uwm.paws360.Controller;

import com.uwm.paws360.Repository.UserRepository;
import com.uwm.paws360.Domain.Users;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    private final UserRepository repository;

    public UserController(UserRepository repository){
        this.repository = repository;
    }

    @PostMapping("/users")
    public Users post(
            @RequestBody Users user
    ){
       return repository.save(user);
    }

}
