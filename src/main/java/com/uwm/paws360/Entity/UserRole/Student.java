package com.uwm.paws360.Entity.UserRole;

import com.uwm.paws360.Entity.Users;
import jakarta.persistence.*;

@Entity
public class Student {

    @Id
    @Column(name = "student_id", unique = true, updatable = false)
    @GeneratedValue
    private int id;

    @OneToOne
    @JoinColumn(name = "user_id")
    private Users user;

    @Column
    private double gpa;

    public Student(Users user, double gpa) {
        this.user = user;
        this.gpa = gpa;
    }

    public Student() {
    }

    public Users getUser() {
        return user;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public double getGpa() {
        return gpa;
    }

    public void setGpa(double gpa) {
        this.gpa = gpa;
    }
}
