# Quick Start: Achieving 90-100% Test Coverage

**Goal:** Get all testing layers to 90-100% coverage following the three-tier approach.

---

## 🎯 Current Status Summary

| Layer | Current Coverage | Target | Gap | Status |
|-------|------------------|--------|-----|--------|
| **Backend** | 38% lines / 27% branches | 90%+ / 90%+ | -52% / -63% | 🔴 CRITICAL |
| **Frontend** | 89.52% lines / 77.26% branches | 90%+ / 90%+ | -0.48% / -12.74% | ⚠️ NEAR TARGET |
| **E2E** | 0% | 90%+ critical paths | -90% | 🔴 NOT STARTED |

**Total Tests:** 603 (121 backend + 482 frontend + 0 E2E)  
**Estimated Work:** ~50-56 hours to reach 90-100% across all layers

---

## 🚀 Quick Start: Backend (Priority 1)

### Step 1: Verify Current Baseline
```bash
cd c:\Users\ASUS\OneDrive\Documents\MU\ITDS323\pj\develop\main_backend
./mvnw.cmd clean test jacoco:report
```

**Expected Output:**
```
Tests run: 121
Failures: 0
Lines: 38%
Branches: 27%
```

**View Report:**
```bash
start target/site/jacoco/index.html
```

### Step 2: Focus on Controllers (12% → 90% branches)
**File to expand:** `src/test/java/com/concert/controller/AuthControllerTest.java`

**Add these test scenarios:**
```java
@Test
void register_ShouldReturnBadRequest_WhenEmailInvalid() {
    // Test invalid email format
}

@Test
void register_ShouldReturnConflict_WhenUsernameExists() {
    // Test duplicate username
}

@Test
void login_ShouldReturnUnauthorized_WhenPasswordWrong() {
    // Test wrong password
}

@Test
void login_ShouldReturnBadRequest_WhenUsernameBlank() {
    // Test empty username
}
```

**Estimated:** 4-5 tests per controller × 3 controllers = ~14 tests (~3.5 hours)

### Step 3: Focus on Models (0% → 90% branches) **CRITICAL**
**Create new file:** `src/test/java/com/concert/model/UserBuilderTest.java`

```java
@Test
void testUserBuilder() {
    User user = User.builder()
        .username("testuser")
        .email("test@example.com")
        .password("password")
        .build();
    
    assertNotNull(user);
    assertEquals("testuser", user.getUsername());
}

@Test
void testUserEqualsAndHashCode() {
    User user1 = new User();
    user1.setUsername("test");
    
    User user2 = new User();
    user2.setUsername("test");
    
    assertEquals(user1, user2);
    assertEquals(user1.hashCode(), user2.hashCode());
}
```

**Estimated:** 15 tests (~3.75 hours)

### Step 4: Run Tests and Check Coverage
```bash
./mvnw.cmd test jacoco:report
start target/site/jacoco/index.html
```

**Target After Step 2-3:** 60-70% lines, 50-60% branches

---

## 🎨 Quick Start: Frontend (Priority 2)

### Step 1: Verify Current Baseline
```bash
cd c:\Users\ASUS\OneDrive\Documents\MU\ITDS323\pj\develop\main_frontend\concert1
npm run test:coverage
```

**Expected Output:**
```
Test Files: 34 passed
Tests: 482 passed
Lines: 89.52%
Branches: 77.26%
Functions: 79.81%
```

### Step 2: Fix Low Branch Coverage Files
**Top 3 Priority Files:**
1. **ProfilePage.vue** - 28.57% branches (CRITICAL)
2. **MyBookingsPage.vue** - 63.63% branches
3. **EditEventPage.vue** - 53.84% branches

**Expand:** `test/unit/pages/ProfilePage.test.ts`

```typescript
describe('ProfilePage - Branch Coverage', () => {
  it('should handle profile update success', async () => {
    // Mock successful API call
    const mockUpdateProfile = vi.fn().mockResolvedValue({ success: true });
    
    const wrapper = mount(ProfilePage, {
      global: {
        mocks: {
          $api: { updateProfile: mockUpdateProfile }
        }
      }
    });
    
    await wrapper.find('form').trigger('submit');
    expect(mockUpdateProfile).toHaveBeenCalled();
  });
  
  it('should handle profile update failure', async () => {
    // Mock failed API call
    const mockUpdateProfile = vi.fn().mockRejectedValue(new Error('Update failed'));
    
    const wrapper = mount(ProfilePage, {
      global: {
        mocks: {
          $api: { updateProfile: mockUpdateProfile }
        }
      }
    });
    
    await wrapper.find('form').trigger('submit');
    // Assert error message displayed
  });
});
```

**Estimated:** 35-40 additional tests (~12-15 hours)

### Step 3: Fix MapTestingPage Error
**File:** `vitest.setup.ts`

