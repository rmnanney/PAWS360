package com.uwm.paws360.Entity.Profiles;

import com.uwm.paws360.Entity.Users;
import jakarta.persistence.*;

@Entity
public class Professor {

    @Id
    @Column(name = "professor_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id")
    private Users user;

    @Column
    private double pay;

    public Professor(Users user, double pay) {
        this.user = user;
        this.pay = pay;
    }

    public Professor() {
    }

    public Users getUser() {
        return user;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public double getPay() {
        return pay;
    }

    public void setPay(double pay) {
        this.pay = pay;
    }
}
