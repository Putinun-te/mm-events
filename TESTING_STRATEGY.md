# Testing Strategy

This document outlines the complete testing strategy for the Concert Booking Platform.

## Testing Levels

### 1. Unit Tests (Maven - Local Development)

**Purpose:** Test individual components in isolation without external dependencies.

**Backend:**
- **Location:** `main_backend/src/test/java/**/*Test.java`
- **Excludes:** `*IntegrationTest.java`, `*DockerTest.java`
- **Run Command:**
  ```powershell
  cd main_backend
  mvn test -P unit-tests
  ```
- **Examples:**
  - `AuthServiceTest.java` - Service logic tests with mocked repositories
  - `JwtServiceTest.java` - JWT token generation and validation
  - `UserTest.java` - Model validation and business logic
  - `AuthControllerTest.java` - Controller layer with mocked services

**Frontend:**
- **Location:** `main_frontend/concert1/test/**/*.test.ts`
- **Framework:** Vitest with Testing Library
- **Run Command:**
  ```powershell
  cd main_frontend/concert1
  npm run test
  ```
- **Coverage Command:**
  ```powershell
  npm run test:coverage
  ```
- **Examples:**
  - Component tests (Login.vue, Register.vue)
  - Composable tests
  - Utility function tests

**Requirements:**
- ✅ No external dependencies (database, Docker)
- ✅ Fast execution (< 30 seconds total)
- ✅ Mockito for backend, vitest mocks for frontend
- ✅ Run before every commit

---

### 2. Integration Tests (GitHub Actions - CI/CD)

**Purpose:** Test component interactions with real databases and external services.

**Backend:**
- **Location:** `main_backend/src/test/java/**/*IntegrationTest.java`, `**/*DockerTest.java`
- **Run Command (Local):**
  ```powershell
  cd main_backend
  mvn verify -P integration-tests
  ```
- **Run Command (GitHub Actions):** Automatically triggered on push/PR
- **Requirements:**
  - 🐳 Docker Desktop running (for Testcontainers)
  - 🗄️ MySQL container (via Testcontainers or docker-compose)
- **Examples:**
  - `AuthIntegrationTest.java` - Full auth flow with real database
  - `BookingIntegrationTest.java` - Booking operations with MySQL
  - `UserRepositoryDockerTest.java` - Repository tests with Testcontainers

**Frontend:**
- **Workflow:** `.github/workflows/frontend-tests.yml`
- **Triggers:** Push to `main`, `FE-tester` branches
- **Jobs:**
  1. Unit tests with coverage
  2. Type checking
  3. E2E tests (Cypress)

**GitHub Actions Workflows:**

1. **Backend Integration Tests** (`.github/workflows/backend-integration-tests.yml`)
   - Runs on: `main`, `BE-Tester`, `develop` branches
   - Sets up MySQL service
   - Runs all tests with JaCoCo coverage
   - Enforces 80% coverage threshold
   - Uploads artifacts: coverage reports, test results

2. **Frontend Tests** (`.github/workflows/frontend-tests.yml`)
   - Runs on: `main`, `FE-tester` branches
   - Jobs: unit tests, lint, type check, E2E

---

### 3. E2E Coverage (Cypress - End-to-End)

**Purpose:** Test complete user workflows across the entire application stack.

**Backend E2E:**
- **Location:** `main_backend/cypress-tests/cypress/e2e/`
- **Config:** `main_backend/cypress-tests/cypress.config.js`
- **Run Command (Local):**
  ```powershell
  # Start backend server first
  cd main_backend
  mvn spring-boot:run
  
  # In another terminal
  cd main_backend/cypress-tests
  npm install
  npm run test:e2e
  ```
- **Run Command (Headless):**
  ```powershell
  npm run test:e2e:headless
  ```
- **GitHub Actions:** `.github/workflows/backend-e2e-tests.yml`
  - Starts MySQL service
  - Builds and runs backend
  - Executes Cypress tests
  - Uploads videos/screenshots on failure

**Frontend E2E:**
- **Location:** `main_frontend/concert1/cypress/e2e/`
- **Config:** `main_frontend/concert1/cypress.config.ts`
- **Run Command (Local):**
  ```powershell
  # Start backend and frontend
  cd main_frontend/concert1
  npm run dev
  
  # In another terminal
  npm run test:e2e
  ```
- **GitHub Actions:** `.github/workflows/frontend-e2e.yml`
  - Starts full stack (MySQL + backend + frontend)
  - Runs Cypress tests against running app
  - Uploads artifacts

**E2E Test Suites:**
- 🔐 Authentication flows (login, register, logout)
- 📅 Event browsing and searching
- 🎫 Booking creation and cancellation
- 👤 User account management
- 🔄 Full user journeys (browse → book → cancel)

