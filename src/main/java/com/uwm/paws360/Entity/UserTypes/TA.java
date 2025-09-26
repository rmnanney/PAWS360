package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import jakarta.persistence.*;

@Entity
public class TA {
    @Id
    @Column(nullable = false, unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "user_id")
    private Users user;

    public TA(){}

    public TA(Users user){
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
