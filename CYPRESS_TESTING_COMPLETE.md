# Complete Cypress Testing Implementation

**Date:** October 14, 2025  
**Status:** ✅ Cypress-only testing for both backend and frontend

## Testing Strategy - Cypress Only

### Backend Testing (Cypress)

1. **Unit Tests → Maven**
   - Profile: `-P unit-tests`
   - Java unit tests only
   - Fast, no external dependencies
   - Workflow: `backend-tests.yml` → job: `unit-tests`

2. **Integration Tests → GitHub Actions**
   - Profile: `-P integration-tests`
   - Java integration tests with MySQL
   - Workflow: `backend-tests.yml` → job: `integration-tests`

3. **E2E API Tests → Cypress** ✅
   - Framework: Cypress
   - Tests: API endpoints
   - Workflow: `backend-e2e.yml`

### Frontend Testing (Cypress)

1. **Component Tests → Cypress** ✅
   - Framework: Cypress component testing
   - Tests: Vue components in isolation
   - Workflow: `frontend-tests.yml` → job: `component-tests`

2. **E2E Full Stack → Cypress** ✅
   - Framework: Cypress E2E
   - Tests: Complete user workflows
   - Stack: MySQL → Backend → Frontend
   - Workflow: `frontend-e2e.yml`

## GitHub Actions Workflows

### 1. backend-tests.yml
```yaml
Jobs:
  - unit-tests: Maven unit tests
  - integration-tests: Maven integration tests with MySQL
```

### 2. backend-e2e.yml ✅ Cypress
```yaml
Jobs:
  - e2e-tests: Cypress API testing
    - MySQL service
    - Backend application
    - Cypress test suite
```

### 3. frontend-tests.yml ✅ Cypress
```yaml
Jobs:
  - component-tests: Cypress component testing
    - Tests Vue components
    - No backend needed
```

### 4. frontend-e2e.yml ✅ Cypress
```yaml
Jobs:
  - e2e-tests: Full stack Cypress E2E
    - MySQL service
    - Backend API
    - Frontend Nuxt app
    - Complete user workflows
```

## Key Changes

### ✅ Removed Vitest
- No longer using Vitest for frontend unit tests
- All frontend testing now uses Cypress

### ✅ Fixed npm install issues
- Changed from `npm ci` to `npm install`
- Works without package-lock.json
- Generates lock files during installation

### ✅ Unified Testing Framework
- **All E2E and component tests use Cypress**
- Consistent testing experience
- Same tool for backend API and frontend UI

## File Structure

```
.github/workflows/
├── backend-tests.yml           # Maven unit + integration
├── backend-e2e.yml             # Cypress API tests ✅
├── frontend-tests.yml          # Cypress component tests ✅
└── frontend-e2e.yml            # Cypress full stack E2E ✅

main_backend/
├── pom.xml                     # Maven profiles
├── src/test/java/              # Java unit/integration tests
└── cypress-tests/              # Cypress API tests ✅
    ├── package.json
    ├── cypress.config.js
    └── cypress/e2e/

main_frontend/concert1/
├── cypress.config.ts           # Cypress configuration
├── cypress/                    # E2E and component tests ✅
│   ├── e2e/                   # Full stack E2E tests
│   └── component/             # Component tests
└── package.json
```

## Testing Commands

### Backend (Local)

```powershell
# Maven unit tests
cd main_backend
.\mvnw.cmd clean test -P unit-tests -B

# Maven integration tests (needs Docker)
.\mvnw.cmd test -P integration-tests -B

# Cypress API E2E tests
cd cypress-tests
npm install
npx cypress run
```

### Frontend (Local)

```powershell
cd main_frontend/concert1

# Cypress component tests
npm install
npx cypress run --component

# Cypress E2E tests (needs backend running)
npx cypress run --e2e

# Or open Cypress UI
npx cypress open
```

## Workflow Execution Flow

