package com.uwm.paws360.Entity.UserTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class Instructor {

    @Id
    @Column(name = "instructor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    public Instructor(){}

    public int getId() {
        return id;
    }
}
