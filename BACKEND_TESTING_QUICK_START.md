# Backend Testing Quick Start Guide

## Prerequisites

- JDK 21 installed
- Maven 3.8+ (or use `mvnw` wrapper)
- Docker Desktop running (for integration tests)
- Node.js 20+ and npm (for E2E tests)

## Quick Test Commands

### 1. Run All Unit Tests (Fastest)
```bash
cd main_backend
./mvnw test
```
⏱️ **Time:** ~30-60 seconds  
📊 **Coverage:** Included in report

### 2. Run Tests with Coverage Report
```bash
cd main_backend
./mvnw clean test jacoco:report
```
📄 **Report Location:** `main_backend/target/site/jacoco/index.html`  
✅ **Threshold:** 80% line and branch coverage

### 3. View Coverage Report
**Windows:**
```powershell
start main_backend/target/site/jacoco/index.html
```

**macOS/Linux:**
```bash
open main_backend/target/site/jacoco/index.html
```

### 4. Run Integration Tests Only
```bash
cd main_backend
./mvnw test -Dtest="*IntegrationTest"
```
⏱️ **Time:** ~2-3 minutes  
🐳 **Requires:** Docker running

### 5. Run E2E Tests with Cypress

**Step 1:** Start backend server
```bash
cd main_backend
./mvnw spring-boot:run
```

**Step 2:** In a new terminal, run Cypress
```bash
cd main_backend/cypress-tests
npm install
npm run test:e2e
```
⏱️ **Time:** ~3-5 minutes  
🎥 **Outputs:** Videos and screenshots in `cypress/` folders

### 6. Run Specific Test Suites

**Controller Tests:**
```bash
./mvnw test -Dtest="*ControllerUnitTest"
```

**Service Tests:**
```bash
./mvnw test -Dtest="*ServiceTest"
```

**Auth E2E Tests:**
```bash
cd main_backend/cypress-tests
npm run test:e2e:auth
```

**Events E2E Tests:**
```bash
npm run test:e2e:events
```

**Bookings E2E Tests:**
```bash
npm run test:e2e:bookings
```

## Verify Coverage Meets 80% Threshold

```bash
cd main_backend
./mvnw clean test jacoco:report jacoco:check
```

✅ **Success:** Build passes with 80%+ coverage  
❌ **Failure:** Build warns if coverage < 80%

## GitHub Actions (Automated)

All tests run automatically when you push to:
- `main`
- `BE-Tester`
- `develop`

### View Results:
1. Go to GitHub repository
2. Click "Actions" tab
3. Select latest workflow run
4. Download artifacts (coverage reports, videos, etc.)

## Test Coverage Summary

| Component | Unit Tests | Integration Tests | E2E Tests |
|-----------|-----------|-------------------|-----------|
| Auth | ✅ | ✅ | ✅ |
| Events | ✅ | ✅ | ✅ |
| Bookings | ✅ | ✅ | ✅ |
| JWT Service | ✅ | ✅ | ✅ |
| Controllers | ✅ | ✅ | ✅ |

## Troubleshooting

### Tests Fail with "Cannot connect to database"
**Solution:** Ensure Docker is running and MySQL container is up
```bash
docker ps | grep mysql
```

### E2E Tests Fail with "Connection refused"
**Solution:** Ensure backend is running on port 8080
```bash
curl http://localhost:8080/actuator/health
```

### Maven wrapper not executable
**Windows:**
```powershell
cd main_backend
.\mvnw.cmd test
```

**macOS/Linux:**
```bash
chmod +x mvnw
./mvnw test
```

### Out of memory errors
**Solution:** Increase Maven memory
```bash
export MAVEN_OPTS="-Xmx2048m"
./mvnw test
```

## Files Created/Modified

### New Test Files
- `EventControllerUnitTest.java`
- `BookingControllerUnitTest.java`
- `EventServiceTest.java` (enhanced)
- `BookingServiceTest.java` (enhanced)
- `EventIntegrationTest.java`
- `BookingIntegrationTest.java`

### New E2E Test Files
- `cypress/e2e/auth/auth-api.cy.js`
- `cypress/e2e/events/events-api.cy.js`
- `cypress/e2e/bookings/bookings-api.cy.js`

### Configuration Files
- `pom.xml` (updated coverage to 80%)
- `.github/workflows/backend-integration-tests.yml` (new)
- `.github/workflows/backend-e2e-tests.yml` (new)
- `.github/workflows/backend-ci.yml` (updated)
- `cypress-tests/cypress.config.js` (new)
- `cypress-tests/package.json` (new)

## Documentation
- `BACKEND_TESTING_SUMMARY.md` - Complete testing documentation
- `main_backend/cypress-tests/README.md` - Cypress setup guide

## Next Steps

1. ✅ Run all tests locally to verify
2. ✅ Push to BE-Tester branch
3. ✅ Verify GitHub Actions pass
4. ✅ Review coverage reports
5. ✅ Merge with main (when ready)
6. ✅ Merge with FE-Tester (no conflicts expected)

## Support

For detailed information, see:
- **Complete Guide:** `BACKEND_TESTING_SUMMARY.md`
- **Cypress Guide:** `main_backend/cypress-tests/README.md`
- **Coverage Copilot Instructions:** `.github/copilot-instructions.md`

---

**Target:** 80%+ code coverage ✅  
**Status:** All tests implemented and ready 🚀  
**Branch:** BE-Tester