```
Push to Tester branch
  │
  ├─> backend-tests.yml
  │     ├─> unit-tests (Maven, fast)
  │     └─> integration-tests (Maven + MySQL)
  │
  ├─> backend-e2e.yml ✅ CYPRESS
  │     └─> Cypress API tests
  │
  ├─> frontend-tests.yml ✅ CYPRESS
  │     └─> Cypress component tests
  │
  └─> frontend-e2e.yml ✅ CYPRESS
        └─> Full stack Cypress E2E
```

## Benefits of Cypress-Only Approach

✅ **Single testing framework** - Learn once, use everywhere  
✅ **Visual debugging** - Screenshots and videos on failure  
✅ **Component + E2E** - Test isolation and integration  
✅ **Real browser testing** - Test actual user experience  
✅ **Easy setup** - Just `npm install` and go  
✅ **Great developer experience** - Interactive UI mode  

## Testing Levels

### 1. Maven Unit Tests (Backend only)
- **What**: Test Java classes in isolation
- **Speed**: Very fast (seconds)
- **Dependencies**: None (mocked)

### 2. Maven Integration Tests (Backend only)
- **What**: Test database operations, Spring context
- **Speed**: Medium (1-2 minutes)
- **Dependencies**: MySQL database

### 3. Cypress Component Tests (Frontend only) ✅
- **What**: Test Vue components in isolation
- **Speed**: Fast (seconds)
- **Dependencies**: None (mocked)

### 4. Cypress E2E Tests (Backend API) ✅
- **What**: Test API endpoints
- **Speed**: Medium (1-2 minutes)
- **Dependencies**: MySQL + Backend

### 5. Cypress E2E Tests (Full Stack) ✅
- **What**: Test complete user workflows
- **Speed**: Slower (3-5 minutes)
- **Dependencies**: MySQL + Backend + Frontend

## Example Cypress Tests

### Backend API Test
```javascript
// main_backend/cypress-tests/cypress/e2e/auth.cy.js
describe('Authentication API', () => {
  it('should register a new user', () => {
    cy.request('POST', '/api/auth/register', {
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123'
    }).then((response) => {
      expect(response.status).to.eq(200)
      expect(response.body).to.have.property('token')
    })
  })
})
```

### Frontend Component Test
```javascript
// main_frontend/concert1/cypress/component/Login.cy.js
import Login from '~/components/Login.vue'

describe('Login Component', () => {
  it('renders login form', () => {
    cy.mount(Login)
    cy.get('input[type="email"]').should('exist')
    cy.get('input[type="password"]').should('exist')
    cy.get('button[type="submit"]').should('exist')
  })
})
```

### Full Stack E2E Test
```javascript
// main_frontend/concert1/cypress/e2e/login.cy.js
describe('Login Flow', () => {
  it('should login successfully', () => {
    cy.visit('/')
    cy.get('input[type="email"]').type('user@example.com')
    cy.get('input[type="password"]').type('password123')
    cy.get('button[type="submit"]').click()
    cy.url().should('include', '/dashboard')
  })
})
```

## Coverage Reports

### Backend (JaCoCo - Maven)
- Location: `main_backend/target/site/jacoco/index.html`
- Target: 80% line and branch coverage
- Generated by: Maven jacoco plugin

### Frontend (Cypress)
- Screenshots: Automatically captured on failure
- Videos: Full test execution recordings
- Coverage: Can be added with @cypress/code-coverage plugin

## Troubleshooting

### If backend E2E fails
- Check MySQL service is healthy
- Verify backend started successfully
- Review Cypress error messages
- Check screenshots in artifacts

### If frontend component tests fail
- Ensure all dependencies installed
- Check component imports
- Review Cypress error output

### If full stack E2E fails
- Verify MySQL → Backend → Frontend chain
- Check each service logs
- Review Cypress screenshots/videos
- Ensure correct environment variables

---

**Summary:**  
Complete Cypress-based testing for both backend (API) and frontend (components + E2E) with Maven for Java unit/integration tests. Simple, unified, and working!
