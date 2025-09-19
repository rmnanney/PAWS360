package com.uwm.paws360.Domain;

import jakarta.persistence.*;

import java.util.Date;

@Entity
public class Users {
    @Id
    @Column(name = "user_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;
    private String name;
    private String last;
    @Column(length = 40, unique = true)
    private String email;
    @Column(updatable = false, nullable = false)
    private final Date created_date = new Date();

    public Users(String name, String last, String email) {
        this.name = name;
        this.last = last;
        this.email = email;
    }

    public Users() {}

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getLast() {
        return last;
    }

    public void setLast(String last) {
        this.last = last;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}