package com.uwm.paws360.Entity.Domains.User;

import com.uwm.paws360.Entity.Address;

public enum Address_Type {
    HOME("Home"),
    BILLING("Billing"),
    MAILING("Mailing"),
    SHIPPING("Shipping"),
    WORK("Work"),
    CAMPUS("Campus"),
    EMERGENCY("Emergency"),
    OTHER("Other");

    private final String label;

    Address_Type(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }

}
