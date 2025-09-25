package com.uwm.paws360.Entity;

import com.uwm.paws360.Entity.Domains.User.Address_Type;
import com.uwm.paws360.Entity.Domains.User.US_States;
import jakarta.persistence.*;

import java.util.List;

@Entity
public class Address {

    @Id
    @Column(name = "address_id", unique = true, updatable = false, nullable = false)
    @GeneratedValue
    private int id;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Address_Type address_type;

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

    @OneToMany(
            mappedBy = "address",
            cascade = CascadeType.ALL
    )
    private List<Users> users;

}
