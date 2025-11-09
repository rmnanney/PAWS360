package com.uwm.paws360.Service;

import com.uwm.paws360.Entity.Base.Users;
import com.uwm.paws360.JPARepository.User.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service for managing demo data reset and initialization functionality.
 * Supports resetting the database to a known baseline state for demo repeatability.
 */
@Service
@Transactional
public class DemoDataService {

    private static final Logger logger = LoggerFactory.getLogger(DemoDataService.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StudentRepository studentRepository;

    // Repository dependencies removed to avoid unused field warnings
    // Direct SQL operations are used for bulk data operations

    /**
     * Resets all demo data to baseline state for consistent demo execution.
     * This operation truncates all user-related tables and reloads demo seed data.
     * 
     * @return DemoResetResult containing operation status and details
     */
    @Transactional
    public DemoResetResult resetDemoData() {
        logger.info("Starting demo data reset operation");
        
        try {
            // Step 1: Clear existing data in proper order to respect foreign key constraints
            clearExistingData();
            
            // Step 2: Reset auto-increment sequences
            resetSequences();
            
            // Step 3: Load demo seed data
            loadDemoSeedData();
            
            // Step 4: Verify demo data integrity
            DemoDataValidation validation = validateDemoData();
            
            if (validation.isValid()) {
                logger.info("Demo data reset completed successfully");
                return new DemoResetResult(true, "Demo data reset successful", validation);
            } else {
                logger.error("Demo data validation failed after reset: {}", validation.getErrors());
                return new DemoResetResult(false, "Demo data validation failed", validation);
            }
            
        } catch (Exception e) {
            logger.error("Demo data reset failed", e);
            return new DemoResetResult(false, "Demo data reset failed: " + e.getMessage(), null);
        }
    }

    /**
     * Validates the current state of demo data to ensure consistency.
     * 
     * @return DemoDataValidation containing validation results
     */
    public DemoDataValidation validateDemoData() {
        logger.info("Validating demo data integrity");
        
        DemoDataValidation validation = new DemoDataValidation();
        
        try {
            // Check for required demo accounts
            validateDemoAccounts(validation);
            
            // Check data consistency between users and role tables
            validateRoleConsistency(validation);
            
            // Check for orphaned records
            validateDataIntegrity(validation);
            
            logger.info("Demo data validation completed. Valid: {}, Errors: {}", 
                       validation.isValid(), validation.getErrors().size());
            
        } catch (Exception e) {
            logger.error("Demo data validation failed", e);
            validation.addError("Validation process failed: " + e.getMessage());
        }
        
        return validation;
    }

    /**
     * Provides status information about the current demo environment.
     * 
     * @return DemoStatusInfo containing current environment status
     */
    public DemoStatusInfo getDemoStatus() {
        logger.debug("Retrieving demo environment status");
        
        try {
            long totalUsers = userRepository.count();
            long totalStudents = studentRepository.count();
            long totalAdministrators = countAdministrators();
            
            List<String> demoAccounts = getDemoAccountEmails();
            
            DemoDataValidation validation = validateDemoData();
            
            return new DemoStatusInfo(
                true,
                totalUsers,
                totalStudents,
                totalAdministrators,
                demoAccounts,
                validation.isValid(),
                validation.getErrors()
            );
            
        } catch (Exception e) {
            logger.error("Failed to retrieve demo status", e);
            return new DemoStatusInfo(
                false,
                0,
                0,
                0,
                List.of(),
                false,
                List.of("Failed to retrieve demo status: " + e.getMessage())
            );
        }
    }

    private void clearExistingData() {
        logger.info("Clearing existing demo data");
        
        // Clear in reverse dependency order to avoid FK constraint violations
        jdbcTemplate.execute("DELETE FROM authentication_sessions");
        jdbcTemplate.execute("DELETE FROM emergency_contacts");
        jdbcTemplate.execute("DELETE FROM addresses");
        
        // Clear role-specific tables
        jdbcTemplate.execute("DELETE FROM ta");
        jdbcTemplate.execute("DELETE FROM students");
        jdbcTemplate.execute("DELETE FROM professors");
        jdbcTemplate.execute("DELETE FROM mentors");
        jdbcTemplate.execute("DELETE FROM instructors");
        jdbcTemplate.execute("DELETE FROM faculty");
        jdbcTemplate.execute("DELETE FROM counselors");
        jdbcTemplate.execute("DELETE FROM advisors");
        
        // Finally clear users table
        jdbcTemplate.execute("DELETE FROM users");
        
        logger.info("Existing data cleared successfully");
    }

    private void resetSequences() {
        logger.info("Resetting auto-increment sequences");
        
        try {
            // Reset sequences for all tables with auto-increment IDs
            jdbcTemplate.execute("ALTER SEQUENCE users_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE students_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE advisors_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE counselors_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE faculty_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE instructors_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE mentors_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE professors_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE ta_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE addresses_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE emergency_contacts_id_seq RESTART WITH 1");
            jdbcTemplate.execute("ALTER SEQUENCE authentication_sessions_id_seq RESTART WITH 1");
            
            logger.info("Sequences reset successfully");
        } catch (Exception e) {
            logger.warn("Some sequences may not exist yet, continuing: {}", e.getMessage());
        }
    }

    private void loadDemoSeedData() {
        logger.info("Loading demo seed data");
        
        try {
            // Load demo seed data from SQL file
            ClassPathResource resource = new ClassPathResource("demo_seed_data.sql");
            if (!resource.exists()) {
                // Fallback to database directory
                loadExternalSeedData();
                return;
            }
            
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
                String sqlContent = reader.lines()
                        .filter(line -> !line.trim().isEmpty() && !line.trim().startsWith("--"))
                        .collect(Collectors.joining("\n"));
                
                // Execute the SQL content
                String[] statements = sqlContent.split(";");
                for (String statement : statements) {
                    if (!statement.trim().isEmpty()) {
                        jdbcTemplate.execute(statement.trim());
                    }
                }
            }
            
            logger.info("Demo seed data loaded successfully");
            
        } catch (Exception e) {
            logger.error("Failed to load demo seed data", e);
            throw new RuntimeException("Failed to load demo seed data: " + e.getMessage(), e);
        }
    }

