# Redis Connection Fix for CI/CD Pipeline

**Date:** November 22, 2025  
**Commit:** `1c99c25`  
**Branch:** `release/v1.0.0`

## Problem

Backend test jobs were **failing** with Redis connection errors:

```
org.springframework.data.redis.RedisConnectionFailureException: Unable to connect to Redis
```

### Root Cause Analysis

1. **Redis Dependency Present:**
   - `pom.xml` includes `spring-boot-starter-data-redis`
   - Spring Boot auto-configures Redis connection on startup

2. **Test Configuration:**
   - `application-test.properties` disables Redis repositories:
     ```properties
     spring.data.redis.repositories.enabled=false
     spring.cache.type=none
     ```
   - However, this **doesn't prevent** Spring Boot from trying to establish a connection

3. **Missing Service in CI:**
   - GitHub Actions workflows had MySQL service containers
   - But **no Redis service containers**
   - Backend couldn't connect to Redis on startup → **test failures**

## Solution

Added **Redis 7.2 service containers** to all GitHub Actions jobs that run backend code.

### Jobs Modified

1. ✅ **test-backend-unit** - Backend unit tests
2. ✅ **test-backend-integration** - Backend integration tests with MySQL
3. ✅ **test-frontend-e2e** - E2E tests with backend server startup

## Changes Made

### 1. Backend Unit Tests Job

Added Redis service container:

```yaml
test-backend-unit:
  name: Backend Unit Tests
  runs-on: ubuntu-latest
  needs: build-backend
  services:
    redis:
      image: redis:7.2
      options: >-
        --health-cmd="redis-cli ping"
        --health-interval=10s
        --health-timeout=5s
        --health-retries=5
      ports:
        - 6379:6379
  steps:
    # ... existing steps ...
    - name: Run unit tests with coverage
      run: |
        cd main_backend
        mvn test jacoco:report -Dspring.profiles.active=test
      env:
        SPRING_PROFILES_ACTIVE: test
        SPRING_DATA_REDIS_HOST: localhost
        SPRING_DATA_REDIS_PORT: 6379
```

### 2. Backend Integration Tests Job

Added Redis service alongside MySQL:

```yaml
test-backend-integration:
  name: Backend Integration Tests
  runs-on: ubuntu-latest
  needs: test-backend-unit
  services:
    mysql:
      image: mysql:8.0
      # ... mysql config ...
    redis:
      image: redis:7.2
      options: >-
        --health-cmd="redis-cli ping"
        --health-interval=10s
        --health-timeout=5s
        --health-retries=5
      ports:
        - 6379:6379
  steps:
    # ... existing steps ...
    - name: Run integration tests
      run: |
        cd main_backend
        mvn verify -Dspring.profiles.active=test -Dtest=*IntegrationTest
      env:
        SPRING_DATASOURCE_URL: jdbc:mysql://127.0.0.1:3306/concert_db
        SPRING_DATASOURCE_USERNAME: root
        SPRING_DATASOURCE_PASSWORD: rootpass
        SPRING_DATASOURCE_DRIVER_CLASS_NAME: com.mysql.cj.jdbc.Driver
        SPRING_JPA_DATABASE_PLATFORM: org.hibernate.dialect.MySQLDialect
        SPRING_DATA_REDIS_HOST: localhost
        SPRING_DATA_REDIS_PORT: 6379
```

### 3. Frontend E2E Tests Job

Added Redis for backend server startup:

```yaml
test-frontend-e2e:
  name: Frontend E2E Tests
  runs-on: ubuntu-latest
  needs: [build-backend, build-frontend, test-frontend-unit]
  services:
    mysql:
      image: mysql:8.0
      # ... mysql config ...
    redis:
      image: redis:7.2
      options: >-
        --health-cmd="redis-cli ping"
        --health-interval=10s
        --health-timeout=5s
        --health-retries=5
      ports:
        - 6379:6379
  steps:
    # ... existing steps ...
    - name: Start backend server
      run: |
        set -e
        cd main_backend
        echo "🚀 Starting backend server..."
        nohup mvn spring-boot:run -Dspring-boot.run.profiles=test > backend.log 2>&1 &
        BACKEND_PID=$!
        echo "BACKEND_PID=$BACKEND_PID" >> $GITHUB_ENV
        echo "✅ Backend started with PID: $BACKEND_PID"
        sleep 5
      env:
        SPRING_DATASOURCE_URL: jdbc:mysql://127.0.0.1:3306/concert_db
        SPRING_DATASOURCE_USERNAME: root
        SPRING_DATASOURCE_PASSWORD: rootpass
        SPRING_DATASOURCE_DRIVER_CLASS_NAME: com.mysql.cj.jdbc.Driver
        SPRING_JPA_DATABASE_PLATFORM: org.hibernate.dialect.MySQLDialect
        SPRING_JPA_HIBERNATE_DDL_AUTO: update
        SPRING_DATA_REDIS_HOST: localhost
        SPRING_DATA_REDIS_PORT: 6379
```

## Redis Service Configuration

### Image
- **Version:** `redis:7.2` (latest stable release)
- **Why:** Stable, well-tested, matches production Redis versions

