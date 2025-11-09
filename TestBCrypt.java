import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class TestBCrypt {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hash = "$2a$10$N9qo8uLOickgx2ZMRZoMye1IcUWa1aNOWWrF5Dq9/TXzXYpY1VQ.y";
        System.out.println("Password 'password' matches hash: " + encoder.matches("password", hash));
        System.out.println("Fresh hash for 'password': " + encoder.encode("password"));
    }
}