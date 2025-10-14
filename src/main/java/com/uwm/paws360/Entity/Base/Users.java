package com.uwm.paws360.Entity.Base;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import com.uwm.paws360.Entity.EntityDomains.User.Country_Code;
import com.uwm.paws360.Entity.EntityDomains.User.Role;
import com.uwm.paws360.Entity.EntityDomains.User.Status;
import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

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

    @Column(nullable = false, length = 120)
    @JsonIgnore
    private String password;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Address> addresses = new ArrayList<>();

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

    @Column(nullable = false)
    private boolean account_locked;

    @Column
    private LocalDateTime account_locked_duration;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Ferpa_Compliance ferpa_compliance;

    @Column(length = 255)
    @JsonIgnore
    private String session_token;

    @Column
    private LocalDateTime session_expiration;

/*------------------------- Constructors -------------------------*/

    public Users() {}

    public Users(String firstname, String middlename, String lastname, LocalDate dob,
                 String email, String password, Country_Code countryCode,
                 String phone, Status status, Role role) {
        this.firstname = firstname;
        this.middlename = middlename;
        this.lastname = lastname;
        this.dob = dob;
        this.email = email;
        this.password = password;
        this.countryCode = countryCode;
        this.phone = phone;
        this.status = status;
        this.role = role;
    }

/*------------------------- Set Before Entering Into DB -------------------------*/

    @PrePersist
    private void setData(){
        account_updated = LocalDate.now();
        last_login = LocalDateTime.now();
        changed_password = LocalDate.now();
        ferpa_compliance = Ferpa_Compliance.RESTRICTED;
        account_locked = false;
        if (addresses != null) {
            for (Address addr : addresses) {
                if (addr != null) {
                    addr.setUser(this);
                    if (addr.getFirstname() == null) addr.setFirstname(this.firstname);
                    if (addr.getLastname() == null) addr.setLastname(this.lastname);
                }
            }
        }
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

    // Address list handled via getAddresses()

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

    public boolean isAccount_locked() {
        return account_locked;
    }

    public LocalDateTime getAccount_locked_duration() {
        return account_locked_duration;
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

    public List<Address> getAddresses() {
        return addresses;
    }

    public void setAddresses(List<Address> addresses) {
        this.addresses = addresses;
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

    public void setAccount_locked(boolean account_locked) {
        this.account_locked = account_locked;
    }

    public void setAccount_locked_duration(LocalDateTime account_locked_duration) {
        this.account_locked_duration = account_locked_duration;
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
