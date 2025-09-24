package com.uwm.paws360.Entity;

import com.uwm.paws360.Entity.Domains.User.Country_Code;
import com.uwm.paws360.Entity.Domains.User.Role;
import com.uwm.paws360.Entity.Domains.User.Status;
import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Entity
public class Users {

    @Id
    @Column(name = "user_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @Column(nullable = false, length = 100)
    private String firstname;

    @Column(length = 100)
    private String middlename;

    @Column(nullable = false, length = 30)
    private String lastname;

    @Column(nullable = false, updatable = false)
    private LocalDate dob;

    @Column(nullable = false, length = 50, unique = true)
    private String email;

    @Column
    @Enumerated(EnumType.STRING)
    private Country_Code countryCode;

    @Column(length = 10)
    private String phone;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Status status;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Role role;

    @Column(nullable = false, updatable = false)
    private final LocalDate date_created = LocalDate.parse(LocalDate.now().format(DateTimeFormatter.ISO_DATE));


/*------------------------------------------------------- Getters -------------------------------------------------------*/

    public int getId() {
        return id;
    }

    public String getFirstname() {
        return firstname;
    }

    public String getLastname() {
        return lastname;
    }

    public LocalDate getDob() {
        return dob;
    }

    public String getEmail() {
        return email;
    }

    public Country_Code getCountryCode() {
        return countryCode;
    }

    public String getPhone() {
        return phone;
    }

    public Status getStatus() {
        return status;
    }

    public LocalDate getDate_created() {
        return date_created;
    }

    public Role getRoles() {
        return role;
    }

    /*------------------------------------------------------- Setters -------------------------------------------------------*/

    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    public void setDob(LocalDate dob) {
        this.dob = dob;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setCountryCode(Country_Code countryCode) {
        this.countryCode = countryCode;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public void setRole(Role role) {
        this.role = role;
    }
}