import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class TestHashCheck {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String storedHash = "$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.";
        String testPassword = "password";
        
        System.out.println("Testing password: '" + testPassword + "'");
        System.out.println("Against hash: " + storedHash);
        System.out.println("Match result: " + encoder.matches(testPassword, storedHash));
        
        // Generate a fresh hash for comparison
        String freshHash = encoder.encode(testPassword);
        System.out.println("Fresh hash for same password: " + freshHash);
        System.out.println("Fresh hash matches: " + encoder.matches(testPassword, freshHash));
    }
}