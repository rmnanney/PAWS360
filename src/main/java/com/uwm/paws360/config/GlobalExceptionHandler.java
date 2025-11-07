package com.uwm.paws360.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Global exception handler for PAWS360 application.
 * Provides consistent error handling and user-friendly messages across all endpoints.
 * Implements comprehensive logging for demo troubleshooting.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /**
     * Handle validation errors from @Valid annotations
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationExceptions(
            MethodArgumentNotValidException ex, HttpServletRequest request) {
        
        Map<String, String> fieldErrors = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.put(error.getField(), error.getDefaultMessage());
        }

        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.BAD_REQUEST,
            "Validation failed",
            "The request contains invalid data. Please check the highlighted fields.",
            request.getRequestURI()
        );
        errorResponse.put("field_errors", fieldErrors);

        logger.warn("Validation error on {} from {}: {}", 
            request.getRequestURI(), 
            getClientIp(request), 
            fieldErrors);

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle constraint violation exceptions
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> handleConstraintViolationExceptions(
            ConstraintViolationException ex, HttpServletRequest request) {
        
        List<String> violations = ex.getConstraintViolations()
            .stream()
            .map(ConstraintViolation::getMessage)
            .collect(Collectors.toList());

        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.BAD_REQUEST,
            "Constraint violation",
            "The request violates data constraints.",
            request.getRequestURI()
        );
        errorResponse.put("violations", violations);

        logger.warn("Constraint violation on {} from {}: {}", 
            request.getRequestURI(), 
            getClientIp(request), 
            violations);

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle missing request parameters
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, Object>> handleMissingParameterExceptions(
            MissingServletRequestParameterException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.BAD_REQUEST,
            "Missing required parameter",
            String.format("Required parameter '%s' is missing.", ex.getParameterName()),
            request.getRequestURI()
        );
        errorResponse.put("missing_parameter", ex.getParameterName());
        errorResponse.put("parameter_type", ex.getParameterType());

        logger.warn("Missing parameter '{}' on {} from {}", 
            ex.getParameterName(),
            request.getRequestURI(), 
            getClientIp(request));

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle HTTP method not supported
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> handleMethodNotSupportedExceptions(
            HttpRequestMethodNotSupportedException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.METHOD_NOT_ALLOWED,
            "Method not allowed",
            String.format("HTTP method '%s' is not supported for this endpoint.", ex.getMethod()),
            request.getRequestURI()
        );
        errorResponse.put("method", ex.getMethod());
        errorResponse.put("supported_methods", ex.getSupportedMethods());

        logger.warn("Unsupported method {} on {} from {}", 
            ex.getMethod(),
            request.getRequestURI(), 
            getClientIp(request));

        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(errorResponse);
    }

    /**
     * Handle unsupported media type
     */
    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<Map<String, Object>> handleMediaTypeNotSupportedExceptions(
            HttpMediaTypeNotSupportedException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.UNSUPPORTED_MEDIA_TYPE,
            "Unsupported media type",
            "The request content type is not supported.",
            request.getRequestURI()
        );
        errorResponse.put("content_type", ex.getContentType());
        errorResponse.put("supported_types", ex.getSupportedMediaTypes());

        logger.warn("Unsupported media type {} on {} from {}", 
            ex.getContentType(),
            request.getRequestURI(), 
            getClientIp(request));

        return ResponseEntity.status(HttpStatus.UNSUPPORTED_MEDIA_TYPE).body(errorResponse);
    }

    /**
     * Handle malformed JSON requests
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleMessageNotReadableExceptions(
            HttpMessageNotReadableException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.BAD_REQUEST,
            "Malformed request",
            "The request body contains invalid JSON or data format.",
            request.getRequestURI()
        );

        logger.warn("Malformed request on {} from {}: {}", 
            request.getRequestURI(), 
            getClientIp(request),
            ex.getMostSpecificCause().getMessage());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle type conversion errors
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleTypeMismatchExceptions(
            MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.BAD_REQUEST,
            "Invalid parameter type",
            String.format("Parameter '%s' should be of type %s.", 
                ex.getName(), 
                ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "unknown"),
            request.getRequestURI()
        );
        errorResponse.put("parameter", ex.getName());
        errorResponse.put("provided_value", ex.getValue());
        errorResponse.put("required_type", ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "unknown");

        logger.warn("Type mismatch for parameter '{}' on {} from {}: provided '{}', expected {}", 
            ex.getName(),
            request.getRequestURI(), 
            getClientIp(request),
            ex.getValue(),
            ex.getRequiredType());

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
    }

    /**
     * Handle database access exceptions
     */
    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, Object>> handleDataAccessExceptions(
            DataAccessException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "Database error",
            "A database operation failed. Please try again later.",
            request.getRequestURI()
        );

        logger.error("Database error on {} from {}: {}", 
            request.getRequestURI(), 
            getClientIp(request),
            ex.getMessage(), ex);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }

    /**
     * Handle endpoint not found
     */
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFoundExceptions(
            NoHandlerFoundException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.NOT_FOUND,
            "Endpoint not found",
            "The requested endpoint does not exist.",
            request.getRequestURI()
        );
        errorResponse.put("method", ex.getHttpMethod());

        logger.warn("Endpoint not found: {} {} from {}", 
            ex.getHttpMethod(),
            request.getRequestURI(), 
            getClientIp(request));

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
    }

    /**
     * Handle authentication-related exceptions
     */
    @ExceptionHandler({SecurityException.class})
    public ResponseEntity<Map<String, Object>> handleSecurityExceptions(
            SecurityException ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.UNAUTHORIZED,
            "Authentication required",
            "Please log in to access this resource.",
            request.getRequestURI()
        );

        logger.warn("Security error on {} from {}: {}", 
            request.getRequestURI(), 
            getClientIp(request),
            ex.getMessage());

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    /**
     * Handle all other unhandled exceptions
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneralExceptions(
            Exception ex, HttpServletRequest request) {
        
        Map<String, Object> errorResponse = createBaseErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "Internal server error",
            "An unexpected error occurred. Please try again later.",
            request.getRequestURI()
        );

        // Generate a unique error ID for tracking
        String errorId = generateErrorId();
        errorResponse.put("error_id", errorId);

        logger.error("Unhandled exception [{}] on {} from {}: {}", 
            errorId,
            request.getRequestURI(), 
            getClientIp(request),
            ex.getMessage(), ex);

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
    }

    /**
     * Create base error response structure
     */
    private Map<String, Object> createBaseErrorResponse(HttpStatus status, String error, String message, String path) {
        Map<String, Object> errorResponse = new HashMap<>();
        errorResponse.put("timestamp", LocalDateTime.now().toString());
        errorResponse.put("status", status.value());
        errorResponse.put("error", error);
        errorResponse.put("message", message);
        errorResponse.put("path", path);
        return errorResponse;
    }

    /**
     * Extract client IP address from request
     */
    private String getClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }

    /**
     * Generate unique error ID for tracking
     */
    private String generateErrorId() {
        return "ERR-" + System.currentTimeMillis() + "-" + (int)(Math.random() * 1000);
    }
}