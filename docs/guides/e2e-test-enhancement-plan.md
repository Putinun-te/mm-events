# E2E Test Enhancement Plan

**Current E2E Tests:** 2 (homepage, navigation)  
**Target:** 10-15 comprehensive E2E tests  
**Framework:** Playwright  
**Priority:** Medium (Short-term)

---

## 📊 Current State

### Existing E2E Tests (`tests/e2e/basic.spec.ts`)
```typescript
✅ Homepage loads successfully (200 status)
✅ Navigation bar links are accessible
```

**Coverage Gap:** Only UI rendering tested, no user flows or backend integration

---

## 🎯 New E2E Test Suites

### 1. Authentication Flow Tests
**File:** `tests/e2e/auth.spec.ts`

**Test Cases (8 tests):**

```typescript
test.describe('User Registration Flow', () => {
  test('Complete registration with valid data', async ({ page }) => {
    // Navigate to registration page
    // Fill form with valid data
    // Submit form
    // Verify redirect to dashboard/homepage
    // Verify welcome message or user profile
  });

  test('Registration fails with existing email', async ({ page }) => {
    // Register first user
    // Attempt to register with same email
    // Verify error message displayed
    // Verify user not created in DB
  });

  test('Registration fails with invalid email format', async ({ page }) => {
    // Fill form with invalid email
    // Submit form
    // Verify validation error message
    // Verify form not submitted
  });

  test('Registration fails with short password', async ({ page }) => {
    // Fill form with password < 6 characters
    // Verify real-time or submission validation error
  });

  test('Registration form validates required fields', async ({ page }) => {
    // Submit empty form
    // Verify all required field errors displayed
  });
});

test.describe('User Login Flow', () => {
  test('Successful login with valid credentials', async ({ page }) => {
    // Register a user first
    // Navigate to login page
    // Enter correct credentials
    // Submit form
    // Verify redirect to dashboard
    // Verify user session active (check localStorage/cookies)
  });

  test('Login fails with incorrect password', async ({ page }) => {
    // Register a user
    // Attempt login with wrong password
    // Verify error message
    // Verify user not logged in
  });

  test('Login fails with non-existent email', async ({ page }) => {
    // Attempt login with unregistered email
    // Verify error message
  });

  test('Remember me checkbox persists session', async ({ page }) => {
    // Login with remember me checked
    // Close browser
    // Reopen and check if still logged in
  });

  test('Logout clears user session', async ({ page }) => {
    // Login
    // Click logout
    // Verify redirect to login/home
    // Verify session cleared
    // Attempt to access protected page → should redirect
  });
});
```

**Expected Duration:** 30-45 seconds (8 tests)

---

### 2. Event Creation Flow Tests
**File:** `tests/e2e/events.spec.ts`

**Test Cases (7 tests):**

```typescript
test.describe('Event Creation Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Register and login a user before each test
  });

  test('Create event with all required fields', async ({ page }) => {
    // Navigate to create event page
    // Fill all required fields (title, dates, location, etc.)
    // Submit form
    // Verify event created
    // Verify redirect to event details page
    // Verify event appears in events list
  });

  test('Create event with optional fields', async ({ page }) => {
    // Fill required + optional fields (description, price, limit)
    // Submit
    // Verify all data saved correctly
  });

  test('Event creation fails without authentication', async ({ page }) => {
    // Logout
    // Navigate to create event page
    // Verify redirect to login or access denied
  });

  test('Event creation validates start date before end date', async ({ page }) => {
    // Fill form with endDate < startDate
    // Submit
    // Verify validation error
  });

  test('Event creation validates future dates', async ({ page }) => {
    // Fill form with past date
    // Submit
    // Verify validation error
  });

  test('Created event appears in public events list', async ({ page }) => {
    // Create event
    // Navigate to events listing page
    // Verify new event visible
  });

  test('Event creator can edit their own event', async ({ page }) => {
    // Create event
    // Navigate to event details
    // Click edit button
    // Modify fields
    // Save changes
    // Verify updates reflected
  });
});

test.describe('Event Viewing Flow', () => {
  test('View event details as guest', async ({ page }) => {
    // Create event (setup)
    // Logout
    // Navigate to event details page
    // Verify all public fields visible
    // Verify no edit/delete buttons for guest
  });

  test('Search/filter events by category', async ({ page }) => {
    // Create events in different categories (setup)
    // Use filter dropdown
    // Verify filtered results
  });
});
```

**Expected Duration:** 40-60 seconds (9 tests)

---

