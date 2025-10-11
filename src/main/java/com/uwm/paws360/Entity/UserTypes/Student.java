package com.uwm.paws360.Entity.UserTypes;

import com.uwm.paws360.Entity.Base.Users;
import jakarta.persistence.*;

@Entity
public class Student {

    @Id
    @Column(name = "student_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne(
            cascade = CascadeType.ALL
    )
    @JoinColumn(name = "user_id")
    private Users user;

    public Student(Users user) {
        this.user = user;
    }

    public Student(){}

    public int getId() {
        return id;
    }

    public Users getUser() {
        return user;
    }

    public void setUser(Users user) {
        this.user = user;
    }
}
