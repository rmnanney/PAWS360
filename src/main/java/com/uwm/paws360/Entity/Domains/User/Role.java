package com.uwm.paws360.Entity.Domains.User;

public enum Role {
    STUDENT("Student"),
    PROFESSOR("Professor"),
    TA("Teacher Assistant"),
    INSTRUCTOR("Instructor"),
    COUNSELOR("Counselor"),
    MENTOR("Mentor"),
    ADVISOR("Advisor"),
    FACULTY("Faculty");

    private final String label;

    Role(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }

}
