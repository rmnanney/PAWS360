# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for PAWS360
# Base image with Maven and JDK for building
FROM maven:3.9-eclipse-temurin-21-alpine AS build

# Set working directory
WORKDIR /app

# Copy Maven settings to configure local repository
RUN mkdir -p /root/.m2 && \
    echo '<settings><localRepository>/cache/maven</localRepository></settings>' > /root/.m2/settings.xml

# Copy pom.xml and pre-resolve dependencies using cache mount
# The cache mount persists Maven repository between builds
COPY pom.xml .
RUN --mount=type=cache,target=/cache/maven \
    mvn dependency:resolve -B || true

# Copy source code
COPY src ./src

# Build application with cache mount (dependencies already resolved)
RUN --mount=type=cache,target=/cache/maven \
    mvn clean package -DskipTests -B -Dmaven.artifact.threads=10 -o

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