```typescript
// Add global mock for longdo
global.longdo = {
  Map: vi.fn().mockImplementation(() => ({
    placeholder: null,
    // Add other longdo.Map methods as needed
  }))
};
```

**Estimated:** 15 minutes

### Step 4: Run Tests and Check Coverage
```bash
npm run test:coverage
```

**Target After Steps 2-3:** 90%+ lines, 85-90% branches, 85-90% functions

---

## 🧪 Quick Start: E2E Testing (Priority 3)

### Step 1: Install Coverage Plugin
```bash
cd c:\Users\ASUS\OneDrive\Documents\MU\ITDS323\pj\develop\main_frontend\concert1
npm install --save-dev @cypress/code-coverage nyc
```

### Step 2: Configure Coverage

**File:** `cypress.config.ts`

```typescript
import { defineConfig } from 'cypress';
import codeCoverage from '@cypress/code-coverage/task';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    setupNodeEvents(on, config) {
      codeCoverage(on, config);
      return config;
    },
  },
});
```

**File:** `cypress/support/e2e.ts`

```typescript
import '@cypress/code-coverage/support';
```

### Step 3: Create First E2E Test

**File:** `cypress/e2e/auth.cy.ts`

```typescript
describe('Authentication Flow', () => {
  beforeEach(() => {
    cy.visit('/');
  });
  
  it('should register a new user', () => {
    cy.visit('/register');
    cy.get('[data-cy=username]').type('testuser123');
    cy.get('[data-cy=email]').type('test@example.com');
    cy.get('[data-cy=password]').type('password123');
    cy.get('[data-cy=confirm-password]').type('password123');
    cy.get('[data-cy=submit]').click();
    
    cy.url().should('include', '/login');
    cy.contains('Registration successful').should('be.visible');
  });
  
  it('should login with valid credentials', () => {
    cy.visit('/login');
    cy.get('[data-cy=username]').type('testuser');
    cy.get('[data-cy=password]').type('password123');
    cy.get('[data-cy=submit]').click();
    
    cy.url().should('include', '/events');
    cy.get('[data-cy=user-menu]').should('be.visible');
  });
  
  it('should fail login with invalid credentials', () => {
    cy.visit('/login');
    cy.get('[data-cy=username]').type('wronguser');
    cy.get('[data-cy=password]').type('wrongpass');
    cy.get('[data-cy=submit]').click();
    
    cy.contains('Invalid credentials').should('be.visible');
  });
});
```

### Step 4: Run E2E Tests

**Development Mode (with UI):**
```bash
npm run cy:open
```

**Headless Mode:**
```bash
npm run test:e2e
```

**Estimated:** 30 tests (~15 hours)

---

## 📊 Coverage Verification Commands

### Backend Coverage Check
```bash
cd main_backend
./mvnw.cmd test jacoco:report

# Windows: Open report
start target/site/jacoco/index.html

# Check if meets 90% threshold (will fail if below)
./mvnw.cmd test jacoco:check
```

### Frontend Coverage Check
```bash
cd main_frontend/concert1
npm run test:coverage

# View report
start coverage/index.html

# Coverage will fail if below 90%
# ERROR: Coverage for lines (XX%) does not meet global threshold (90%)
```

### E2E Coverage Check
```bash
cd main_frontend/concert1
npm run test:e2e

# View combined coverage
npx nyc report --reporter=html
start coverage-e2e/index.html
```

---

## 🔄 Iteration Process (Until 90-100%)

### Step 1: Run Tests
```bash
# Backend
cd main_backend && ./mvnw.cmd clean test jacoco:report

# Frontend
cd main_frontend/concert1 && npm run test:coverage

# E2E
cd main_frontend/concert1 && npm run test:e2e
```

### Step 2: Check Coverage Reports
- Backend: `main_backend/target/site/jacoco/index.html`
- Frontend: `main_frontend/concert1/coverage/index.html`
- E2E: `main_frontend/concert1/coverage-e2e/index.html`

### Step 3: Identify Gaps
Look for red/yellow highlighted lines in coverage reports:
- **Red:** Uncovered code (0%)
- **Yellow:** Partially covered (< 80%)
- **Green:** Good coverage (≥ 80%)

### Step 4: Add Tests for Gaps
Focus on:
1. Backend: Branches in controllers, models (0% branch coverage critical)
2. Frontend: Branches in pages (ProfilePage 28%, MyBookingsPage 63%)
3. E2E: Critical user journeys

### Step 5: Repeat Until ALL Metrics ≥ 90%

**User Requirement:**
> "if not 90-100%, back to fix tester all of tester part again until tester part have 90-100%"

---

## ⚡ Priority Order

### Week 1: Backend Critical (Days 1-3)
1. **Controllers** → 90%+ branches (3.5 hours)
2. **Models** → 90%+ branches (3.75 hours) **CRITICAL - 0% current**
3. **Services** → 90%+ branches (6.7 hours)
4. **DTOs** → 90%+ instructions (1.7 hours)

