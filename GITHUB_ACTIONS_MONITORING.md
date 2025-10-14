# GitHub Actions Test Monitoring Guide

## 🎯 Your Testing Strategy (Now Live!)

✅ **Unit Tests** → Maven (local development)  
✅ **Integration Tests** → GitHub Actions (CI/CD)  
✅ **E2E Coverage** → Cypress (full stack validation)

## 📍 Current Status

**Branch:** Tester  
**Commit:** 1c79d30  
**Pushed:** October 14, 2025

## 🔍 Monitor GitHub Actions

### Quick Links

**Main Actions Page:**  
https://github.com/MorningMores/develop/actions

**Workflows Triggered:**
1. **Backend Integration Tests** - https://github.com/MorningMores/develop/actions/workflows/backend-integration-tests.yml
2. **Backend CI** - https://github.com/MorningMores/develop/actions/workflows/backend-ci.yml
3. **Backend E2E Tests** - https://github.com/MorningMores/develop/actions/workflows/backend-e2e-tests.yml

## ✅ What to Expect

### 1. Backend Integration Tests Workflow

**File:** `.github/workflows/backend-integration-tests.yml`

#### Jobs Running:

**Job 1: integration-tests**
```yaml
Steps:
✓ Checkout code
✓ Set up JDK 21
✓ Setup MySQL service
✓ Wait for MySQL to be ready
✓ Run all tests with coverage (NEW)
  → mvn clean test jacoco:report -B -Djacoco.haltOnFailure=false
✓ Run integration tests (NEW)
  → mvn verify -P integration-tests -B
✓ Check coverage threshold (80%)
✓ Upload JaCoCo coverage report
✓ Upload test results
✓ Publish test report
```

**Job 2: unit-tests**
```yaml
Steps:
✓ Checkout code
✓ Set up JDK 21
✓ Run unit tests only (NEW)
  → mvn test -P unit-tests -B
✓ Upload unit test results
```

### 2. Backend CI Workflow

**File:** `.github/workflows/backend-ci.yml`

```yaml
Steps:
✓ Start MySQL in Docker
✓ Run backend tests in Docker
✓ Generate JaCoCo report
✓ Upload coverage artifacts
```

### 3. Backend E2E Tests Workflow (If Triggered)

**File:** `.github/workflows/backend-e2e-tests.yml`

```yaml
Steps:
✓ Setup MySQL service
✓ Build backend
✓ Start backend server
✓ Run Cypress E2E tests
  → Auth API tests
  → Events API tests
  → Bookings API tests
✓ Upload videos/screenshots
```

## 📊 Expected Test Results

### Unit Tests (Maven - Fast)
- **Location:** `main_backend/src/test/java/**/*Test.java`
- **Excludes:** `*IntegrationTest.java`, `*DockerTest.java`
- **Expected Duration:** ~30 seconds
- **Tests:**
  - ✓ AuthServiceTest
  - ✓ JwtServiceTest
  - ✓ UserTest
  - ✓ AuthControllerTest
  - ✓ BookingServiceTest
  - ✓ EventServiceTest
  - ✓ And more...

### Integration Tests (GitHub Actions)
- **Location:** `main_backend/src/test/java/**/*IntegrationTest.java`, `**/*DockerTest.java`
- **Expected Duration:** 2-5 minutes
- **Tests:**
  - ✓ AuthIntegrationTest
  - ✓ BookingIntegrationTest
  - ✓ EventIntegrationTest
  - ✓ UserRepositoryDockerTest
  - ✓ AuthDockerIntegrationTest
  - ✓ And more...

### E2E Tests (Cypress)
- **Location:** `main_backend/cypress-tests/cypress/e2e/`
- **Expected Duration:** 3-5 minutes
- **Test Suites:**
  - ✓ Auth API (register, login, test endpoint)
  - ✓ Events API (list, search, get details)
  - ✓ Bookings API (create, list, cancel)

## 🎨 GitHub Actions UI - What to Look For

### ✅ Success Indicators
```
✓ All checks have passed
✓ Green checkmarks on all jobs
✓ Coverage >= 80%
✓ All tests passed
✓ Artifacts uploaded successfully
```

### ⚠️ Warning Signs
```
⚠ Yellow warnings (non-blocking)
⚠ Coverage below threshold
⚠ Flaky tests
```

### ❌ Failure Indicators
```
✗ Red X marks on jobs
✗ Test failures
✗ Coverage below 80%
✗ Build failures
```

## 📦 Downloadable Artifacts

After workflow completion, you can download:

1. **JaCoCo Coverage Report** (`jacoco-report`)
   - HTML coverage report
   - View detailed coverage metrics
   - Identify uncovered code

2. **Surefire Reports** (`surefire-reports`)
   - Test execution results
   - Failure details
   - Test timings

