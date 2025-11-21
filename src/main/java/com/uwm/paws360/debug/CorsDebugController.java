package com.uwm.paws360.debug;

import org.springframework.context.annotation.Profile;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Diagnostic controller available only under the 'test' profile. Exposes a
 * small endpoint to inspect configured CORS mappings for CI debugging.
 */
@RestController
@RequestMapping("/__debug")
@Profile("test")
public class CorsDebugController {

    private final CorsConfigurationSource corsConfigurationSource;

    public CorsDebugController(CorsConfigurationSource corsConfigurationSource) {
        this.corsConfigurationSource = corsConfigurationSource;
    }

    @GetMapping("/cors")
    public Map<String, Object> cors() {
        Map<String, Object> info = new HashMap<>();
        info.put("corsBeanClass", corsConfigurationSource.getClass().getName());

        if (corsConfigurationSource instanceof UrlBasedCorsConfigurationSource urlSource) {
            Map<String, CorsConfiguration> map = urlSource.getCorsConfigurations();
            Map<String, Object> mapped = new HashMap<>();
            for (String k : map.keySet()) {
                CorsConfiguration c = map.get(k);
                Map<String, Object> cinfo = new HashMap<>();
                cinfo.put("allowedOrigins", c.getAllowedOrigins() == null ? List.of() : c.getAllowedOrigins());
                cinfo.put("allowedOriginPatterns", c.getAllowedOriginPatterns() == null ? List.of() : c.getAllowedOriginPatterns());
                cinfo.put("allowedMethods", c.getAllowedMethods());
                cinfo.put("allowCredentials", c.getAllowCredentials());
                mapped.put(k, cinfo);
            }
            info.put("mappings", mapped);
        }

        return info;
    }
}
