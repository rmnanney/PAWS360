package com.uwm.paws360.Entity.Domains.User;

public enum Ethnicity {
    HISPANIC_OR_LATINO("Hispanic or Latino"),
    NOT_HISPANIC_OR_LATINO("Not Hispanic or Latino"),
    AMERICAN_INDIAN_OR_ALASKA_NATIVE("American Indian or Alaska Native"),
    ASIAN("Asian"),
    BLACK_OR_AFRICAN_AMERICAN("Black or African American"),
    NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER("Native Hawaiian or Other Pacific Islander"),
    WHITE("White"),
    TWO_OR_MORE_RACES("Two or More Races"),
    OTHER("Other"),
    PREFER_NOT_TO_ANSWER("Prefer not to answer");

    private final String label;

    Ethnicity(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
