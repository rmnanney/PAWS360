package com.uwm.paws360.Entity.Base;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import jakarta.persistence.*;

@Entity
public class EmergencyContact {

    @Id
    @GeneratedValue
    @Column(name = "emergency_contact_id", unique = true, updatable = false, nullable = false)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private Users user;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 50)
    private String relationship;

    @Column(length = 100)
    private String email;

    @Column(length = 20)
    private String phone;

    @Column(length = 120)
    private String street_address_1;

    @Column(length = 120)
    private String street_address_2;

    @Column(length = 60)
    private String city;

    @Enumerated(EnumType.STRING)
    @Column(name = "state")
    private US_States us_state;

    @Column(length = 10)
    private String zipcode;

    public EmergencyContact() {}

    public EmergencyContact(Users user, String name, String relationship, String email, String phone,
                            String street_address_1, String street_address_2, String city, US_States us_state, String zipcode) {
        this.user = user;
        this.name = name;
        this.relationship = relationship;
        this.email = email;
        this.phone = phone;
        this.street_address_1 = street_address_1;
        this.street_address_2 = street_address_2;
        this.city = city;
        this.us_state = us_state;
        this.zipcode = zipcode;
    }

    public int getId() { return id; }
    public Users getUser() { return user; }
    public String getName() { return name; }
    public String getRelationship() { return relationship; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getStreet_address_1() { return street_address_1; }
    public String getStreet_address_2() { return street_address_2; }
    public String getCity() { return city; }
    public US_States getUs_state() { return us_state; }
    public String getZipcode() { return zipcode; }

    public void setUser(Users user) { this.user = user; }
    public void setName(String name) { this.name = name; }
    public void setRelationship(String relationship) { this.relationship = relationship; }
    public void setEmail(String email) { this.email = email; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setStreet_address_1(String street_address_1) { this.street_address_1 = street_address_1; }
    public void setStreet_address_2(String street_address_2) { this.street_address_2 = street_address_2; }
    public void setCity(String city) { this.city = city; }
    public void setUs_state(US_States us_state) { this.us_state = us_state; }
    public void setZipcode(String zipcode) { this.zipcode = zipcode; }
}

