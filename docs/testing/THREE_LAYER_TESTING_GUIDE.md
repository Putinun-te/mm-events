# 3-Layer Testing Strategy for Frontend & Backend

> **Unit → Integration → E2E**  
> Clear separation for both Frontend and Backend

---

## 🎯 Testing Layers Explained

### Layer 1: UNIT TESTS (Fast, Local, Maven/npm)

**Frontend Unit Tests** (`npm test`)
- **Tool**: Vitest + Testing Library
- **Where**: Run locally with `npm test`
- **What's Tested**:
  - ✅ Component logic (Login.vue, Register.vue, Booking.vue)
  - ✅ Vue composables
  - ✅ Utility functions
  - ✅ Form validation
  - ❌ NO API calls (mocked)
  - ❌ NO backend interaction
- **Speed**: ~7 seconds (570 tests)
- **Coverage**: 90%+

**Backend Unit Tests** (`mvn test`)
- **Tool**: JUnit 5 + Mockito + Testcontainers
- **Where**: Run locally with Maven OR in GitHub Actions
- **What's Tested**:
  - ✅ Service layer logic
  - ✅ Controller endpoints (MockMvc)
  - ✅ Repository with real MySQL (Testcontainers)
  - ✅ DTOs and validation
  - ✅ Security filters
- **Speed**: ~2-3 minutes (228 tests)
- **Coverage**: 96%

**Key Point**: Backend "unit tests" include Testcontainers because each test gets its own isolated MySQL container. This is still fast and can run locally.

---

### Layer 2: INTEGRATION TESTS (GitHub Actions)

**Frontend Integration** (GitHub Actions)
- **Tool**: GitHub Actions + Real Backend
- **Where**: ONLY in GitHub Actions (not local)
- **What's Tested**:
  - ✅ Frontend makes REAL API calls
  - ✅ Backend responds with MySQL
  - ✅ Auth flow (login → register → logout)
  - ✅ Data persistence across requests
  - ✅ Session management
- **Speed**: ~8-12 minutes
- **When**: Automatically when backend/frontend changes

**Backend Integration** (GitHub Actions)
- **Tool**: GitHub Actions + MySQL Service
- **Where**: ONLY in GitHub Actions (not local)
- **What's Tested**:
  - ✅ Full Spring Boot context
  - ✅ Real MySQL database (GitHub service)
  - ✅ Transaction management
  - ✅ Multi-layer integration (Controller → Service → Repository)
- **Speed**: ~8-12 minutes
- **When**: Automatically when backend changes

**Key Point**: Integration tests verify that frontend and backend work together with real services, but ONLY run in CI/CD (not locally).

---

### Layer 3: E2E COVERAGE (Cypress)

**E2E Tests** (Full Stack)
- **Tool**: Cypress
- **Where**: Can run locally OR in GitHub Actions
- **What's Tested**:
  - ✅ Complete user journeys
  - ✅ Login → Browse Events → Book → Checkout → Logout
  - ✅ Multi-page flows
  - ✅ Real browser interactions
  - ✅ Full stack (MySQL + Backend + Frontend)
- **Speed**: ~15-25 minutes
- **Coverage**: E2E flow coverage
- **When**: 
  - Locally: `npm run test:e2e`
  - GitHub: On main branch changes

**Key Point**: E2E tests simulate real users with full stack running. These provide end-to-end coverage.

---

## 📋 What Runs Where

### Local Development (Your Machine)

```bash
# Unit Tests - Frontend
cd main_frontend/concert1
npm test                    # Fast (7s)

# Unit Tests - Backend  
cd main_backend
mvn test                    # Includes Testcontainers (2-3 min)

# E2E Tests (optional)
docker-compose up -d mysql backend
cd main_frontend/concert1
npm run dev &
npm run test:e2e           # Full stack (5-10 min)
```

### GitHub Actions (Automatic)

```yaml
# unit-tests.yml (Runs on every commit)
- Frontend: npm test
- Backend: mvn test (with Testcontainers)

# e2e-tests.yml (Runs on main branch)  
- Full stack: Docker Compose + Cypress
```

---

## 🎯 Testing Matrix

| Test Type | Frontend | Backend | Where | When |
|-----------|----------|---------|-------|------|
| **Unit** | Vitest (mocked) | Maven + Testcontainers | Local + CI | Every commit |
| **Integration** | Real API calls | Full Spring context + MySQL | CI only | Backend changes |
| **E2E** | Cypress | Participates in E2E | Local + CI | Main branch |

---

## 📊 Coverage Breakdown

### Frontend Coverage

```
Unit Tests (Vitest):
├── Components: 90%+
├── Pages: 85%+
├── Composables: 95%+
└── Utils: 100%

E2E Coverage (Cypress):
├── User Flows: 70%+
├── Critical Paths: 100%
└── Edge Cases: 60%+
```

