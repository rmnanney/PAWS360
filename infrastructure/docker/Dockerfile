# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for PAWS360
FROM maven:3.9-eclipse-temurin-21-alpine AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (for better caching)
COPY pom.xml .
# Use BuildKit cache mount for Maven dependencies (best practice)
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B || true

# Copy source code
COPY src ./src

# Build the application with cache mount
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user  
RUN addgroup -S paws360 && adduser -S paws360 -G paws360

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R paws360:paws360 /app
USER paws360

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]