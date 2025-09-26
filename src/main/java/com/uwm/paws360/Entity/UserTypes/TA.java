package com.uwm.paws360.Entity.UserTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class TA {
    @Id
    @Column(nullable = false, unique = true, updatable = false)
    @GeneratedValue
    private int id;

    public TA(){}

    public int getId() {
        return id;
    }
}
