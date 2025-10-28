# Frontend & Backend Testing Strategy

> **Unified 3-Layer Testing Approach**  
> Unit → Integration → E2E for both Frontend and Backend

---

## 🎯 Testing Layers

```
┌─────────────────────────────────────────┐
│         LAYER 1: UNIT TESTS             │
│  Frontend: Vitest (npm test)            │
│  Backend: Maven (mvn test)              │
│  ✓ Fast, isolated, no external deps     │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│    LAYER 2: INTEGRATION TESTS           │
│  Frontend: API calls to backend         │
│  Backend: Testcontainers + MySQL        │
│  ✓ GitHub Actions with services         │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│       LAYER 3: E2E TESTS                │
│  Full Stack: Docker Compose             │
│  E2E Coverage: Cypress                  │
│  ✓ Real user flows, complete system     │
└─────────────────────────────────────────┘
```

---

## 📦 Frontend Testing

### Unit Tests (npm test)
- **Framework**: Vitest + Testing Library
- **Files**: `**/*.test.ts`, `**/*.test.js`
- **Coverage**: 90%+ (570 tests)
- **Speed**: ~7-8 seconds
- **Run**: `npm test`

**What's tested**:
- ✅ Component logic (Login, Register, Booking)
- ✅ Vue composables
- ✅ Utils and helpers
- ✅ Form validation
- ❌ No API calls (mocked)
- ❌ No real backend

### Integration Tests (GitHub Actions)
- **Framework**: GitHub Actions with MySQL service
- **What's tested**:
  - Frontend makes real API calls
  - Backend responds with MySQL
  - Auth flow (login/register)
  - Data persistence

### E2E Tests (Cypress)
- **Framework**: Cypress
- **Files**: `cypress/e2e/**/*.cy.ts`
- **Coverage**: E2E flow coverage
- **Run**: `npm run test:e2e`

**What's tested**:
- ✅ Complete user journeys
- ✅ Login → Browse → Book → Logout
- ✅ Multi-page flows
- ✅ Real browser interactions

---

## ⚙️ Backend Testing

### Unit Tests (Maven)
- **Framework**: JUnit 5 + Mockito
- **Files**: `*Test.java` (excludes `*DockerTest`, `*IntegrationTest`)
- **Coverage**: 96% (228 tests)
- **Speed**: ~45 seconds
- **Run**: `mvn test -Dtest='!*DockerTest,!*IntegrationTest'`

**What's tested**:
- ✅ Service layer logic
- ✅ Controller endpoints (MockMvc)
- ✅ DTOs and validation
- ✅ Security filters
- ❌ No real database (H2 or mocks)
- ❌ No Testcontainers

### Integration Tests (Testcontainers)
- **Framework**: Testcontainers + MySQL
- **Files**: `*DockerTest.java`, `*IntegrationTest.java`
- **Run**: `mvn test -Dtest='*DockerTest,*IntegrationTest'`

**What's tested**:
- ✅ Real MySQL database
- ✅ Repository layer
- ✅ Full Spring context
- ✅ Transaction management
- ✅ Data persistence

### E2E Tests (Part of Cypress)
- Backend participates in full-stack E2E
- Real API endpoints tested via Cypress

---

## 🚀 Quick Reference

### Run Frontend Tests Locally

```bash
cd main_frontend/concert1

# Unit tests (fast)
npm test                    # 570 tests, ~7s

# Unit tests with coverage
npm run test:coverage       # 90%+ coverage

# Watch mode (development)
npm run test:watch

# E2E tests (requires backend)
docker-compose up -d mysql backend
npm run dev &
npm run test:e2e
```

### Run Backend Tests Locally

```bash
cd main_backend

# Unit tests only (fast, no Docker)
JAVA_HOME=$(/usr/libexec/java_home -v 21) \
  mvn test -Dtest='!*DockerTest,!*IntegrationTest'

# Integration tests (requires Docker)
JAVA_HOME=$(/usr/libexec/java_home -v 21) \
  mvn -DforkCount=1 -DreuseForks=false test \
  -Dtest='*DockerTest,*IntegrationTest'

# All tests
JAVA_HOME=$(/usr/libexec/java_home -v 21) \
  mvn clean test

# With coverage
JAVA_HOME=$(/usr/libexec/java_home -v 21) \
  mvn clean test jacoco:report
```

