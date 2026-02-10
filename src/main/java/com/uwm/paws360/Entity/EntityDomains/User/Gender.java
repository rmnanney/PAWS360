package com.uwm.paws360.Entity.EntityDomains.User;

public enum Gender {
    MALE("Male"),
    FEMALE("Female"),
    OTHER("Other");

    private final String label;

    Gender(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }
}