**Week 1 Goal:** Backend 90%+/90%+ ✅

### Week 2: Frontend + E2E Setup (Days 4-6)
1. **ProfilePage** → 90%+ branches (5-6 hours) **CRITICAL - 28% current**
2. **MyBookingsPage** → 90%+ branches (4-5 hours)
3. **EditEventPage** → 90%+ branches (3-4 hours)
4. **Install E2E coverage** (1 hour)

**Week 2 Goal:** Frontend 90%+/90%+/90%+ ⚠️, E2E infrastructure ready ✅

### Week 3: E2E Implementation (Days 7-9)
1. **Auth flow tests** (7 tests, 3.5 hours)
2. **Event management tests** (10 tests, 5 hours)
3. **Booking flow tests** (8 tests, 4 hours)
4. **Profile tests** (5 tests, 2.5 hours)

**Week 3 Goal:** E2E 90%+ critical paths ✅

### Day 10: Final Verification
- All layers ≥ 90%
- All tests passing
- Documentation complete

---

## 📝 Test Templates

### Backend Controller Test Template
```java
@SpringBootTest
@AutoConfigureMockMvc
class ControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private ServiceClass service;
    
    @Test
    void endpoint_ShouldReturnSuccess_WhenValidInput() throws Exception {
        // Arrange
        when(service.method(any())).thenReturn(expectedResult);
        
        // Act & Assert
        mockMvc.perform(post("/api/endpoint")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.field").value("expected"));
    }
}
```

### Frontend Component Test Template
```typescript
import { mount } from '@vue/test-utils';
import { describe, it, expect, vi } from 'vitest';
import ComponentName from '~/app/components/ComponentName.vue';

describe('ComponentName', () => {
  it('should render correctly', () => {
    const wrapper = mount(ComponentName, {
      props: {
        // props here
      }
    });
    
    expect(wrapper.find('[data-testid="element"]').exists()).toBe(true);
  });
  
  it('should handle click event', async () => {
    const mockFn = vi.fn();
    const wrapper = mount(ComponentName, {
      props: {
        onClick: mockFn
      }
    });
    
    await wrapper.find('button').trigger('click');
    expect(mockFn).toHaveBeenCalled();
  });
});
```

### E2E Test Template
```typescript
describe('Feature Flow', () => {
  beforeEach(() => {
    cy.visit('/');
    // Setup test data
  });
  
  it('should complete user journey', () => {
    // Step 1
    cy.get('[data-cy=action1]').click();
    cy.url().should('include', '/page1');
    
    // Step 2
    cy.get('[data-cy=input]').type('value');
    cy.get('[data-cy=submit]').click();
    
    // Step 3 - Verify outcome
    cy.contains('Success message').should('be.visible');
  });
});
```

---

## 🛠️ Troubleshooting

### Backend: JaCoCo not generating report
```bash
# Clean and rebuild
./mvnw.cmd clean
./mvnw.cmd test jacoco:report

# Check if jacoco.exec exists
dir target\jacoco.exec
```

### Frontend: Tests failing on main branch
```bash
# The old .spec.ts files are outdated
# Use the .test.ts files instead
npm run test -- --run
```

### Frontend: "longdo is not defined" error
```typescript
// Add to vitest.setup.ts
global.longdo = {
  Map: vi.fn().mockImplementation(() => ({}))
};
```

### E2E: Backend not starting
```bash
# Make sure backend is running
cd main_backend
./mvnw.cmd spring-boot:run

# Or use Docker Compose
docker-compose up -d
```

---

## 📈 Success Metrics

### ✅ Final Targets

**Backend:**
- Lines: ≥ 90%
- Branches: ≥ 90%
- All tests passing (no skipped)

**Frontend:**
- Lines: ≥ 90%
- Branches: ≥ 90%
- Functions: ≥ 90%
- Statements: ≥ 90%
- No unhandled errors

**E2E:**
- Auth flow: 100% coverage
- Event management: 100% coverage
- Booking flow: 100% coverage
- Profile: 100% coverage

---

## 📞 Quick Reference

**Backend Test Command:**
```bash
cd main_backend && ./mvnw.cmd test jacoco:report
```

**Frontend Test Command:**
```bash
cd main_frontend/concert1 && npm run test:coverage
```

**E2E Test Command:**
```bash
cd main_frontend/concert1 && npm run test:e2e
```

**View All Reports:**
```bash
# Backend
start main_backend/target/site/jacoco/index.html

# Frontend
start main_frontend/concert1/coverage/index.html

# E2E
start main_frontend/concert1/coverage-e2e/index.html
```

---

**Next Action:** Start with Backend Controllers (Priority 1) → Add 14 tests to reach 90% branches

