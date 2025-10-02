# Multi-stage build for Spring Boot backend (cross-platform friendly)
# Stage 1: Build with official Maven + Temurin 21 (avoids wrapper + line-ending issues on Windows)
FROM maven:3.9.9-eclipse-temurin-21 AS build

WORKDIR /app

# Copy only pom first to leverage dependency layer caching
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Copy source (after deps cached)
COPY src ./src

# Optional build arg to skip tests (override with --build-arg SKIP_TESTS=false)
ARG SKIP_TESTS=true
# Build
RUN if [ "$SKIP_TESTS" = "true" ]; then \
      mvn -q clean package -DskipTests; \
    else \
      mvn -q clean package; \
    fi

# Stage 2: Minimal runtime image
FROM eclipse-temurin:21-jre

ENV JAVA_OPTS="-Xms256m -Xmx512m" \
    TZ=UTC \
    SPRING_PROFILES_ACTIVE=docker

# Install curl for healthcheck (Debian slim base)
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user (works on Linux hosts & Docker Desktop on Windows/macOS)
RUN groupadd -r spring && useradd -r -g spring spring
USER spring:spring

# Copy fat jar
COPY --from=build /app/target/concert-backend-*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:8080/actuator/health || exit 1

# Entry point (supports extra JAVA_OPTS at runtime)
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]

# Notes:
# - Works the same on Windows/macOS/Linux because build uses official Maven image (no mvnw chmod issues).
# - Override tests: docker build --build-arg SKIP_TESTS=false -t concert-backend .
# - Add --platform=linux/amd64 if building on Apple Silicon for a different target.
