package com.uwm.paws360.Entity.Domains;

public enum Country_Code {
    // North America
    US("+1"),          // United States
    CA("+1"),          // Canada
    MX("+52"),         // Mexico
    JM("+1-876"),      // Jamaica
    TT("+1-868"),      // Trinidad and Tobago
    BB("+1-246"),      // Barbados

    // South America
    BR("+55"),         // Brazil
    AR("+54"),         // Argentina
    CL("+56"),         // Chile
    CO("+57"),         // Colombia
    PE("+51"),         // Peru
    VE("+58"),         // Venezuela
    UY("+598"),        // Uruguay
    PY("+595"),        // Paraguay
    BO("+591"),        // Bolivia
    EC("+593"),        // Ecuador

    // Europe
    GB("+44"),         // United Kingdom
    IE("+353"),        // Ireland
    FR("+33"),         // France
    DE("+49"),         // Germany
    ES("+34"),         // Spain
    IT("+39"),         // Italy
    PT("+351"),        // Portugal
    NL("+31"),         // Netherlands
    BE("+32"),         // Belgium
    CH("+41"),         // Switzerland
    AT("+43"),         // Austria
    SE("+46"),         // Sweden
    NO("+47"),         // Norway
    DK("+45"),         // Denmark
    FI("+358"),        // Finland
    PL("+48"),         // Poland
    CZ("+420"),        // Czech Republic
    SK("+421"),        // Slovakia
    HU("+36"),         // Hungary
    GR("+30"),         // Greece
    RO("+40"),         // Romania
    BG("+359"),        // Bulgaria
    UA("+380"),        // Ukraine
    RU("+7"),          // Russia
    TR("+90"),         // Turkey

    // Middle East
    IL("+972"),        // Israel
    SA("+966"),        // Saudi Arabia
    AE("+971"),        // United Arab Emirates
    QA("+974"),        // Qatar
    KW("+965"),        // Kuwait
    OM("+968"),        // Oman
    BH("+973"),        // Bahrain
    JO("+962"),        // Jordan
    LB("+961"),        // Lebanon
    IR("+98"),         // Iran
    IQ("+964"),        // Iraq

    // Africa
    ZA("+27"),         // South Africa
    NG("+234"),        // Nigeria
    KE("+254"),        // Kenya
    EG("+20"),         // Egypt
    GH("+233"),        // Ghana
    TZ("+255"),        // Tanzania
    UG("+256"),        // Uganda
    ZM("+260"),        // Zambia
    ZW("+263"),        // Zimbabwe
    DZ("+213"),        // Algeria
    MA("+212"),        // Morocco
    TN("+216"),        // Tunisia
    ET("+251"),        // Ethiopia
    SD("+249"),        // Sudan

    // Asia
    IN("+91"),         // India
    CN("+86"),         // China
    JP("+81"),         // Japan
    KR("+82"),         // South Korea
    PK("+92"),         // Pakistan
    BD("+880"),        // Bangladesh
    LK("+94"),         // Sri Lanka
    NP("+977"),        // Nepal
    AF("+93"),         // Afghanistan
    MY("+60"),         // Malaysia
    SG("+65"),         // Singapore
    TH("+66"),         // Thailand
    VN("+84"),         // Vietnam
    PH("+63"),         // Philippines
    ID("+62"),         // Indonesia
    MM("+95"),         // Myanmar
    KH("+855"),        // Cambodia

    // Oceania
    AU("+61"),         // Australia
    NZ("+64"),         // New Zealand
    FJ("+679"),        // Fiji
    PG("+675");        // Papua New Guinea

    private final String code;

    Country_Code(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }
}
