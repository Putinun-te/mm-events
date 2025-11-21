# E2E Test Quick Reference

## 🚀 Running Tests

```bash
# Primary API integration tests (fast, recommended)
npm run test:e2e

# All E2E tests (including browser-based)
npm run test:e2e:all

# Watch mode for development
npm run test:e2e:watch
```

## 📊 What Changed

### Before (Broken)
- ❌ Backend/Frontend failed to start in CI
- ❌ TextEncoder errors with browser automation
- ❌ Short 30s timeouts not enough
- ❌ No diagnostic logging
- ❌ Difficult to debug failures

### After (Fixed)
- ✅ Robust server startup with 60s timeouts
- ✅ API-based tests (no browser needed)
- ✅ Detailed diagnostic logging
- ✅ Health check endpoints
- ✅ Server logs uploaded as artifacts
- ✅ Fast, reliable execution

## 🔧 Key Fixes

1. **Server Startup:**
   - Use `/actuator/health` endpoint
   - Increase timeout to 60 seconds
   - Add `set -e` for error detection
   - Use `nohup` for background logging
   - Initialize database before backend starts

2. **TextEncoder Issue:**
   - Change vitest environment: `jsdom` → `node`
   - Create API-based tests (no browser)
   - Add pool configuration: `singleFork: true`
   - Set explicit Node.js version: `20.x`

3. **Better Debugging:**
   - Progress indicators every 10 attempts
   - Log backend/frontend output
   - Upload logs as CI artifacts
   - Service verification step

## 📝 Test Structure

### API Integration Tests (api-integration.e2e.test.ts)
```typescript
// Health Checks
✅ Backend actuator health
✅ Auth test endpoint
✅ Frontend server

// Authentication
✅ Register new user
✅ Login with credentials
✅ Reject invalid login

// Events API
✅ List events
✅ Create event (with auth)
✅ Fetch single event
✅ Reject unauthorized creation

// Full Journey
✅ Register → Login → Create → Fetch
```

## 🎯 CI/CD Integration

**Runs on:** `main`, `develop`, `release/*` branches

**Workflow Steps:**
1. Setup MySQL service
2. Build backend
3. Start backend (with health checks)
4. Start frontend (with health checks)
5. Verify all services
6. Run E2E tests
7. Upload results & logs

## 🐛 Debugging

### Check Server Logs
```bash
# Backend
cat main_backend/backend.log

# Frontend
cat main_frontend/concert1/frontend.log
```

### Check CI Artifacts
- Go to failed workflow run
- Download `e2e-server-logs` artifact
- Review backend.log and frontend.log

### Common Issues

**Backend won't start:**
- Check MySQL is ready
- Check database schema initialized
- Review backend.log for errors

**Frontend won't start:**
- Check backend is ready first
- Verify NUXT_PUBLIC_API_BASE is set
- Review frontend.log for errors

**Tests fail:**
- Verify both servers responding
- Check auth endpoints accessible
- Review test output for specific failures

## 📚 Documentation

- `E2E_TEST_IMPLEMENTATION.md` - Initial implementation
- `E2E_TEST_FIX_SUMMARY.md` - Detailed fix documentation
- `test/e2e/README.md` - Test structure overview
- `test/e2e/TESTING.md` - Comprehensive testing guide

## ✅ Success Indicators

In CI logs, look for:
```
✅ MySQL is ready!
✅ Backend is ready!
✅ Frontend is ready!
✅ All services verified
✅ E2E tests completed
```

## 🔗 Useful Links

- Workflow: `.github/workflows/full-pipeline.yml`
- Tests: `main_frontend/concert1/test/e2e/`
- Config: `main_frontend/concert1/vitest.e2e.config.ts`
- Actions: https://github.com/MorningMores/develop/actions

---

**Last Updated:** November 22, 2025  
**Commit:** 951e850  
**Status:** ✅ All Issues Resolved