    private void loadExternalSeedData() {
        logger.info("Loading external demo seed data from database directory");
        
        // This is a simplified version - in practice, you might want to read from external files
        // For now, create minimal demo data programmatically
        
        try {
            // Insert demo admin user
            jdbcTemplate.execute("""
                INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role, 
                                  ethnicity, gender, nationality, country_code, preferred_name,
                                  account_updated, last_login, changed_password, failed_attempts, account_locked,
                                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                                  ferpa_directory_opt_in, photo_release_opt_in) VALUES
                ('Admin', 'User', '1980-01-01', '123456789', 'admin@uwm.edu', 
                 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 
                 '4149999999', 'ACTIVE', 'Administrator', 
                 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Administrator',
                 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
                 'RESTRICTED', true, true, false, false, false)
            """);
            
            // Insert demo student user
            jdbcTemplate.execute("""
                INSERT INTO users (firstname, lastname, dob, ssn, email, password, phone, status, role,
                                  ethnicity, gender, nationality, country_code, preferred_name,
                                  account_updated, last_login, changed_password, failed_attempts, account_locked,
                                  ferpa_compliance, contact_by_phone, contact_by_email, contact_by_mail,
                                  ferpa_directory_opt_in, photo_release_opt_in) VALUES
                ('John', 'Smith', '2002-05-15', '111223333', 'john.smith@uwm.edu',
                 '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
                 '4141234567', 'ACTIVE', 'STUDENT',
                 'WHITE', 'MALE', 'UNITED_STATES', 'US', 'Johnny',
                 CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_DATE, 0, false,
                 'DIRECTORY', true, true, false, true, true)
            """);
            
            logger.info("Minimal demo data created successfully");
            
        } catch (Exception e) {
            logger.error("Failed to create minimal demo data", e);
            throw new RuntimeException("Failed to create minimal demo data: " + e.getMessage(), e);
        }
    }

