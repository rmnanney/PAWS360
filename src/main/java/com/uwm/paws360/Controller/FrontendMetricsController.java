// T061: Frontend Metrics Collection Controller
// Constitutional Compliance: Article VIIa (Monitoring Discovery and Integration)
//
// Spring Boot controller for receiving and processing frontend performance metrics
// from Next.js application, integrating with Prometheus for constitutional compliance

package com.uwm.paws360.Controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.validation.annotation.Validated;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Timer;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.Tags;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/api/monitoring")
@CrossOrigin(origins = {"http://localhost:3000", "http://localhost:9002"})
@Validated
public class FrontendMetricsController {

    private static final Logger logger = LoggerFactory.getLogger(FrontendMetricsController.class);

    @Autowired
    private MeterRegistry meterRegistry;

    // Metrics storage for aggregation
    private final Map<String, AtomicLong> performanceCounters = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> errorCounters = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> interactionCounters = new ConcurrentHashMap<>();

    // Data Transfer Objects
    public static class PerformanceMetric {
        @NotNull
        public String name;
        @NotNull
        public Double value;
        @NotNull
        public Long timestamp;
        @NotNull
        public String url;
        public String userId;
        @NotNull
        public String sessionId;
    }

    public static class ErrorMetric {
        @NotNull
        public String type;
        @NotNull
        public String message;
        public String stack;
        @NotNull
        public String url;
        @NotNull
        public Long timestamp;
        public String userId;
        @NotNull
        public String sessionId;
        @NotNull
        public String userAgent;
    }

    public static class UserInteractionMetric {
        @NotNull
        public String action;
        public String element;
        public Double duration;
        @NotNull
        public Boolean success;
        @NotNull
        public Long timestamp;
        @NotNull
        public String url;
        public String userId;
        @NotNull
        public String sessionId;
    }

    public static class NavigationMetric {
        @NotNull
        public String from;
        @NotNull
        public String to;
        @NotNull
        public Double duration;
        @NotNull
        public Long timestamp;
        public String userId;
        @NotNull
        public String sessionId;
    }

    public static class FrontendMetricsPayload {
        @NotNull
        public String sessionId;
        public String userId;
        @NotNull
        public Long timestamp;
        @NotNull
        public List<PerformanceMetric> metrics;
        @NotNull
        public List<ErrorMetric> errors;
        @NotNull
        public List<UserInteractionMetric> interactions;
        @NotNull
        public List<NavigationMetric> navigations;
        @NotNull
        public Map<String, Object> metadata;
    }

    @PostMapping("/frontend-metrics")
    public ResponseEntity<Map<String, Object>> receiveFrontendMetrics(
            @Valid @RequestBody FrontendMetricsPayload payload) {
        
        try {
            logger.info("Received frontend metrics - Session: {}, Metrics: {}, Errors: {}, Interactions: {}, Navigations: {}", 
                payload.sessionId, 
                payload.metrics.size(), 
                payload.errors.size(), 
                payload.interactions.size(), 
                payload.navigations.size());

            // Process performance metrics
            processPerformanceMetrics(payload.metrics, payload.userId, payload.sessionId);

            // Process error metrics
            processErrorMetrics(payload.errors, payload.userId, payload.sessionId);

            // Process interaction metrics
            processInteractionMetrics(payload.interactions, payload.userId, payload.sessionId);

            // Process navigation metrics
            processNavigationMetrics(payload.navigations, payload.userId, payload.sessionId);

            // Update session activity
            updateSessionActivity(payload.sessionId, payload.userId);

            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("processed", Map.of(
                "metrics", payload.metrics.size(),
                "errors", payload.errors.size(),
                "interactions", payload.interactions.size(),
                "navigations", payload.navigations.size()
            ));
            response.put("timestamp", Instant.now().toEpochMilli());
            response.put("constitutional", "Article VIIa");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("Error processing frontend metrics", e);
            
            // Record processing error
            Counter.builder("paws360_frontend_metrics_processing_errors")
                .description("Frontend metrics processing errors")
                .tag("constitutional", "VIIa")
                .register(meterRegistry)
                .increment();

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("status", "error");
            errorResponse.put("message", "Failed to process metrics");
            errorResponse.put("timestamp", Instant.now().toEpochMilli());

            return ResponseEntity.status(500).body(errorResponse);
        }
    }

