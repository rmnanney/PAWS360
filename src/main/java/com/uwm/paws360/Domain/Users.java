package com.uwm.paws360.Domain;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Entity
public class Users {
    @Id
    @Column(name = "user_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;
    @Column(nullable = false, length = 20)
    private String firstname;
    @Column(nullable = false, length = 30)
    private String lastname;
    @Column(nullable = false, length = 50, unique = true)
    private String email;
    @Column(nullable = false, updatable = false)
    private LocalDate dob;
    @Column(nullable = false, updatable = false)
    private final LocalDate date_created = LocalDate.parse(LocalDate.now().format(DateTimeFormatter.ISO_DATE));

    public Users(String firstname, String lastname, String email, LocalDate dob) throws Exception {
        setF_name(firstname);
        setL_name(lastname);
        setEmail(email);
        setDob(dob);
    }

    public Users() {}

    public String getF_name() {
        return firstname;
    }

    public void setF_name(String firstname) {
        this.firstname = firstname;
    }

    public String getL_name() {
        return lastname;
    }

    public void setL_name(String lastname) {
        this.lastname = lastname;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) throws Exception {
        if(!email.contains("@uwm.edu")) throw new Exception("Must be a UWM@EDU Email");
        this.email = email;
    }

    public LocalDate getDob() {
        return dob;
    }

    public void setDob(LocalDate dob) {
        this.dob = dob;
    }
}