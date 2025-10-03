package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import jakarta.persistence.*;
import org.springframework.data.relational.core.sql.In;

@Entity
public class Instructor {

    @Id
    @Column(name = "instructor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "user_id")
    private Users user;

    public Instructor(){}

    public Instructor(Users user){
        this.user = user;
    }

    public int getId() {
        return id;
    }

    public Users getUser(){
        return this.user;
    }

    public void setUser(Users user) {
        this.user = user;
    }
}
