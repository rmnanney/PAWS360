package com.uwm.paws360.Entity;

import com.uwm.paws360.Entity.Domains.Ferpa_Compliance;
import com.uwm.paws360.Entity.Domains.User.Country_Code;
import com.uwm.paws360.Entity.Domains.User.Role;
import com.uwm.paws360.Entity.Domains.User.Status;
import jakarta.persistence.*;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Entity
public class Users {

/*------------------------- Fields -------------------------*/
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

    @Column(nullable = false, length = 60)
    private String password;

    @ManyToOne
    @JoinColumn(name = "address_id")
    private Address address;

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

    @Column(nullable = false)
    private LocalDate account_updated;

    @Column(nullable = false)
    private LocalDateTime last_login;

    @Column(nullable = false)
    private LocalDate changed_password;

    @Column(nullable = false)
    private int failed_attempts;

    @Column
    private LocalDateTime account_locked;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Ferpa_Compliance ferpa_compliance;

    @Column(length = 255)
    private String session_token;

    @Column
    private LocalDateTime session_expiration;

/*------------------------- Constructors -------------------------*/

    public Users() {}

    public Users(String firstname, String middlename, String lastname, LocalDate dob,
                 String email, String password, Address address, Country_Code countryCode,
                 String phone, Status status, Role role) {
        this.firstname = firstname;
        this.middlename = middlename;
        this.lastname = lastname;
        this.dob = dob;
        this.email = email;
        this.password = password;
        this.address = address;
        this.countryCode = countryCode;
        this.phone = phone;
        this.status = status;
        this.role = role;
    }

/*------------------------- Set Before Entering Into DB -------------------------*/

    @PrePersist
    private void setTimes(){
        account_updated = LocalDate.now();
        last_login = LocalDateTime.now();
        changed_password = LocalDate.now();
    }

/*------------------------- Getters -------------------------*/

    public int getId() {
        return id;
    }

    public String getFirstname() {
        return firstname;
    }

    public String getMiddlename() {
        return middlename;
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

    public String getPassword() {
        return password;
    }

    public Address getAddress() {
        return address;
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

    public Role getRole() {
        return role;
    }

    public LocalDate getDate_created() {
        return date_created;
    }

    public LocalDate getAccount_updated() {
        return account_updated;
    }

    public LocalDateTime getLast_login() {
        return last_login;
    }

    public LocalDate getChanged_password() {
        return changed_password;
    }

    public int getFailed_attempts() {
        return failed_attempts;
    }

    public LocalDateTime getAccount_locked() {
        return account_locked;
    }

    public Ferpa_Compliance getFerpa_compliance() {
        return ferpa_compliance;
    }

    public String getSession_token() {
        return session_token;
    }

    public LocalDateTime getSession_expiration() {
        return session_expiration;
    }

/*------------------------- Setters -------------------------*/

    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    public void setMiddlename(String middlename) {
        this.middlename = middlename;
    }

    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    public void setDob(LocalDate dob) {
        this.dob = dob;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setAddress(Address address) {
        this.address = address;
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

    public void setAccount_updated(LocalDate account_updated) {
        this.account_updated = account_updated;
    }

    public void setLast_login(LocalDateTime last_login) {
        this.last_login = last_login;
    }

    public void setChanged_password(LocalDate changed_password) {
        this.changed_password = changed_password;
    }

    public void setFailed_attempts(int failed_attempts) {
        this.failed_attempts = failed_attempts;
    }

    public void setAccount_locked(LocalDateTime account_locked) {
        this.account_locked = account_locked;
    }

    public void setFerpa_compliance(Ferpa_Compliance ferpa_compliance) {
        this.ferpa_compliance = ferpa_compliance;
    }

    public void setSession_token(String session_token) {
        this.session_token = session_token;
    }

    public void setSession_expiration(LocalDateTime session_expiration) {
        this.session_expiration = session_expiration;
    }
}