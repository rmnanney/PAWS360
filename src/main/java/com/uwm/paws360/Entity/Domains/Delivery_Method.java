package com.uwm.paws360.Entity.Domains;

public enum Delivery_Method {
    IN_PERSON("In-person"),
    ONLINE("Online"),
    HYBRID("Hybrid"),
    BLENDED("Blended");

    private final String label;

    Delivery_Method(String label){
        this.label = label;
    }

    public String getLabel(){
        return this.label;
    }
}
