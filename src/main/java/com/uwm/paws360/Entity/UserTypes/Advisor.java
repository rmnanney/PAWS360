package com.uwm.paws360.Entity.UserTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class Advisor {

    @Id
    @Column(name = "advisor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    public Advisor() {
    }

    public int getId() {
        return id;
    }
}