---

## 🔄 GitHub Actions Workflows

### 1. Unit Tests (`unit-tests.yml`)
**Runs on**: Every code push/PR  
**Duration**: ~2-3 minutes

```yaml
jobs:
  frontend-unit-tests:
    - npm ci
    - npm test
    - npm run test:coverage
  
  backend-unit-tests:
    - mvn test (exclude Docker/Integration)
    - jacoco:report
```

### 2. Integration Tests (`integration-tests.yml`)
**Runs on**: Backend/database changes  
**Duration**: ~8-12 minutes

```yaml
jobs:
  backend-integration-tests:
    - Testcontainers + MySQL
    - mvn test (only *DockerTest, *IntegrationTest)
  
  frontend-backend-integration:
    services: [MySQL]
    - Build & start backend
    - Test API endpoints
```

### 3. E2E Tests (`e2e-tests.yml`)
**Runs on**: Frontend + Backend changes  
**Duration**: ~15-25 minutes

```yaml
jobs:
  e2e-cypress:
    - Docker Compose (MySQL + Backend)
    - Nuxt dev server
    - Cypress E2E tests
    - Coverage report
```

---

## 📊 Test Organization

### Frontend Test Files
```
main_frontend/concert1/
├── __tests__/
│   ├── components/
│   │   ├── Login.test.ts          # Unit
│   │   ├── Register.test.ts       # Unit
│   │   └── Booking.test.ts        # Unit
│   └── pages/
│       └── index.test.ts          # Unit
├── cypress/
│   └── e2e/
│       ├── login.cy.ts            # E2E
│       ├── booking.cy.ts          # E2E
│       └── checkout.cy.ts         # E2E
└── vitest.config.ts
```

### Backend Test Files
```
main_backend/src/test/java/com/concert/
├── controller/
│   ├── AuthControllerTest.java          # Unit
│   └── BookingControllerTest.java       # Unit
├── service/
│   ├── AuthServiceTest.java             # Unit
│   └── BookingServiceTest.java          # Unit
├── repository/
│   ├── UserRepositoryDockerTest.java    # Integration
│   └── BookingRepositoryDockerTest.java # Integration
└── integration/
    └── FullStackIntegrationTest.java    # Integration
```

---

## ✅ Test Checklist

### Before Committing
- [ ] Run `npm test` (frontend unit)
- [ ] Run `mvn test -Dtest='!*DockerTest,!*IntegrationTest'` (backend unit)
- [ ] Verify tests pass locally

### Before Merging PR
- [ ] All unit tests pass (GitHub Actions)
- [ ] All integration tests pass (GitHub Actions)
- [ ] E2E tests pass (if frontend/backend changed)
- [ ] Coverage requirements met (90% frontend, 85% backend)

---

## 🎯 Coverage Goals

| Test Layer | Frontend | Backend |
|------------|----------|---------|
| Unit | ≥90% ✅ | ≥85% ✅ |
| Integration | ≥80% 🔄 | ≥80% 🔄 |
| E2E | ≥70% 🔄 | N/A |

---

## 🐛 Common Issues

### Frontend Tests Fail Locally
```bash
# Clear cache
rm -rf node_modules coverage .nuxt
npm install
npm test
```

### Backend Tests Fail (Docker)
```bash
# Ensure Docker is running
docker ps

# Check Testcontainers
docker pull mysql:8.0

# Use correct JDK
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
java -version
```

### E2E Tests Timeout
```bash
# Check backend health
curl http://localhost:8080/actuator/health

# Check logs
docker-compose logs backend

# Restart clean
docker-compose down -v
docker-compose up -d mysql backend
```

---

## 📚 Testing Commands Summary

| Command | Purpose | Duration |
|---------|---------|----------|
| `npm test` | Frontend unit tests | 7-8s |
| `npm run test:coverage` | Frontend coverage | 8-10s |
| `npm run test:e2e` | Cypress E2E | 30-60s |
| `mvn test -Dtest='!*Docker*,!*Integration*'` | Backend unit | 45s |
| `mvn test -Dtest='*Docker*,*Integration*'` | Backend integration | 2-3min |
| `mvn clean test jacoco:report` | Full backend + coverage | 3-4min |

---

**Last Updated**: October 16, 2025  
**Status**: ✅ Active and enforced in CI/CD
