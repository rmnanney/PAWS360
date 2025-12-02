package com.uwm.paws360.Entity.Base;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.uwm.paws360.Entity.EntityDomains.Ferpa_Compliance;
import com.uwm.paws360.Entity.EntityDomains.User.*;
import jakarta.persistence.*;
import jakarta.validation.constraints.Pattern;

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
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @Column(nullable = false, length = 100)
    private String firstname;

    @Column(length = 100)
    private String middlename;

    @Column(nullable = false, length = 30)
    private String lastname;

    @Column(nullable = false)
    private LocalDate dob;

    @Column(nullable = false, unique = true, length = 9)
    @Pattern(regexp = "\\d{9}", message = "SSN must be exactly 9 digits")
    private String ssn;

    @Column
    @Enumerated(EnumType.STRING)
    private Ethnicity ethnicity;

    @Column
    @Enumerated(EnumType.STRING)
    private Gender gender;

    @Column
    @Enumerated(EnumType.STRING)
    private Nationality nationality;

    @Column(nullable = false, length = 50, unique = true)
    private String email;

    @Column(length = 50)
    private String alternateEmail;

    @Column(nullable = false, length = 120)
    @JsonIgnore
    private String password;

    @Column(length = 100)
    private String preferred_name;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Address> addresses = new ArrayList<>();

    @Column
    @Enumerated(EnumType.STRING)
    private Country_Code countryCode;

    @Column(length = 10)
    private String phone;

    @Column(length = 20)
    private String alternatePhone;

    @Column(length = 255)
    private String profilePictureUrl;

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

    @Column(nullable = false)
    private boolean contact_by_phone;

    @Column(nullable = false)
    private boolean contact_by_email;

    @Column(nullable = false)
    private boolean contact_by_mail;

    @Column(nullable = false)
    private boolean ferpa_directory_opt_in;

    @Column(nullable = false)
    private boolean photo_release_opt_in;

    @Column(length = 255)
    @JsonIgnore
    private String session_token;

    @Column
    private LocalDateTime session_expiration;

/*------------------------- Constructors -------------------------*/

    public Users() {}

    public Users(String firstname, String middlename, String lastname, LocalDate dob,
                 String email, String password, Country_Code countryCode,
                 String phone, Status status, Role role, String ssn,
                 Ethnicity ethnicity, Nationality nationality, Gender gender) {
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
        this.ssn = ssn;
        this.ethnicity = ethnicity;
        this.nationality = nationality;
        this.gender = gender;
    }

/*------------------------- Set Before Entering Into DB -------------------------*/

    @PrePersist
    private void setData(){
        account_updated = LocalDate.now();
        last_login = LocalDateTime.now();
        changed_password = LocalDate.now();
        ferpa_compliance = Ferpa_Compliance.RESTRICTED;
        account_locked = false;
        contact_by_phone = true;
        contact_by_email = true;
        contact_by_mail = false;
        ferpa_directory_opt_in = false;
        photo_release_opt_in = false;
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

    public String getAlternateEmail() { return alternateEmail; }

    public String getPassword() {
        return password;
    }

    public String getPreferred_name() { return preferred_name; }

    // Address list handled via getAddresses()

    public Country_Code getCountryCode() {
        return countryCode;
    }

    public String getPhone() {
        return phone;
    }

    public String getAlternatePhone() { return alternatePhone; }

    public String getProfilePictureUrl() { return profilePictureUrl; }

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

    public boolean isContact_by_phone() { return contact_by_phone; }
    public boolean isContact_by_email() { return contact_by_email; }
    public boolean isContact_by_mail() { return contact_by_mail; }
    public boolean isFerpa_directory_opt_in() { return ferpa_directory_opt_in; }
    public boolean isPhoto_release_opt_in() { return photo_release_opt_in; }

    public String getSession_token() {
        return session_token;
    }

    public LocalDateTime getSession_expiration() {
        return session_expiration;
    }

    public String getSocialsecurity() {
        return ssn;
    }

    public Ethnicity getEthnicity() {
        return ethnicity;
    }

    public Gender getGender() {
        return gender;
    }

    public Nationality getNationality() {
        return nationality;
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

    public void setAlternateEmail(String alternateEmail) { this.alternateEmail = alternateEmail; }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setPreferred_name(String preferred_name) { this.preferred_name = preferred_name; }

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

    public void setAlternatePhone(String alternatePhone) { this.alternatePhone = alternatePhone; }

    public void setProfilePictureUrl(String profilePictureUrl) { this.profilePictureUrl = profilePictureUrl; }

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

    public void setContact_by_phone(boolean contact_by_phone) { this.contact_by_phone = contact_by_phone; }
    public void setContact_by_email(boolean contact_by_email) { this.contact_by_email = contact_by_email; }
    public void setContact_by_mail(boolean contact_by_mail) { this.contact_by_mail = contact_by_mail; }
    public void setFerpa_directory_opt_in(boolean ferpa_directory_opt_in) { this.ferpa_directory_opt_in = ferpa_directory_opt_in; }
    public void setPhoto_release_opt_in(boolean photo_release_opt_in) { this.photo_release_opt_in = photo_release_opt_in; }

    public void setSession_token(String session_token) {
        this.session_token = session_token;
    }

    // Backwards-compatible camelCase accessors used by Spring Data derived query names
    // eg. findBySessionToken -> matches getSessionToken()
    public String getSessionToken() {
        return this.session_token;
    }

    public void setSessionToken(String sessionToken) {
        this.session_token = sessionToken;
    }

    public void setSession_expiration(LocalDateTime session_expiration) {
        this.session_expiration = session_expiration;
    }

    public void setSocialsecurity(String socialsecurity) {
        this.ssn = socialsecurity;
    }

    public void setEthnicity(Ethnicity ethnicity) {
        this.ethnicity = ethnicity;
    }

    public void setGender(Gender gender) {
        this.gender = gender;
    }

    public void setNationality(Nationality nationality) {
        this.nationality = nationality;
    }
}
