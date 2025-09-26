package com.uwm.paws360.Entity.UserTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class Mentor {

    @Id
    @Column(name = "mentor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    public Mentor(){}

    public int getId() {
        return id;
    }
}
