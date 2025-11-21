# Quick Unit Test Pipeline

## ✅ What It Does

A **minimal, fast** GitHub Actions workflow that runs **only unit tests**.

## 🚀 Features

### What Runs ✅
- **Backend Unit Tests**: Maven tests with H2 in-memory database
- **Frontend Unit Tests**: Vitest tests in jsdom environment

### What Doesn't Run ❌
- ❌ No Docker builds
- ❌ No integration tests
- ❌ No E2E tests
- ❌ No deployments (staging/production)
- ❌ No Kubernetes operations
- ❌ No external services (MySQL containers, etc.)

## ⚡ Speed

**Estimated execution time:** 2-3 minutes

- Backend tests: ~1-2 minutes
- Frontend tests: ~30-60 seconds
- Jobs run in parallel

## 🔄 When It Runs

**Automatic triggers:**
- Push to `main`, `develop`, or `release/**` branches
- Pull requests to these branches
- Changes to backend or frontend code

**Manual trigger:**
- GitHub Actions UI → Run workflow

## 📋 Pipeline Jobs

```
Quick Unit Tests Workflow
│
├─ Backend Unit Tests (parallel)
│  ├─ Checkout code
│  ├─ Setup JDK 21
│  ├─ Maven cache
│  └─ Run: mvn clean test
│
├─ Frontend Unit Tests (parallel)
│  ├─ Checkout code
│  ├─ Setup Node.js 20
│  ├─ npm cache
│  ├─ Install dependencies
│  └─ Run: npm run test
│
└─ Test Summary
   └─ Check all results
```

## 📊 Expected Output

### Success ✅
```
📊 Test Pipeline Summary
========================
Backend Tests: success
Frontend Tests: success

✅ All tests passed!
```

### Failure ❌
```
📊 Test Pipeline Summary
========================
Backend Tests: failure
Frontend Tests: success

❌ Some tests failed
```

## 🔍 View Results

**GitHub Actions page:**
https://github.com/MorningMores/develop/actions

Look for workflow: **"Quick Unit Tests"**

## 🛠️ Local Testing

Before pushing, run tests locally:

### Backend
```powershell
cd main_backend
mvn clean test -Dspring.profiles.active=test
```

### Frontend
```powershell
cd main_frontend/concert1
npm test
```

## 📁 Workflow File

Location: `.github/workflows/quick-tests.yml`

## 🎯 Use Cases

Perfect for:
- ✅ Quick validation of code changes
- ✅ Pull request checks
- ✅ Pre-merge testing
- ✅ Fast feedback loop
- ✅ Development branches

NOT for:
- ❌ Production deployments
- ❌ Integration testing with real databases
- ❌ E2E testing
- ❌ Performance testing

## 💡 Benefits

1. **Fast Feedback**: Results in 2-3 minutes
2. **Low Cost**: Minimal GitHub Actions minutes
3. **Simple**: No complex dependencies
4. **Focused**: Only tests code quality
5. **Reliable**: No external service dependencies

## 🔧 Configuration

The workflow uses:
- **Java 21** (Temurin distribution)
- **Node.js 20** (LTS)
- **Maven cache** (faster builds)
- **npm cache** (faster installs)
- **Parallel execution** (backend + frontend simultaneously)

## 📝 Test Profiles

### Backend
- Uses `test` profile
- H2 in-memory database
- UUID-based test isolation
- No Docker containers needed

### Frontend
- Vitest with jsdom
- Component unit tests
- No browser required

## 🚨 Troubleshooting

### If backend tests fail:
1. Check H2 database configuration in `application-test.properties`
2. Verify test isolation (UUID usage)
3. Run locally: `mvn test`

### If frontend tests fail:
1. Check Vitest configuration
2. Verify dependencies: `npm ci`
3. Run locally: `npm test`

### If workflow doesn't trigger:
1. Verify file paths in trigger configuration
2. Check branch names match
3. Ensure changes are in monitored directories

## 📈 Recent Commits

```
76e82e0 - feat: add quick unit test pipeline
90701af - chore: remove Kubernetes deployment workflow
f4104fa - fix: resolve test isolation issues
5b99cdc - fix: resolve database initialization errors
```

## ✅ Status

**Current:** ACTIVE  
**Branch:** release/v1.0.0  
**Date:** November 21, 2025  
**Status:** ✅ PUSHED AND ACTIVE

---

**This workflow provides fast, focused testing without deployment complexity!** 🎉