    private void validateDemoAccounts(DemoDataValidation validation) {
        // Check for required demo accounts
        String[] requiredEmails = {
            "admin@uwm.edu",
            "john.smith@uwm.edu"
        };
        
        for (String email : requiredEmails) {
            Users user = userRepository.findUsersByEmailIgnoreCase(email);
            if (user == null) {
                validation.addError("Required demo account not found: " + email);
            }
        }
    }

    private void validateRoleConsistency(DemoDataValidation validation) {
        // Check that users with STUDENT role have corresponding student records
        // Using SQL query since findByRole method doesn't exist
        try {
            List<String> studentEmails = jdbcTemplate.queryForList(
                "SELECT email FROM users WHERE role = 'STUDENT'", String.class);
            
            for (String email : studentEmails) {
                Long studentCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM students s JOIN users u ON s.user_id = u.id WHERE u.email = ?",
                    Long.class, email);
                if (studentCount == 0) {
                    validation.addError("User " + email + " has STUDENT role but no student record");
                }
            }
        } catch (Exception e) {
            validation.addError("Failed to validate role consistency: " + e.getMessage());
        }
    }

    private void validateDataIntegrity(DemoDataValidation validation) {
        // Check for orphaned addresses
        long orphanedAddresses = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM addresses a WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = a.user_id)",
            Long.class
        );
        if (orphanedAddresses > 0) {
            validation.addError("Found " + orphanedAddresses + " orphaned address records");
        }
        
        // Check for orphaned emergency contacts
        long orphanedContacts = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM emergency_contacts e WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = e.user_id)",
            Long.class
        );
        if (orphanedContacts > 0) {
            validation.addError("Found " + orphanedContacts + " orphaned emergency contact records");
        }
    }

    private long countAdministrators() {
        return jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM users WHERE role = 'Administrator'", Long.class);
    }

    private List<String> getDemoAccountEmails() {
        return userRepository.findAll().stream()
                .map(Users::getEmail)
                .sorted()
                .collect(Collectors.toList());
    }

    // Data transfer objects for responses

    public static class DemoResetResult {
        private final boolean success;
        private final String message;
        private final DemoDataValidation validation;

        public DemoResetResult(boolean success, String message, DemoDataValidation validation) {
            this.success = success;
            this.message = message;
            this.validation = validation;
        }

        public boolean isSuccess() { return success; }
        public String getMessage() { return message; }
        public DemoDataValidation getValidation() { return validation; }
    }

    public static class DemoDataValidation {
        private final List<String> errors = new java.util.ArrayList<>();

        public void addError(String error) {
            errors.add(error);
        }

        public boolean isValid() {
            return errors.isEmpty();
        }

        public List<String> getErrors() {
            return List.copyOf(errors);
        }
    }

    public static class DemoStatusInfo {
        private final boolean healthy;
        private final long totalUsers;
        private final long totalStudents;
        private final long totalAdministrators;
        private final List<String> demoAccounts;
        private final boolean dataValid;
        private final List<String> validationErrors;

        public DemoStatusInfo(boolean healthy, long totalUsers, long totalStudents, 
                             long totalAdministrators, List<String> demoAccounts,
                             boolean dataValid, List<String> validationErrors) {
            this.healthy = healthy;
            this.totalUsers = totalUsers;
            this.totalStudents = totalStudents;
            this.totalAdministrators = totalAdministrators;
            this.demoAccounts = demoAccounts;
            this.dataValid = dataValid;
            this.validationErrors = validationErrors;
        }

        public boolean isHealthy() { return healthy; }
        public long getTotalUsers() { return totalUsers; }
        public long getTotalStudents() { return totalStudents; }
        public long getTotalAdministrators() { return totalAdministrators; }
        public List<String> getDemoAccounts() { return demoAccounts; }
        public boolean isDataValid() { return dataValid; }
        public List<String> getValidationErrors() { return validationErrors; }
    }
}