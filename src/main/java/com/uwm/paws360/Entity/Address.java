package com.uwm.paws360.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class Address {

    @Id
    @Column(name = "address_id", unique = true, updatable = false, nullable = false)
    @GeneratedValue
    private int id;



}