---

## Quick Reference Commands

### Backend

```powershell
# Unit tests only (fast, no Docker needed)
mvn test -P unit-tests

# Integration tests only (requires Docker)
mvn verify -P integration-tests

# All tests with coverage
mvn clean test jacoco:report

# All tests with coverage (JDK 21 on Windows)
$env:JAVA_HOME="C:\Program Files\Java\jdk-21"; mvn clean test jacoco:report

# Run Spring Boot app
mvn spring-boot:run
```

### Frontend

```powershell
# Unit tests
npm run test

# Unit tests with coverage
npm run test:coverage

# Watch mode (for development)
npm run test:watch

# E2E tests (requires backend running)
npm run test:e2e

# E2E headless
npm run test:e2e:headless

# All tests
npm run test:all
```

---

## Coverage Requirements

### Backend (JaCoCo)
- **Minimum Line Coverage:** 80%
- **Minimum Branch Coverage:** 80%
- **Report Location:** `main_backend/target/site/jacoco/index.html`
- **Configuration:** `pom.xml` (JaCoCo plugin)

### Frontend (Vitest)
- **Minimum Coverage:** 80% (configured in `vitest.config.ts`)
- **Report Location:** `main_frontend/concert1/coverage/index.html`
- **Configuration:** `vitest.config.ts`

---

## GitHub Actions Workflow Summary

| Workflow | Trigger | Purpose | Duration |
|----------|---------|---------|----------|
| `backend-ci.yml` | Push to `main`, `FE-Testing`, `BE-Tester` | Build & test in Docker | ~5 min |
| `backend-integration-tests.yml` | Push to `main`, `BE-Tester`, `develop` | Integration tests with MySQL | ~3 min |
| `backend-e2e-tests.yml` | Push/PR to `main`, `BE-Tester`, `develop` | Cypress E2E tests | ~5 min |
| `frontend-tests.yml` | Push/PR to `main`, `FE-tester` | Unit + E2E tests | ~4 min |
| `frontend-e2e.yml` | Push to `main`, `FE-Testing` | Full stack E2E | ~5 min |

---

## Test Execution Flow

### Local Development (Unit Tests)
```
1. Write code
2. Run unit tests: mvn test -P unit-tests (backend) or npm run test (frontend)
3. Fix failures
4. Commit code
```

### Pull Request (Integration Tests)
```
1. Create PR
2. GitHub Actions runs integration tests automatically
3. Review coverage reports
4. Fix failures before merge
```

### Pre-Production (E2E Tests)
```
1. Merge to develop/main
2. GitHub Actions runs full E2E suite
3. Cypress validates complete workflows
4. Deploy if all tests pass
```

---

## Troubleshooting

### Backend Tests Failing

**Issue:** `Unsupported class file major version 68`
**Solution:** Ensure JDK 21 is being used:
```powershell
$env:JAVA_HOME="C:\Program Files\Java\jdk-21"
mvn clean test
```

**Issue:** Testcontainers tests failing
**Solution:** Ensure Docker Desktop is running
```powershell
docker ps  # Should list containers
```

**Issue:** Coverage below 80%
**Solution:** Check JaCoCo report at `target/site/jacoco/index.html` for uncovered lines

### Frontend Tests Failing

**Issue:** Module not found errors
**Solution:** Clean install dependencies
```powershell
rm -r node_modules
npm install
```

**Issue:** Cypress tests timeout
**Solution:** Ensure backend is running and accessible
```powershell
curl http://localhost:8080/actuator/health
curl http://localhost:3000/concert
```

---

## Best Practices

1. **Write unit tests first** - They're fast and catch most bugs
2. **Run unit tests before committing** - Keep the build green
3. **Let CI run integration tests** - They require Docker and take longer
4. **Use E2E tests for critical flows** - Don't over-test with E2E
5. **Maintain 80%+ coverage** - Quality over quantity
6. **Mock external dependencies in unit tests** - Keep tests isolated
7. **Use real databases in integration tests** - Catch real-world issues

---

## Files to Review

### Backend
- `pom.xml` - Maven configuration with test profiles
- `main_backend/src/test/java/` - All test files
- `main_backend/cypress-tests/` - E2E tests

### Frontend
- `package.json` - NPM scripts for testing
- `vitest.config.ts` - Vitest configuration
- `cypress.config.ts` - Cypress configuration
- `test/` - Unit tests
- `cypress/e2e/` - E2E tests

### CI/CD
- `.github/workflows/backend-*.yml` - Backend workflows
- `.github/workflows/frontend-*.yml` - Frontend workflows