### Backend Coverage

```
Unit Tests (Maven):
├── Services: 96%
├── Controllers: 95%
├── Repositories: 100%
└── Security: 90%

E2E Coverage:
├── API Endpoints: Tested via Cypress
└── Full flows: Tested via Cypress
```

---

## 🔄 How They Work Together

```
┌─────────────────────────────────────────────────┐
│  FRONTEND UNIT TESTS (npm test)                 │
│  • Component logic                              │
│  • No API calls                                 │
│  • 570 tests, ~7s                              │
└─────────────────────────────────────────────────┘
                    +
┌─────────────────────────────────────────────────┐
│  BACKEND UNIT TESTS (mvn test)                  │
│  • Service/Controller logic                     │
│  • Testcontainers for DB                        │
│  • 228 tests, ~2-3 min                         │
└─────────────────────────────────────────────────┘
                    ↓
            Run in GitHub Actions
                    ↓
┌─────────────────────────────────────────────────┐
│  INTEGRATION TESTS (GitHub Actions)             │
│  • Frontend → Backend API calls                 │
│  • Full Spring context                          │
│  • Real MySQL service                           │
│  • ~8-12 min                                   │
└─────────────────────────────────────────────────┘
                    ↓
            Main Branch Only
                    ↓
┌─────────────────────────────────────────────────┐
│  E2E TESTS (Cypress)                            │
│  • Full stack (MySQL + Backend + Frontend)      │
│  • Real user flows                              │
│  • Complete coverage                            │
│  • ~15-25 min                                  │
└─────────────────────────────────────────────────┘
```

---

## ✅ Testing Checklist

### Before Committing Code

**Frontend Developer**:
- [ ] `npm test` passes locally
- [ ] Components have unit tests
- [ ] No API calls in unit tests (use mocks)

**Backend Developer**:
- [ ] `mvn test` passes locally
- [ ] Testcontainers tests run successfully
- [ ] Services and controllers have tests

### Before Merging PR

- [ ] Unit tests pass in GitHub Actions
- [ ] Integration tests pass (if backend/frontend changed)
- [ ] E2E tests pass (if on main branch)
- [ ] Coverage requirements met

---

## 🎯 Key Differences

### Frontend: Unit vs E2E

| Aspect | Unit Tests | E2E Tests |
|--------|------------|-----------|
| **API Calls** | Mocked | Real |
| **Backend** | Not needed | Running |
| **Browser** | Simulated (happy-dom) | Real (Cypress) |
| **Speed** | Fast (7s) | Slow (5-10 min) |
| **Purpose** | Logic testing | User flows |

### Backend: Unit vs Integration

| Aspect | Unit Tests (Local) | Integration Tests (CI) |
|--------|-------------------|----------------------|
| **Database** | Testcontainers (isolated) | GitHub MySQL service |
| **Context** | Individual layers | Full Spring context |
| **Speed** | Fast (2-3 min) | Moderate (8-12 min) |
| **Scope** | Service/Repository | Multi-layer flows |
| **Where** | Local + CI | CI only |

---

## 📚 Examples

### Frontend Unit Test Example
```typescript
// Login.test.ts
describe('Login Component', () => {
  it('validates email format', () => {
    // Unit test - NO real API
    const wrapper = mount(Login)
    wrapper.vm.email = 'invalid'
    expect(wrapper.vm.validateEmail()).toBe(false)
  })
})
```

### Frontend E2E Test Example
```typescript
// login.cy.ts
describe('Login Flow', () => {
  it('logs in successfully', () => {
    // E2E - Real backend + database
    cy.visit('/login')
    cy.get('[data-test="email"]').type('user@example.com')
    cy.get('[data-test="password"]').type('password123')
    cy.get('[data-test="submit"]').click()
    cy.url().should('include', '/dashboard')
  })
})
```

### Backend Unit Test Example
```java
// AuthServiceTest.java
@Test
void testRegisterUser() {
    // Unit test with Testcontainers
    RegisterRequest request = new RegisterRequest(
        "test@example.com", "password", "Test User"
    );
    AuthResponse response = authService.register(request);
    assertNotNull(response.getToken());
}
```

---

## 🎯 Summary

**3 Layers for Both Frontend & Backend**:

1. **UNIT** (Maven/npm) - Fast, local, isolated testing
2. **INTEGRATION** (GitHub Actions) - Real services, full context
3. **E2E** (Cypress) - Complete user flows, full stack

**Frontend**: Unit (Vitest) → Integration (in CI) → E2E (Cypress)  
**Backend**: Unit (Maven+TC) → Integration (in CI) → E2E (participates)

**All 798 tests working together to ensure quality!** ✅

---

**Last Updated**: October 16, 2025  
**Commit**: 8e2c4ef
