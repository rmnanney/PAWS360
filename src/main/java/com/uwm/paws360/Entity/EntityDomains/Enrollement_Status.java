package com.uwm.paws360.Entity.EntityDomains;

public enum Enrollement_Status {
    ENROLLED("Enrolled"),
    WAITLISTED("Waitlisted"),
    DROPPED("Dropped"),
    COMPLETED("Completed"),
    WITHDRAWN("Withdrawn");

    private final String label;

    Enrollement_Status(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }
}
