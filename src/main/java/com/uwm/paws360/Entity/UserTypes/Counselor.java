package com.uwm.paws360.Entity.UserTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity
public class Counselor {
    @Id
    @Column(name = "councelor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    public Counselor() {
    }

    public int getId() {
        return id;
    }
}
