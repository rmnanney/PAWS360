# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for PAWS360
FROM maven:3.9-eclipse-temurin-21-alpine AS build

# Set working directory
WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Copy source code  
COPY src ./src

# Build application using a named BuildKit volume that can be pre-populated
# Use `paws360-m2-cache` volume populated by `ci/populate-m2.sh` to avoid
# network dependency during image build (helps when AppArmor blocks build-time network)
RUN --mount=type=volume,source=paws360-m2-cache,target=/root/.m2 \
  mvn clean package -DskipTests -B

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