### Health Check
```yaml
options: >-
  --health-cmd="redis-cli ping"
  --health-interval=10s
  --health-timeout=5s
  --health-retries=5
```

- **Command:** `redis-cli ping` returns `PONG` when Redis is ready
- **Interval:** Check every 10 seconds
- **Timeout:** 5 seconds per check
- **Retries:** 5 attempts before marking unhealthy

### Networking
```yaml
ports:
  - 6379:6379
```

- **Port:** 6379 (standard Redis port)
- **Host:** `localhost` or `127.0.0.1` in GitHub Actions
- **Access:** Backend connects via `SPRING_DATA_REDIS_HOST=localhost`

## Environment Variables Added

All backend test runs now include:

```yaml
env:
  SPRING_DATA_REDIS_HOST: localhost
  SPRING_DATA_REDIS_PORT: 6379
```

These override any default Redis connection settings and ensure the backend connects to the GitHub Actions service container.

## Why This Fix Works

### Spring Boot Auto-Configuration

When `spring-boot-starter-data-redis` is on the classpath:

1. Spring Boot auto-configures `RedisConnectionFactory`
2. Attempts to connect to Redis on application startup
3. Even if Redis repositories are disabled, connection is still initialized

### Test Profile Configuration

`src/test/resources/application-test.properties` has:

```properties
spring.data.redis.repositories.enabled=false
spring.cache.type=none
```

This disables:
- ✅ Redis repository support
- ✅ Redis-based caching

But does **NOT** disable:
- ❌ Redis connection auto-configuration
- ❌ RedisConnectionFactory initialization

### Solution

By providing a **real Redis service** in CI:
- ✅ Spring Boot successfully connects to Redis
- ✅ Connection factory initializes properly
- ✅ Tests run without connection errors
- ✅ Backend server starts successfully for E2E tests

## Testing Strategy

### Local Development

For local development without Redis:

**Option 1: Run Redis locally**
```bash
docker run -d -p 6379:6379 redis:7.2
```

**Option 2: Exclude Redis auto-configuration**

Add to test class:
```java
@SpringBootTest(
    properties = {
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration"
    }
)
```

**Option 3: Use embedded Redis (test dependency)**

Not recommended for this project as it adds complexity.

### CI/CD Environment

✅ **GitHub Actions** - Redis service container (implemented)
✅ **Docker Compose** - Redis service defined (if used)
✅ **Kubernetes** - Redis pod/service (if deployed)

## Expected Outcomes

With Redis services added:

1. ✅ **Backend Unit Tests** - Pass without Redis connection errors
2. ✅ **Backend Integration Tests** - Successfully connect to both MySQL and Redis
3. ✅ **Frontend E2E Tests** - Backend server starts cleanly with MySQL and Redis
4. ✅ **Pipeline Success** - All jobs complete successfully

## Related Files

- **Workflow:** `.github/workflows/full-pipeline.yml`
- **Backend POM:** `main_backend/pom.xml` (contains Redis dependency)
- **Test Config:** `main_backend/src/test/resources/application-test.properties`

## Verification

### Check Service Health

In GitHub Actions logs, look for:

```
Creating redis service containers...
Waiting for service containers to start...
Starting service containers...
redis service container started
```

### Check Backend Startup

Backend logs should **NOT** show:

```
❌ Unable to connect to Redis
❌ RedisConnectionFailureException
```

Backend logs **SHOULD** show:

```
✅ Started ConcertApplication in X.XXX seconds
✅ Backend started with PID: XXXXX
```

### Check Test Execution

Unit/integration tests should complete without Redis-related failures.

## Architecture Notes

### Why Redis is a Dependency

Redis is likely included for:
- Session management (distributed sessions)
- Caching (application-level caching)
- Rate limiting (API throttling)
- Real-time features (pub/sub messaging)

Even if not actively used in tests, the dependency causes auto-configuration.

### Future Optimization

Consider these improvements:

1. **Profile-based exclusion:**
   ```properties
   # application-test.properties
   spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration
   ```

2. **Conditional beans:**
   ```java
   @ConditionalOnProperty(name = "redis.enabled", havingValue = "true")
   ```

3. **Test containers:**
   Use Testcontainers for Redis in integration tests instead of service containers

## Lessons Learned

1. **Dependency presence != active usage**
   - Just having `spring-boot-starter-data-redis` triggers auto-config
   - Disabling repositories doesn't prevent connection attempts

2. **Service containers are essential**
   - CI environments need all services the app expects
   - Even if disabled in test profiles, connections are attempted

3. **Health checks matter**
   - Always configure health checks for service containers
   - Ensures services are ready before tests run

4. **Environment variables override defaults**
   - Explicit `SPRING_DATA_REDIS_HOST` ensures correct connection
   - Better than relying on default localhost behavior

---

**Pipeline Status:** 🔄 Running  
**Expected Result:** ✅ All backend tests pass with Redis connectivity  
**GitHub Actions:** https://github.com/MorningMores/develop/actions

## Next Steps

1. ✅ Monitor pipeline run for success
2. ⏳ Verify no more Redis connection errors
3. ⏳ Confirm all test jobs complete successfully
4. 📝 Consider adding Redis to docker-compose for local dev parity
