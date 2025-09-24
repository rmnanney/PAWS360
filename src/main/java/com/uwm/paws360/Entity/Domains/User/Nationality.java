package com.uwm.paws360.Entity.Domains.User;

public enum Nationality {
    // North America
    UNITED_STATES("United States", "US"),
    CANADA("Canada", "CA"),
    MEXICO("Mexico", "MX"),

    // South America
    BRAZIL("Brazil", "BR"),
    ARGENTINA("Argentina", "AR"),
    CHILE("Chile", "CL"),
    COLOMBIA("Colombia", "CO"),
    PERU("Peru", "PE"),

    // Europe
    UNITED_KINGDOM("United Kingdom", "GB"),
    FRANCE("France", "FR"),
    GERMANY("Germany", "DE"),
    ITALY("Italy", "IT"),
    SPAIN("Spain", "ES"),
    PORTUGAL("Portugal", "PT"),
    NETHERLANDS("Netherlands", "NL"),
    BELGIUM("Belgium", "BE"),
    SWEDEN("Sweden", "SE"),
    NORWAY("Norway", "NO"),
    DENMARK("Denmark", "DK"),
    FINLAND("Finland", "FI"),
    POLAND("Poland", "PL"),
    GREECE("Greece", "GR"),
    SWITZERLAND("Switzerland", "CH"),
    IRELAND("Ireland", "IE"),
    RUSSIA("Russia", "RU"),

    // Africa
    NIGERIA("Nigeria", "NG"),
    SOUTH_AFRICA("South Africa", "ZA"),
    EGYPT("Egypt", "EG"),
    KENYA("Kenya", "KE"),
    GHANA("Ghana", "GH"),
    ETHIOPIA("Ethiopia", "ET"),
    MOROCCO("Morocco", "MA"),

    // Middle East
    SAUDI_ARABIA("Saudi Arabia", "SA"),
    UNITED_ARAB_EMIRATES("United Arab Emirates", "AE"),
    TURKEY("Turkey", "TR"),
    ISRAEL("Israel", "IL"),
    IRAN("Iran", "IR"),

    // Asia
    INDIA("India", "IN"),
    CHINA("China", "CN"),
    JAPAN("Japan", "JP"),
    SOUTH_KOREA("South Korea", "KR"),
    PAKISTAN("Pakistan", "PK"),
    BANGLADESH("Bangladesh", "BD"),
    INDONESIA("Indonesia", "ID"),
    PHILIPPINES("Philippines", "PH"),
    VIETNAM("Vietnam", "VN"),
    THAILAND("Thailand", "TH"),
    MALAYSIA("Malaysia", "MY"),
    SINGAPORE("Singapore", "SG"),

    // Oceania
    AUSTRALIA("Australia", "AU"),
    NEW_ZEALAND("New Zealand", "NZ"),
    FIJI("Fiji", "FJ"),

    // Catch-alls
    OTHER("Other", "XX"),
    PREFER_NOT_TO_ANSWER("Prefer not to answer", "NA");

    private final String label;
    private final String code;

    Nationality(String label, String code) {
        this.label = label;
        this.code = code;
    }

    public String getLabel() {
        return label;
    }

    public String getCode() {
        return code;
    }
}
