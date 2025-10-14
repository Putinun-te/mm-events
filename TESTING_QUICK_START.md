# Testing Quick Start Guide

This guide helps you quickly run tests locally and understand the testing strategy.

## 🚀 Quick Commands

### Run Unit Tests (Fast, No Docker Needed)

**Backend:**
```powershell
.\run-unit-tests.ps1
```
Or manually:
```powershell
cd main_backend
mvn test -P unit-tests
```

**Frontend:**
```powershell
.\run-frontend-tests.ps1
```
Or manually:
```powershell
cd main_frontend/concert1
npm run test
```

### Run All Tests with Coverage

```powershell
.\run-all-tests.ps1
```

This runs:
1. Backend unit tests
2. Backend integration tests (if Docker is running)
3. Frontend unit tests
4. Generates coverage reports

### Run Integration Tests (Requires Docker)

```powershell
.\run-integration-tests.ps1
```

### Run E2E Tests (Requires Running Servers)

**Backend E2E:**
```powershell
# Terminal 1: Start backend
cd main_backend
mvn spring-boot:run

# Terminal 2: Run E2E tests
.\run-backend-e2e.ps1
```

**Frontend E2E:**
```powershell
# Terminal 1: Start backend
cd main_backend
mvn spring-boot:run

# Terminal 2: Start frontend
cd main_frontend/concert1
npm run dev

# Terminal 3: Run E2E tests
.\run-frontend-e2e.ps1
```

## 📊 Coverage Reports

After running tests with coverage, view reports at:

- **Backend:** `main_backend/target/site/jacoco/index.html`
- **Frontend:** `main_frontend/concert1/coverage/index.html`

**Coverage Requirements:** 80% line and branch coverage

## 🎯 Testing Levels

### 1. Unit Tests → Maven (Local)
- **What:** Test individual components in isolation
- **When:** Run before every commit
- **Speed:** Fast (< 30 seconds)
- **Requirements:** None (no Docker needed)

### 2. Integration Tests → GitHub Actions (CI/CD)
- **What:** Test component interactions with real databases
- **When:** Automatically run on push/PR
- **Speed:** Medium (2-5 minutes)
- **Requirements:** Docker (for Testcontainers)

### 3. E2E Tests → Cypress (Full Stack)
- **What:** Test complete user workflows
- **When:** Run before releases, part of CI/CD
- **Speed:** Slower (5-10 minutes)
- **Requirements:** Running backend + frontend servers

## 🔧 Prerequisites

### Backend Tests
- **JDK 21** (required for tests)
- **Maven** (bundled with project via `mvnw`)
- **Docker Desktop** (only for integration tests)

### Frontend Tests
- **Node.js 20+**
- **npm**

## 📁 Project Structure

```
develop/
├── main_backend/
│   ├── src/test/java/          # All test files
│   │   ├── **/*Test.java       # Unit tests
│   │   ├── **/*IntegrationTest.java  # Integration tests
│   │   └── **/*DockerTest.java # Docker-based tests
│   ├── cypress-tests/          # Backend E2E tests
│   └── pom.xml                 # Maven config with test profiles
│
├── main_frontend/concert1/
│   ├── test/                   # Unit tests
│   ├── cypress/e2e/            # Frontend E2E tests
│   ├── vitest.config.ts        # Test configuration
│   └── package.json            # Test scripts
│
├── .github/workflows/          # CI/CD pipelines
│   ├── backend-integration-tests.yml
│   ├── backend-e2e-tests.yml
│   ├── frontend-tests.yml
│   └── frontend-e2e.yml
│
└── Test Runner Scripts (this level):
    ├── run-unit-tests.ps1
    ├── run-integration-tests.ps1
    ├── run-backend-e2e.ps1
    ├── run-frontend-tests.ps1
    ├── run-frontend-e2e.ps1
    └── run-all-tests.ps1
```

## 🐛 Troubleshooting

### Backend: "Unsupported class file major version 68"
**Solution:** Ensure JDK 21 is being used (scripts handle this automatically)

### Backend: "Could not connect to Docker"
**Solution:** Start Docker Desktop before running integration tests

### Frontend: "Module not found"
**Solution:** Run `npm install` in `main_frontend/concert1`

### Cypress: "Timed out waiting for..."
**Solution:** Ensure backend/frontend servers are running and accessible

## 📖 Full Documentation

For comprehensive testing strategy, see: **[TESTING_STRATEGY.md](TESTING_STRATEGY.md)**

## 🎬 Typical Workflow

### Development (Daily)
```powershell
# 1. Write code
# 2. Run unit tests
.\run-unit-tests.ps1        # Backend
.\run-frontend-tests.ps1    # Frontend

# 3. Fix any failures
# 4. Commit
```

### Before Pull Request
```powershell
# 1. Run all tests
.\run-all-tests.ps1

# 2. Review coverage reports
# 3. Ensure > 80% coverage
# 4. Create PR (GitHub Actions will run integration + E2E tests)
```

### Before Release
```powershell
# 1. Start servers
# Terminal 1: Backend
cd main_backend ; mvn spring-boot:run

# Terminal 2: Frontend  
cd main_frontend/concert1 ; npm run dev

# Terminal 3: Run E2E tests
.\run-backend-e2e.ps1
.\run-frontend-e2e.ps1

# 2. Verify all pass
# 3. Deploy
```

## ✅ What Gets Tested

### Backend Unit Tests
- ✓ Service layer logic (AuthService, BookingService, EventService)
- ✓ JWT token generation and validation
- ✓ Security filters and authentication
- ✓ DTOs and model validation
- ✓ Controller endpoints (with mocked services)

### Backend Integration Tests
- ✓ Full database operations (with Testcontainers)
- ✓ Repository layer with real MySQL
- ✓ Complete API flows (register → login → book)
- ✓ Transaction management

### Backend E2E Tests (Cypress)
- ✓ Auth API (register, login, test endpoint)
- ✓ Events API (list, search, get details)
- ✓ Bookings API (create, list, cancel)

### Frontend Unit Tests
- ✓ Vue components (Login, Register, EventList)
- ✓ Composables and utilities
- ✓ State management

### Frontend E2E Tests (Cypress)
- ✓ User authentication flow
- ✓ Event browsing and booking
- ✓ Booking cancellation
- ✓ Complete user journeys

## 🎯 CI/CD Pipeline

When you push code:

1. **GitHub Actions** automatically triggers
2. **Unit tests** run first (fast feedback)
3. **Integration tests** run with MySQL
4. **E2E tests** run full stack
5. **Coverage reports** uploaded
6. **PR blocked** if tests fail or coverage < 80%

## 💡 Tips

- ✅ **Run unit tests frequently** - They're fast and catch most issues
- ✅ **Let CI handle integration tests** - They require Docker
- ✅ **Use E2E for critical paths** - Don't over-test with E2E
- ✅ **Maintain 80%+ coverage** - Quality over quantity
- ✅ **Review coverage gaps** - Use HTML reports to find uncovered code

## 🔗 Related Documentation

- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) - Comprehensive testing guide
- [BACKEND_TESTING_QUICK_START.md](BACKEND_TESTING_QUICK_START.md) - Backend-specific guide
- [Copilot Instructions](.github/copilot-instructions.md) - AI agent context
