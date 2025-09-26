package com.uwm.paws360.Entity.EntityDomains;

public enum Department {
    // College of Letters & Science
    BIOLOGICAL_SCIENCES("Biological Sciences"),
    CHEMISTRY_BIOCHEMISTRY("Chemistry & Biochemistry"),
    COMPUTER_SCIENCE("Computer Science"),
    ECONOMICS("Economics"),
    ENGLISH("English"),
    HISTORY("History"),
    MATHEMATICAL_SCIENCES("Mathematical Sciences"),
    PHILOSOPHY("Philosophy"),
    PHYSICS("Physics"),
    POLITICAL_SCIENCE("Political Science"),
    PSYCHOLOGY("Psychology"),
    SOCIOLOGY("Sociology"),

    // Lubar College of Business
    ACCOUNTING("Accounting"),
    FINANCE("Finance"),
    INFORMATION_TECHNOLOGY_MANAGEMENT("Information Technology Management"),
    MARKETING("Marketing"),
    SUPPLY_CHAIN_OPERATIONS("Supply Chain & Operations Management"),

    // College of Engineering & Applied Science
    CIVIL_ENGINEERING("Civil & Environmental Engineering"),
    ELECTRICAL_ENGINEERING("Electrical Engineering"),
    INDUSTRIAL_ENGINEERING("Industrial Engineering"),
    MATERIALS_ENGINEERING("Materials Science & Engineering"),
    MECHANICAL_ENGINEERING("Mechanical Engineering"),

    // College of Health Professions & Sciences
    COMMUNICATION_SCIENCES_DISORDERS("Communication Sciences & Disorders"),
    BIOMEDICAL_SCIENCES("Biomedical Sciences"),
    OCCUPATIONAL_SCIENCE_TECHNOLOGY("Occupational Science & Technology"),
    KINESIOLOGY("Kinesiology"),
    NURSING("Nursing"),

    // School of Education
    CURRICULUM_INSTRUCTION("Curriculum & Instruction"),
    EDUCATIONAL_POLICY_COMMUNITY_STUDIES("Educational Policy & Community Studies"),
    EDUCATIONAL_PSYCHOLOGY("Educational Psychology"),
    ADMINISTRATIVE_LEADERSHIP("Administrative Leadership"),

    // Peck School of the Arts
    ART_DESIGN("Art & Design"),
    DANCE("Dance"),
    FILM_VIDEO_ANIMATION_NEW_GENRES("Film, Video, Animation & New Genres"),
    MUSIC("Music"),
    THEATRE("Theatre"),

    // School of Architecture & Urban Planning
    ARCHITECTURE("Architecture"),
    URBAN_PLANNING("Urban Planning"),

    // School of Freshwater Sciences
    FRESHWATER_SCIENCES("Freshwater Sciences"),

    // Zilber School of Public Health
    PUBLIC_HEALTH("Public Health"),

    // School of Information Studies
    INFORMATION_SCIENCE_TECHNOLOGY("Information Science & Technology"),

    // Other
    GENERAL_STUDIES("General Studies"),
    UNDECLARED("Undeclared");

    private final String label;

    Department(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}