    private void processPerformanceMetrics(List<PerformanceMetric> metrics, String userId, String sessionId) {
        for (PerformanceMetric metric : metrics) {
            try {
                // Create tags for metric categorization
                Tags tags = Tags.of(
                    "metric_name", metric.name,
                    "session_id", sessionId,
                    "constitutional", "VIIa"
                );

                if (userId != null) {
                    tags = tags.and("user_id", userId);
                }

                // Extract page from URL for additional tagging
                String page = extractPageFromUrl(metric.url);
                tags = tags.and("page", page);

                // Record the metric value
                Timer.Sample sample = Timer.start(meterRegistry);
                sample.stop(Timer.builder(metric.name)
                    .description("Frontend performance metric")
                    .tags(tags)
                    .register(meterRegistry));

                // Also record as a gauge for current values
                Gauge.builder(metric.name + "_current", () -> metric.value)
                    .description("Current frontend performance metric value")
                    .tags(tags)
                    .register(meterRegistry);

                // Track Web Vitals specifically
                if (isWebVital(metric.name)) {
                    recordWebVital(metric.name, metric.value, tags);
                }

                // Update performance counters
                performanceCounters.computeIfAbsent(metric.name, k -> new AtomicLong(0)).incrementAndGet();

            } catch (Exception e) {
                logger.warn("Error processing performance metric: {}", metric.name, e);
            }
        }
    }

    private void processErrorMetrics(List<ErrorMetric> errors, String userId, String sessionId) {
        for (ErrorMetric error : errors) {
            try {
                Tags tags = Tags.of(
                    "error_type", error.type,
                    "session_id", sessionId,
                    "constitutional", "VIIa"
                );

                if (userId != null) {
                    tags = tags.and("user_id", userId);
                }

                String page = extractPageFromUrl(error.url);
                tags = tags.and("page", page);

                // Count frontend errors
                Counter.builder("paws360_frontend_errors_total")
                    .description("Frontend errors by type")
                    .tags(tags)
                    .register(meterRegistry)
                    .increment();

                // Track specific error types
                if ("authentication".equals(error.type)) {
                    Counter.builder("paws360_frontend_auth_errors_total")
                        .description("Frontend authentication errors")
                        .tags(tags)
                        .register(meterRegistry)
                        .increment();
                }

                // Update error counters
                errorCounters.computeIfAbsent(error.type, k -> new AtomicLong(0)).incrementAndGet();

                // Log critical errors
                if ("javascript".equals(error.type) || "authentication".equals(error.type)) {
                    logger.warn("Frontend {} error - Session: {}, Message: {}, URL: {}", 
                        error.type, sessionId, error.message, error.url);
                }

            } catch (Exception e) {
                logger.warn("Error processing error metric: {}", error.type, e);
            }
        }
    }

    private void processInteractionMetrics(List<UserInteractionMetric> interactions, String userId, String sessionId) {
        for (UserInteractionMetric interaction : interactions) {
            try {
                Tags tags = Tags.of(
                    "action", interaction.action,
                    "success", String.valueOf(interaction.success),
                    "session_id", sessionId,
                    "constitutional", "VIIa"
                );

                if (userId != null) {
                    tags = tags.and("user_id", userId);
                }

                String page = extractPageFromUrl(interaction.url);
                tags = tags.and("page", page);

                if (interaction.element != null) {
                    tags = tags.and("element", interaction.element);
                }

                // Count user interactions
                Counter.builder("paws360_frontend_interactions_total")
                    .description("Frontend user interactions")
                    .tags(tags)
                    .register(meterRegistry)
                    .increment();

                // Track interaction timing if available
                if (interaction.duration != null) {
                    Timer.builder("paws360_frontend_interaction_duration")
                        .description("Frontend interaction duration")
                        .tags(tags)
                        .register(meterRegistry)
                        .record(interaction.duration.longValue(), java.util.concurrent.TimeUnit.MILLISECONDS);
                }

                // Track authentication events specifically
                if ("login".equals(interaction.action) || "logout".equals(interaction.action)) {
                    Counter.builder("paws360_frontend_auth_events_total")
                        .description("Frontend authentication events")
                        .tags(tags)
                        .register(meterRegistry)
                        .increment();
                }

                // Update interaction counters
                interactionCounters.computeIfAbsent(interaction.action, k -> new AtomicLong(0)).incrementAndGet();

            } catch (Exception e) {
                logger.warn("Error processing interaction metric: {}", interaction.action, e);
            }
        }
    }

