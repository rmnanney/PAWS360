package com.uwm.paws360.Entity.EntityDomains;

public enum Grade_Type {
    LETTER("Letter"),
    PERCENTAGE("Percentage"),
    PASSFAIL("Pass/Fail"),
    AUDIT("Audit");

    private final String label;

    Grade_Type(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }
}
