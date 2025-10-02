# Multi-stage build for optimized Spring Boot Docker image
# Stage 1: Build stage
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy pom first for dependency layer caching
COPY pom.xml .
# Pre-fetch dependencies
RUN mvn -B dependency:go-offline

# Copy source
COPY src ./src

# Build (skip tests for faster image build)
RUN mvn -q clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:21-jre

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Non-root user
RUN addgroup --system spring && adduser --system spring --ingroup spring
USER spring:spring

# Copy built jar
COPY --from=builder /app/target/concert-backend-*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-Dspring.profiles.active=docker", "-Xmx512m", "-Xms256m", "-jar", "app.jar"]
