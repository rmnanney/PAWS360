package com.uwm.paws360.Entity.Domains;

public enum Student_Standing {
    FRESHMAN("Freshman"),
    SOPHOMORE("Sophomore"),
    JUNIOR("Junior"),
    SENIOR("Senior");

    private final String label;

    Student_Standing(String label){
        this.label = label;
    }

    public String getStanding(){
        return this.label;
    }
}
