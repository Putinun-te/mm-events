# E2E Tests Setup and Execution Guide

## Overview
This directory contains End-to-End (E2E) tests for the Concert application using Vitest and @nuxt/test-utils.

## Quick Start

### Run E2E Tests Locally

1. **Start the backend server:**
   ```bash
   cd main_backend
   mvn spring-boot:run -Dspring-boot.run.profiles=test
   ```

2. **Start the frontend dev server:**
   ```bash
   cd main_frontend/concert1
   npm run dev
   ```

3. **Run E2E tests:**
   ```bash
   cd main_frontend/concert1
   npm run test:e2e
   ```

### Run E2E Tests in Watch Mode
```bash
npm run test:e2e:watch
```

### Run Specific Test File
```bash
npx vitest run --config vitest.e2e.config.ts test/e2e/auth.e2e.test.ts
```

## Test Files

| File | Description | Coverage |
|------|-------------|----------|
| `auth.e2e.test.ts` | Authentication flows | Login, registration, validation, navigation |
| `events.e2e.test.ts` | Event browsing | Listing, search, details, quantity controls |
| `navigation.e2e.test.ts` | Navigation flows | Menu, routing, back/forward, 404 handling |
| `cart.e2e.test.ts` | Shopping cart | Cart display, items, totals, checkout |
| `create-event.e2e.test.ts` | Event creation | Form validation, uploads, auth requirement |
| `user-journey.e2e.test.ts` | Full user journeys | Complete workflows end-to-end |

## CI/CD Integration

E2E tests run automatically on GitHub Actions for:
- ✅ Pushes to `main` branch
- ✅ Pushes to `develop` branch  
- ✅ Pushes to `release/*` branches

### Workflow Job: `test-frontend-e2e`

The E2E test job in `.github/workflows/full-pipeline.yml`:
1. Sets up MySQL service container
2. Starts backend Spring Boot server
3. Waits for backend to be ready
4. Installs frontend dependencies
5. Starts Nuxt dev server
6. Waits for frontend to be ready
7. Runs E2E tests
8. Uploads test results as artifacts
9. Cleans up servers

## Prerequisites

### Local Development
- **Backend:** Java 21, Maven, MySQL
- **Frontend:** Node.js 20+, npm
- **Database:** MySQL 8.0 (or use Docker)

### Environment Variables
```bash
# Backend
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/concert_db
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=yourpassword

# Frontend
NUXT_PUBLIC_API_BASE=http://localhost:8080
```

## Test Structure

### Standard E2E Test Pattern
```typescript
import { describe, it, expect } from 'vitest'
import { setup, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Feature Name', async () => {
  await setup({
    server: true,
    browser: true
  })

  it('should test specific behavior', async () => {
    const page = await createPage('/route')
    await page.waitForSelector('selector')
    
    // Your test logic
    const element = await page.$('selector')
    expect(element).toBeTruthy()
  })
})
```

## Common Patterns

### Wait for Element
```typescript
await page.waitForSelector('form')
```

### Fill Input Field
```typescript
await page.fill('input[name="username"]', 'testuser')
```

### Click Button
```typescript
const button = await page.$('button[type="submit"]')
await button?.click()
```

### Navigate and Wait
```typescript
await link.click()
await page.waitForNavigation()
```

### Get Page Content
```typescript
const content = await page.content()
const text = await page.textContent('selector')
```

### Handle Timeout
```typescript
await page.waitForTimeout(2000) // Wait 2 seconds
```

## Debugging E2E Tests

### Enable Verbose Logging
```bash
DEBUG=nuxt:* npm run test:e2e
```

### Run Single Test with Console Output
```typescript
it('should test something', async () => {
  console.log('Starting test...')
  const page = await createPage('/')
  console.log('Page URL:', page.url())
  console.log('Page title:', await page.title())
})
```

### Increase Timeout for Slow Tests
In `vitest.e2e.config.ts`:
```typescript
testTimeout: 60000, // 60 seconds
```

## Troubleshooting

### Backend Not Starting
```bash
# Check if port 8080 is in use
lsof -i :8080

# Kill process if needed
kill -9 <PID>
```

### Frontend Not Starting
```bash
# Check if port 3000 is in use
lsof -i :3000

# Kill process if needed  
kill -9 <PID>
```

### MySQL Connection Issues
```bash
# Check MySQL status
brew services list | grep mysql

# Start MySQL
brew services start mysql

# Or use Docker
docker run -d -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=concert_db \
  mysql:8.0
```

### Test Failures in CI
- Check GitHub Actions logs for the specific failure
- Verify environment variables are set correctly
- Ensure all services started successfully
- Check artifact uploads for detailed test results

## Best Practices

1. **Keep Tests Independent:** Each test should work in isolation
2. **Use Proper Waits:** Always wait for elements before interacting
3. **Clean Up State:** Reset any changes made during tests
4. **Use Descriptive Names:** Test names should clearly describe what they test
5. **Mock External Services:** Don't rely on external APIs
6. **Handle Async Properly:** Always await async operations
7. **Test Real User Flows:** Simulate actual user behavior
8. **Check Error States:** Test both success and failure paths

## Coverage Goals

- ✅ All major user journeys covered
- ✅ Authentication flows tested
- ✅ CRUD operations verified
- ✅ Navigation paths validated
- ✅ Error handling checked
- ✅ Form validations tested

## Future Enhancements

- [ ] Add visual regression testing
- [ ] Add accessibility (a11y) tests
- [ ] Add performance monitoring
- [ ] Add mobile viewport tests
- [ ] Add API mocking with MSW
- [ ] Add screenshot capture on failure
- [ ] Add video recording for failed tests
- [ ] Add cross-browser testing with Playwright

## Resources

- [Vitest Documentation](https://vitest.dev/)
- [@nuxt/test-utils](https://nuxt.com/docs/getting-started/testing)
- [Playwright Documentation](https://playwright.dev/)
- [Testing Library Best Practices](https://testing-library.com/docs/guiding-principles)
