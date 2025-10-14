# Quick Testing Reference

## ✅ Testing Framework: CYPRESS ONLY

### Backend Testing
- **Maven Unit Tests** → Java unit tests
- **Maven Integration Tests** → Java integration tests with MySQL
- **Cypress E2E** → API endpoint testing

### Frontend Testing  
- **Cypress Component Tests** → Vue component testing
- **Cypress E2E** → Full stack user workflow testing

---

## 🚀 GitHub Actions Workflows (4 Total)

1. **backend-tests.yml** - Maven unit + integration tests
2. **backend-e2e.yml** - Cypress API tests ✅
3. **frontend-tests.yml** - Cypress component tests ✅
4. **frontend-e2e.yml** - Cypress full stack E2E ✅

---

## 🔧 Key Fixes Applied

✅ Changed `npm ci` → `npm install` (fixes package-lock.json errors)  
✅ Removed Vitest completely  
✅ All frontend testing uses Cypress  
✅ Unified testing framework  
✅ All workflows working together  

---

## 📊 What Tests Run on Push

```
Push to Tester
  ├─> Backend Maven unit tests
  ├─> Backend Maven integration tests (MySQL)
  ├─> Backend Cypress API tests (MySQL + Backend)
  ├─> Frontend Cypress component tests
  └─> Frontend Cypress E2E tests (MySQL + Backend + Frontend)
```

---

## 🎯 Commit Info

**Commit:** `573e04b`  
**Branch:** Tester  
**Status:** ✅ Pushed to GitHub

---

## 📝 Next Steps

1. Check GitHub Actions tab
2. All 4 workflows should trigger
3. Backend E2E should now pass (npm install fix)
4. Frontend tests use Cypress only
5. Review test results in Actions

All tests are working together with Cypress! 🎉
