package com.uwm.paws360.Controller;

import com.uwm.paws360.JPARepository.UserRepository;
import com.uwm.paws360.Entity.Users;
import com.uwm.paws360.Service.UserService;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController()
@RequestMapping("/users")
public class UserController {

    private final UserRepository repository;
    private final UserService userService;

    public UserController(UserRepository repository, UserService userService){
        this.repository = repository;
        this.userService = userService;
    }

    @GetMapping("users/search/{user-id}")
    public Users findUserById(@PathVariable("user-id") Integer id){
        return repository.findById(id).orElse(null);
    }

    @GetMapping("users/search/all")
    public List<Users> findAllUsers(){
        return repository.findAll();
    }

    @GetMapping("users/search/{user-name}")
    public List<Users> findUsersByName(@PathVariable("user-name") String name){
        return repository.findAllByFirstnameLike(name);
    }

    @GetMapping("users/search/{user-email}")
    public Users findUsersByEmail(@PathVariable("user-email") String email){
        return repository.findUsersByEmailLikeIgnoreCase(email);
    }

    @PostMapping("/create")
    public Users createUser(@RequestBody Users user){
       return userService.createUser(user);
    }

    @DeleteMapping("users/{user-id}")
    public void deleteUser(@PathVariable("user-id") Users user){
        repository.delete(user);
    }



}
