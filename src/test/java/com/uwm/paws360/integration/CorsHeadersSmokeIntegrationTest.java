package com.uwm.paws360.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.cors.CorsConfigurationSource;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class CorsHeadersSmokeIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private CorsConfigurationSource corsConfigurationSource;

    @Test
    void shouldReturnCorsHeadersForOptionsPreflight() {
        String baseUrl = "http://localhost:" + port;

        HttpHeaders preflightHeaders = new HttpHeaders();
        preflightHeaders.set("Origin", "http://localhost:3000");
        preflightHeaders.setAccessControlRequestMethod(HttpMethod.POST);
        preflightHeaders.setAccessControlRequestHeaders(List.of("content-type"));

        ResponseEntity<String> pre = restTemplate.exchange(
                baseUrl + "/auth/login",
                HttpMethod.OPTIONS,
                new HttpEntity<>(preflightHeaders),
                String.class
        );

        assertThat(pre.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(pre.getHeaders().getAccessControlAllowOrigin()).isEqualTo("http://localhost:3000");
        assertThat(pre.getHeaders().getAccessControlAllowMethods()).contains(HttpMethod.POST);
        assertThat(pre.getHeaders().getFirst("Access-Control-Allow-Credentials")).isEqualTo("true");

        // Confirm CORS bean is present and not overridden in test scope
        assertThat(corsConfigurationSource).isNotNull();
    }
}