### 3. User Profile Management Tests
**File:** `tests/e2e/profile.spec.ts`

**Test Cases (6 tests):**

```typescript
test.describe('User Profile Management', () => {
  test.beforeEach(async ({ page }) => {
    // Register and login
  });

  test('View own profile', async ({ page }) => {
    // Navigate to profile page
    // Verify user details displayed
    // Verify email, username visible
  });

  test('Update profile information', async ({ page }) => {
    // Navigate to edit profile
    // Change username, email, phone
    // Save changes
    // Verify success message
    // Refresh page
    // Verify changes persisted
  });

  test('Update profile fails with existing email', async ({ page }) => {
    // Register second user (setup)
    // Try to update to second user's email
    // Verify conflict error message
  });

  test('Upload profile picture', async ({ page }) => {
    // Navigate to profile
    // Upload image file
    // Verify preview shown
    // Save
    // Verify image persisted
  });

  test('Change password', async ({ page }) => {
    // Navigate to change password section
    // Enter current password
    // Enter new password
    // Confirm new password
    // Submit
    // Verify success
    // Logout and login with new password
  });

  test('Delete account', async ({ page }) => {
    // Navigate to account settings
    // Click delete account
    // Confirm deletion
    // Verify redirect to home
    // Attempt to login → should fail
  });
});
```

**Expected Duration:** 35-50 seconds (6 tests)

---

### 4. End-to-End User Journey Test
**File:** `tests/e2e/full-journey.spec.ts`

**Test Case (1 comprehensive test):**

```typescript
test('Complete user journey: Register → Create Event → Update → Delete', async ({ page }) => {
  // Step 1: Registration
  await page.goto('/concert/register');
  await page.fill('[name="username"]', 'testuser');
  await page.fill('[name="email"]', 'testuser@example.com');
  await page.fill('[name="password"]', 'password123');
  await page.click('button[type="submit"]');
  await expect(page).toHaveURL(/.*dashboard|home/);

  // Step 2: Create Event
  await page.click('text=Create Event');
  await page.fill('[name="title"]', 'Test Concert');
  await page.fill('[name="startDate"]', '2025-12-01T19:00');
  await page.fill('[name="endDate"]', '2025-12-01T23:00');
  await page.fill('[name="location"]', 'Test Venue');
  await page.click('button:has-text("Create")');
  await expect(page.locator('text=Test Concert')).toBeVisible();

  // Step 3: View Event
  await page.click('text=Test Concert');
  await expect(page.locator('h1')).toContainText('Test Concert');

  // Step 4: Edit Event
  await page.click('button:has-text("Edit")');
  await page.fill('[name="title"]', 'Updated Concert');
  await page.click('button:has-text("Save")');
  await expect(page.locator('text=Updated Concert')).toBeVisible();

  // Step 5: Delete Event
  await page.click('button:has-text("Delete")');
  await page.click('button:has-text("Confirm")');
  await expect(page.locator('text=Updated Concert')).not.toBeVisible();

  // Step 6: Logout
  await page.click('button:has-text("Logout")');
  await expect(page).toHaveURL(/.*login|home/);
});
```

**Expected Duration:** 15-20 seconds (1 test)

---

## 🛠️ Implementation Steps

### Step 1: Setup E2E Test Environment

**Update `playwright.config.ts`:**

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],

  webServer: [
    {
      command: 'npm run dev',
      url: 'http://localhost:3000',
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
    },
    {
      command: 'cd ../../main_backend && mvn spring-boot:run',
      url: 'http://localhost:8080/api/auth/test',
      reuseExistingServer: !process.env.CI,
      timeout: 120000,
    },
  ],
});
```

### Step 2: Create Test Fixtures

**`tests/e2e/fixtures.ts`:**

```typescript
import { test as base } from '@playwright/test';

type TestFixtures = {
  authenticatedPage: Page;
  testUser: {
    username: string;
    email: string;
    password: string;
    token?: string;
  };
};

export const test = base.extend<TestFixtures>({
  testUser: async ({}, use) => {
    const timestamp = Date.now();
    const user = {
      username: `testuser_${timestamp}`,
      email: `test_${timestamp}@example.com`,
      password: 'password123',
    };
    await use(user);
  },

  authenticatedPage: async ({ page, testUser }, use) => {
    // Register and login
    await page.goto('/concert/register');
    await page.fill('[name="username"]', testUser.username);
    await page.fill('[name="email"]', testUser.email);
    await page.fill('[name="password"]', testUser.password);
    await page.click('button[type="submit"]');
    await page.waitForURL(/.*dashboard|home/);
    
    await use(page);
    
    // Cleanup: logout
    await page.click('[data-test-id="logout"]');
  },
});