3. **Cypress Videos** (`cypress-videos`) - If E2E runs
   - Video recordings of test execution
   - Useful for debugging failures

4. **Cypress Screenshots** (`cypress-screenshots`) - If failures occur
   - Screenshots at point of failure
   - Visual debugging aid

## 🔄 Workflow Status Badges

You can add these to your README.md:

```markdown
![Backend Integration Tests](https://github.com/MorningMores/develop/actions/workflows/backend-integration-tests.yml/badge.svg?branch=Tester)

![Backend CI](https://github.com/MorningMores/develop/actions/workflows/backend-ci.yml/badge.svg?branch=Tester)

![Backend E2E](https://github.com/MorningMores/develop/actions/workflows/backend-e2e-tests.yml/badge.svg?branch=Tester)
```

## 📈 Viewing Results

### In GitHub Actions UI

1. **Click on a workflow run**
2. **View the Summary:**
   - Overall status
   - Test counts
   - Coverage summary
   - Artifacts list

3. **Click on a job:**
   - View step-by-step execution
   - See command outputs
   - Check error messages

4. **Download artifacts:**
   - Click "Artifacts" section
   - Download coverage/test reports
   - Open HTML reports locally

### Command Line Monitoring

```powershell
# Check latest workflow status using GitHub CLI (if installed)
gh run list --branch Tester

# View specific workflow run
gh run view <run-id>

# Watch a workflow run
gh run watch <run-id>
```

## 🐛 Troubleshooting Failed Workflows

### If Unit Tests Fail

1. **Check the logs:**
   - Look for test failure messages
   - Check for compilation errors
   - Verify JDK version (should be 21)

2. **Run locally:**
   ```powershell
   .\run-unit-tests.ps1
   ```

3. **Common issues:**
   - Missing dependencies
   - JDK version mismatch
   - Code syntax errors

### If Integration Tests Fail

1. **Check MySQL service:**
   - Ensure service started successfully
   - Check connection logs
   - Verify credentials

2. **Check Testcontainers:**
   - Docker availability in GitHub runner
   - Container startup logs
   - Network connectivity

3. **Run locally (with Docker):**
   ```powershell
   .\run-integration-tests.ps1
   ```

### If E2E Tests Fail

1. **Check backend startup:**
   - Backend server logs
   - MySQL connection
   - Port availability

2. **Check Cypress execution:**
   - View screenshots
   - Download videos
   - Check test assertions

3. **Run locally:**
   ```powershell
   # Terminal 1: Start backend
   cd main_backend
   mvn spring-boot:run

   # Terminal 2: Run E2E
   .\run-backend-e2e.ps1
   ```

## ⏱️ Expected Timeline

```
Push to GitHub
    ↓
    └─ Workflows Triggered (< 10 seconds)
        ↓
        ├─ Unit Tests Start (immediate)
        │   └─ Complete in ~30 seconds
        │
        ├─ Integration Tests Start (immediate)
        │   ├─ Setup MySQL (~30 seconds)
        │   ├─ Run tests (~2-3 minutes)
        │   └─ Complete in ~3-4 minutes
        │
        └─ E2E Tests Start (immediate)
            ├─ Setup & Build (~1 minute)
            ├─ Start backend (~30 seconds)
            ├─ Run Cypress (~2-3 minutes)
            └─ Complete in ~4-5 minutes

Total Duration: 4-5 minutes for all workflows
```

## 📝 Next Steps After Success

1. ✅ **Review Coverage Reports**
   - Download JaCoCo report
   - Check coverage percentages
   - Identify areas needing tests

2. ✅ **Merge to Main (if desired)**
   - All tests passing
   - Coverage >= 80%
   - Ready for production

3. ✅ **Update Documentation**
   - Add workflow badges to README
   - Document any special test cases
   - Update team on new testing approach

4. ✅ **Share with Team**
   - Testing strategy guide
   - How to run tests locally
   - How to interpret CI results

## 🎯 Success Criteria

Your implementation is successful when you see:

- ✅ All workflow runs complete successfully
- ✅ Unit tests pass (< 30 seconds)
- ✅ Integration tests pass (2-5 minutes)
- ✅ E2E tests pass (if configured)
- ✅ Coverage >= 80% for both line and branch
- ✅ All artifacts uploaded successfully
- ✅ Green checkmarks across all jobs

## 📚 Reference Documentation

- **Testing Strategy:** `TESTING_STRATEGY.md`
- **Quick Start:** `TESTING_QUICK_START.md`
- **Implementation Details:** `TESTING_IMPLEMENTATION_COMPLETE.md`

---

**Current Status:** 🟡 Workflows Running  
**Expected Completion:** 4-5 minutes  
**Monitor At:** https://github.com/MorningMores/develop/actions

**Legend:**  
🟢 Success | 🟡 Running | 🔴 Failed | ⚪ Pending
