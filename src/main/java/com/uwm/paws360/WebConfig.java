package com.uwm.paws360;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.cors.CorsConfigurationSource;

@Configuration
public class WebConfig {

    @Value("${cors.allowed-origins:${CORS_ALLOWED_ORIGINS:http://localhost:9002}}")
    private String corsAllowedOrigins;

    @Value("${app.upload-dir:uploads}")
    private String uploadDir;
    @Value("${spring.web.cors.allowed-origins:http://localhost:9002}")
    private String allowedOrigins;

    @Bean
    public WebMvcConfigurer corsConfigurer(){
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry){
                String[] origins = java.util.Arrays.stream(corsAllowedOrigins.split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .toArray(String[]::new);
                registry.addMapping("/**")
                        .allowedOrigins(origins)
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .allowCredentials(true);
            }

            @Override
            public void addResourceHandlers(ResourceHandlerRegistry registry) {
                String uploadPath = java.nio.file.Paths.get(uploadDir)
                        .toAbsolutePath()
                        .normalize()
                        .toUri()
                        .toString();
                registry.addResourceHandler("/uploads/**")
                        .addResourceLocations(uploadPath)
                        .setCachePeriod(3600);
            }
        };
    }

    // Provide a CorsConfigurationSource bean used by Spring Security when http.cors() is enabled
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        for (String origin : allowedOrigins.split(",")) {
            // Add both explicit origin and pattern support to cover both exact and wildcard
            config.addAllowedOrigin(origin);
            config.addAllowedOriginPattern(origin);
        }
        config.addAllowedHeader(CorsConfiguration.ALL);
        config.addAllowedMethod(CorsConfiguration.ALL);
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
