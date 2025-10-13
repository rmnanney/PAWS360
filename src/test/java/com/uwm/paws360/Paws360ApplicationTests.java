package com.uwm.paws360;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
class Paws360ApplicationTests {

    @Test
    void contextLoads() {
        // Test that the application context loads successfully with TestContainers
    }

}
