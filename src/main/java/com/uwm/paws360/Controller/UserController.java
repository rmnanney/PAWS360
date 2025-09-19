package com.uwm.paws360.Controller;

import com.uwm.paws360.JPARepository.UserRepository;
import com.uwm.paws360.Domain.Users;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController()
public class UserController {

    private final UserRepository repository;

    public UserController(UserRepository repository){
        this.repository = repository;
    }

    @PostMapping("/create_user")
    public Users createUser(
            @RequestBody Users user
    ){
       return repository.save(user);
    }

    @GetMapping("users/{user-id}")
    public Users findUserById(@PathVariable("user-id") Integer id){
        return repository.findById(id).orElse(null);
    }

    @GetMapping("users/search-all")
    public List<Users> findAllUsers(){
        return repository.findAll();
    }

    @GetMapping("users/search/{user-name}")
    public List<Users> findUsersByName(@PathVariable("user-name") String name){
        return repository.findAllByFirstnameLike(name);
    }

}
