package com.uwm.paws360.Entity.Base;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.uwm.paws360.Entity.EntityDomains.User.Address_Type;
import com.uwm.paws360.Entity.EntityDomains.User.US_States;
import jakarta.persistence.*;

@Entity
public class Address {

/*------------------------- Fields -------------------------*/

    @Id
    @Column(name = "address_id", unique = true, updatable = false, nullable = false)
    @GeneratedValue
    private int id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private Users user;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Address_Type address_type;

    @Column(nullable = false)
    private String firstname;

    @Column(nullable = false)
    private String lastname;

    @Column(nullable = false)
    private String street_address_1;

    @Column
    private String street_address_2;

    @Column
    private String po_box;

    @Column(nullable = false)
    private String city;

    @Column(nullable = false, name = "state")
    @Enumerated(EnumType.STRING)
    private US_States us_state;

    @Column(nullable = false, length = 6)
    private String zipcode;

/*------------------------- Constructors -------------------------*/

    public Address() {
    }

    public Address(Users user, Address_Type address_type, String firstname, String lastname,
                   String street_address_1, String street_address_2, String po_box,
                   String city, US_States us_state, String zipcode) {
        this.user = user;
        this.address_type = address_type;
        this.firstname = firstname;
        this.lastname = lastname;
        this.street_address_1 = street_address_1;
        this.street_address_2 = street_address_2;
        this.po_box = po_box;
        this.city = city;
        this.us_state = us_state;
        this.zipcode = zipcode;
    }

/*------------------------- Getters -------------------------*/

    public int getId() {
        return id;
    }

    public Users getUser() {
        return user;
    }

    public Address_Type getAddress_type() {
        return address_type;
    }

    public String getFirstname() {
        return firstname;
    }

    public String getLastname() {
        return lastname;
    }

    public String getStreet_address_1() {
        return street_address_1;
    }

    public String getStreet_address_2() {
        return street_address_2;
    }

    public String getPo_box() {
        return po_box;
    }

    public String getCity() {
        return city;
    }

    public US_States getUs_state() {
        return us_state;
    }

    public String getZipcode() {
        return zipcode;
    }

/*------------------------- Setters -------------------------*/

    public void setUser(Users user) {
        this.user = user;
    }

    public void setAddress_type(Address_Type address_type) {
        this.address_type = address_type;
    }

    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    public void setStreet_address_1(String street_address_1) {
        this.street_address_1 = street_address_1;
    }

    public void setStreet_address_2(String street_address_2) {
        this.street_address_2 = street_address_2;
    }

    public void setPo_box(String po_box) {
        this.po_box = po_box;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public void setUs_state(US_States us_state) {
        this.us_state = us_state;
    }

    public void setZipcode(String zipcode) {
        this.zipcode = zipcode;
    }
}
