package com.uwm.paws360.Entity.UserTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class Faculty {
    @Id
    @Column(name = "faculty_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    public Faculty(){}

    public int getId() {
        return id;
    }
}
