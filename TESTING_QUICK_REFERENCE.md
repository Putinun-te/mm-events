# Testing Quick Reference Card

## 🎯 Testing Strategy Overview

```
Unit Tests (Local)         →  Integration Tests (GitHub)  →  E2E Tests (Cypress)
Fast (seconds)                Moderate (minutes)              Slow (15-25 min)
No external deps              Real services (MySQL)           Full stack
Run on every commit           Backend/DB changes only         Main branch only
```

---

## ⚡ Quick Commands

### Frontend
```bash
# Unit tests
npm test                    # 570 tests, ~7s

# With coverage
npm run test:coverage       # 90%+ coverage

# Watch mode
npm run test:watch

# E2E
npm run test:e2e           # Requires backend
```

### Backend
```bash
# Unit tests only (no Docker)
mvn test -Dtest='!*DockerTest,!*IntegrationTest'

# Integration tests (requires Docker)
mvn test -Dtest='*DockerTest,*IntegrationTest'

# All tests
mvn clean test

# With coverage
mvn clean test jacoco:report
```

---

## 📋 GitHub Actions Workflows

| Workflow | Runs On | Duration | Triggers |
|----------|---------|----------|----------|
| **unit-tests.yml** | Ubuntu | 2-3 min | Every push/PR |
| **integration-tests.yml** | Ubuntu + MySQL | 8-12 min | Backend/DB changes |
| **e2e-tests.yml** | Ubuntu + Docker | 15-25 min | Main branch |

---

## ✅ Pre-Commit Checklist

- [ ] `npm test` passes (frontend)
- [ ] `mvn test -Dtest='!*Docker*,!*Integration*'` passes (backend)
- [ ] Code formatted
- [ ] No console.log or debug statements

---

## 🐛 Troubleshooting

### Frontend Tests Fail
```bash
rm -rf node_modules coverage .nuxt
npm install
npm test
```

### Backend Tests Fail
```bash
# Check JDK version
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
java -version

# Ensure Docker is running (for integration tests)
docker ps
```

### E2E Tests Fail
```bash
# Check backend
curl http://localhost:8080/actuator/health

# Restart stack
docker-compose down -v
docker-compose up -d mysql backend
```

---

## 📊 Coverage Requirements

- **Frontend Unit**: ≥90% ✅
- **Backend Unit**: ≥85% ✅ (currently 96%)
- **Integration**: ≥80%
- **E2E**: ≥70%

---

## 📁 Test File Locations

### Frontend
```
main_frontend/concert1/
├── __tests__/              # Unit tests
└── cypress/e2e/            # E2E tests
```

### Backend
```
main_backend/src/test/java/
├── **/*Test.java           # Unit tests
├── **/*IntegrationTest.java # Integration
└── **/*DockerTest.java      # Integration
```

---

## 🔗 Resources

- **TESTING_STRATEGY.md** - Complete guide
- **FRONTEND_BACKEND_TESTING.md** - Detailed commands
- **TESTING_IMPLEMENTATION_SUMMARY.md** - Implementation details

---

**Last Updated**: October 16, 2025
