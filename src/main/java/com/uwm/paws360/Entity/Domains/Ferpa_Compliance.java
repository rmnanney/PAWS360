package com.uwm.paws360.Entity.Domains;

public enum Ferpa_Compliance {
    PUBLIC("Public"),
    DIRECTORY("Directory"),
    RESTRICTED("Restricted"),
    CONFIDENTIAL("Confidential");

    private final String label;

    Ferpa_Compliance(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }
}
