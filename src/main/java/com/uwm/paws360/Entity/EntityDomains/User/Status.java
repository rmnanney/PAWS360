package com.uwm.paws360.Entity.EntityDomains.User;

public enum Status {
    ACTIVE("Active"),
    INACTIVE("Inactive"),
    PENDING("Pending"),
    SUSPENDED("Suspended");

    private final String label;

    Status(String label) {
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }
}