export { expect } from '@playwright/test';
```

### Step 3: Create Test Files

```bash
cd main_frontend/concert1/tests/e2e

# Create new test files
New-Item -ItemType File -Path "auth.spec.ts"
New-Item -ItemType File -Path "events.spec.ts"
New-Item -ItemType File -Path "profile.spec.ts"
New-Item -ItemType File -Path "full-journey.spec.ts"
New-Item -ItemType File -Path "fixtures.ts"
```

### Step 4: Run E2E Tests

```bash
# Run all E2E tests
npx playwright test

# Run specific test file
npx playwright test auth.spec.ts

# Run in headed mode (see browser)
npx playwright test --headed

# Run in debug mode
npx playwright test --debug

# Generate report
npx playwright show-report
```

---

## 📊 Expected Results

### Test Count
- **Before:** 2 tests
- **After:** 32 tests (16x increase)
  - Auth flow: 10 tests
  - Event flow: 9 tests
  - Profile flow: 6 tests
  - Full journey: 1 test
  - Existing: 2 tests (homepage, navigation)
  - CI smoke: 4 tests (optional)

### Coverage
- ✅ User registration flow
- ✅ User login/logout flow
- ✅ Event creation workflow
- ✅ Event editing workflow
- ✅ Event deletion workflow
- ✅ Profile management
- ✅ Authentication guards
- ✅ Form validation
- ✅ Error handling
- ✅ Full user journey

### Duration
- **Total E2E suite:** ~3-5 minutes (all browsers)
- **Chromium only:** ~1.5-2 minutes
- **CI optimized:** ~2-3 minutes (parallel execution)

---

## 🧪 Testing Best Practices

### 1. Use Data Test IDs
```html
<!-- Add to components -->
<button data-test-id="login-button">Login</button>
<form data-test-id="registration-form">...</form>
```

```typescript
// In tests
await page.click('[data-test-id="login-button"]');
```

### 2. Use Page Object Model

**`tests/e2e/pages/LoginPage.ts`:**

```typescript
import { Page } from '@playwright/test';

export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/concert/login');
  }

  async login(email: string, password: string) {
    await this.page.fill('[name="email"]', email);
    await this.page.fill('[name="password"]', password);
    await this.page.click('button[type="submit"]');
  }

  async getErrorMessage() {
    return await this.page.locator('.error-message').textContent();
  }
}
```

### 3. Clean Up Test Data

```typescript
test.afterEach(async ({ page, testUser }) => {
  // Delete created events
  // Delete test user
  // Clear localStorage
  await page.evaluate(() => localStorage.clear());
});
```

### 4. Use Stable Locators
```typescript
// ✅ Good
await page.click('[data-test-id="submit-button"]');
await page.click('button:has-text("Submit")');

// ❌ Avoid
await page.click('.btn-primary'); // CSS classes can change
await page.click('button:nth-child(3)'); // Position can change
```

---

## 🚀 Quick Start Commands

```bash
# Install Playwright browsers
npx playwright install --with-deps

# Run tests
npm run test:e2e

# Run tests in UI mode
npx playwright test --ui

# Generate code for new test
npx playwright codegen http://localhost:3000/concert/

# View test report
npx playwright show-report
```

---

## 📋 CI/CD Integration

**Already configured in `.github/workflows/ci.yml`:**

```yaml
e2e-tests:
  needs: [frontend-tests, backend-tests]
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20.x'
    - name: Install dependencies
      run: npm ci
      working-directory: main_frontend/concert1
    - name: Install Playwright Browsers
      run: npx playwright install --with-deps
      working-directory: main_frontend/concert1
    - name: Run E2E tests
      run: npm run test:e2e
      working-directory: main_frontend/concert1
    - name: Upload Playwright Report
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: playwright-report
        path: main_frontend/concert1/playwright-report/
```

---

## ✅ Success Criteria

✅ 30+ E2E tests implemented  
✅ All critical user flows covered  
✅ Tests pass on all browsers (Chromium, Firefox, WebKit)  
✅ E2E suite completes in < 5 minutes  
✅ Tests run reliably in CI/CD  
✅ Test reports generated with screenshots/videos on failure  
✅ Page Object Model implemented for maintainability  
✅ Test data cleanup implemented  

---

**Estimated Time:** 6-8 hours  
**Complexity:** Medium-High  
**Impact:** High (comprehensive integration testing + user flow validation)
