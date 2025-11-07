package com.uwm.paws360;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web configuration for PAWS360 application.
 * Provides comprehensive CORS configuration for demo environment compatibility.
 */
@Configuration
public class WebConfig {

    private static final Logger logger = LoggerFactory.getLogger(WebConfig.class);

    // CORS configuration properties
    @Value("${paws360.cors.allowed-origins:http://localhost:3000,http://localhost:9002}")
    private String allowedOrigins;

    @Value("${paws360.cors.allowed-credentials:true}")
    private boolean allowCredentials;

    @Value("${paws360.cors.max-age:3600}")
    private long maxAge;

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                String[] origins = allowedOrigins.split(",");
                
                logger.info("Configuring CORS with allowed origins: {}", allowedOrigins);
                logger.info("CORS credentials allowed: {}", allowCredentials);
                
                registry.addMapping("/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                        .allowedHeaders(
                            "Content-Type",
                            "Authorization", 
                            "X-Requested-With",
                            "X-Session-Token",
                            "X-Service-Origin",
                            "Accept",
                            "Origin",
                            "Access-Control-Request-Method",
                            "Access-Control-Request-Headers"
                        )
                        .exposedHeaders(
                            "Access-Control-Allow-Origin",
                            "Access-Control-Allow-Credentials",
                            "X-Session-Token",
                            "Set-Cookie"
                        )
                        .allowCredentials(allowCredentials)
                        .maxAge(maxAge);

                // Specific mappings for demo endpoints with enhanced logging
                registry.addMapping("/auth/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "POST", "OPTIONS")
                        .allowCredentials(true);

                registry.addMapping("/api/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowCredentials(true);

                registry.addMapping("/health/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "OPTIONS")
                        .allowCredentials(false); // Health checks don't need credentials

                registry.addMapping("/demo/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "POST", "OPTIONS")
                        .allowCredentials(true);

                registry.addMapping("/metrics/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "POST", "OPTIONS")
                        .allowCredentials(false); // Metrics don't need credentials

                logger.info("CORS configuration completed successfully");
            }
        };
    }
}