    private void processNavigationMetrics(List<NavigationMetric> navigations, String userId, String sessionId) {
        for (NavigationMetric navigation : navigations) {
            try {
                Tags tags = Tags.of(
                    "from_page", extractPageFromUrl(navigation.from),
                    "to_page", extractPageFromUrl(navigation.to),
                    "session_id", sessionId,
                    "constitutional", "VIIa"
                );

                if (userId != null) {
                    tags = tags.and("user_id", userId);
                }

                // Record navigation timing
                Timer.builder("paws360_frontend_navigation_duration")
                    .description("Frontend navigation duration")
                    .tags(tags)
                    .register(meterRegistry)
                    .record(navigation.duration.longValue(), java.util.concurrent.TimeUnit.MILLISECONDS);

                // Count page navigations
                Counter.builder("paws360_frontend_navigations_total")
                    .description("Frontend page navigations")
                    .tags(tags)
                    .register(meterRegistry)
                    .increment();

            } catch (Exception e) {
                logger.warn("Error processing navigation metric", e);
            }
        }
    }

    private void updateSessionActivity(String sessionId, String userId) {
        Tags tags = Tags.of(
            "session_id", sessionId,
            "constitutional", "VIIa"
        );

        if (userId != null) {
            tags = tags.and("user_id", userId);
        }

        // Update session activity timestamp
        Gauge.builder("paws360_frontend_session_last_activity", () -> (double) Instant.now().toEpochMilli())
            .description("Last activity timestamp for frontend session")
            .tags(tags)
            .register(meterRegistry);

        // Count active sessions
        Counter.builder("paws360_frontend_session_activity_total")
            .description("Frontend session activity events")
            .tags(tags)
            .register(meterRegistry)
            .increment();
    }

    private String extractPageFromUrl(String url) {
        try {
            java.net.URL parsedUrl = new java.net.URL(url);
            String path = parsedUrl.getPath();
            return path.isEmpty() ? "/" : path;
        } catch (Exception e) {
            return "/unknown";
        }
    }

    private boolean isWebVital(String metricName) {
        return metricName.contains("vitals_cls") || 
               metricName.contains("vitals_inp") || 
               metricName.contains("vitals_fcp") || 
               metricName.contains("vitals_lcp") || 
               metricName.contains("vitals_ttfb");
    }

    private void recordWebVital(String vitalName, double value, Tags tags) {
        // Record Web Vital with specific thresholds
        Timer.builder("paws360_frontend_web_vital")
            .description("Core Web Vitals performance metrics")
            .tags(tags.and("vital", vitalName))
            .register(meterRegistry)
            .record((long) value, java.util.concurrent.TimeUnit.MILLISECONDS);

        // Check thresholds and record violations
        if (isWebVitalViolation(vitalName, value)) {
            Counter.builder("paws360_frontend_web_vital_violations_total")
                .description("Web Vital threshold violations")
                .tags(tags.and("vital", vitalName))
                .register(meterRegistry)
                .increment();

            logger.warn("Web Vital violation - {}: {} (constitutional: Article VIIa)", vitalName, value);
        }
    }

    private boolean isWebVitalViolation(String vitalName, double value) {
        return switch (vitalName) {
            case "vitals_cls" -> value > 0.25;     // Cumulative Layout Shift
            case "vitals_inp" -> value > 300;     // Interaction to Next Paint
            case "vitals_fcp" -> value > 3000;    // First Contentful Paint
            case "vitals_lcp" -> value > 4000;    // Largest Contentful Paint
            case "vitals_ttfb" -> value > 1500;   // Time to First Byte
            default -> false;
        };
    }

    @GetMapping("/frontend-metrics/summary")
    public ResponseEntity<Map<String, Object>> getFrontendMetricsSummary() {
        Map<String, Object> summary = new HashMap<>();
        summary.put("performance_metrics", performanceCounters.size());
        summary.put("error_types", errorCounters.size());
        summary.put("interaction_types", interactionCounters.size());
        summary.put("total_performance_events", performanceCounters.values().stream().mapToLong(AtomicLong::get).sum());
        summary.put("total_errors", errorCounters.values().stream().mapToLong(AtomicLong::get).sum());
        summary.put("total_interactions", interactionCounters.values().stream().mapToLong(AtomicLong::get).sum());
        summary.put("timestamp", Instant.now().toEpochMilli());
        summary.put("constitutional", "Article VIIa");

        return ResponseEntity.ok(summary);
    }

    @GetMapping("/frontend-metrics/health")
    public ResponseEntity<Map<String, Object>> getFrontendMetricsHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("metrics_collection", "enabled");
        health.put("constitutional_compliance", "Article VIIa");
        health.put("timestamp", Instant.now().toEpochMilli());

        return ResponseEntity.ok(health);
    }
}