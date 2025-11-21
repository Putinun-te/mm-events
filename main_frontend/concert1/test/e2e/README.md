# E2E Tests

End-to-End tests for the Concert application using Vitest and API integration testing.

## Structure

- `api-integration.e2e.test.ts` - **Primary E2E tests** - API-based integration tests (recommended)
- `auth.e2e.test.ts` - Authentication flow tests (browser-based, optional)
- `events.e2e.test.ts` - Events listing and details tests (browser-based, optional)
- `navigation.e2e.test.ts` - Navigation and routing tests (browser-based, optional)
- `cart.e2e.test.ts` - Shopping cart functionality tests (browser-based, optional)
- `create-event.e2e.test.ts` - Event creation form tests (browser-based, optional)

## Running E2E Tests

```bash
# Run primary API integration E2E tests (recommended)
npm run test:e2e

# Run all E2E tests (including browser-based)
npm run test:e2e:all

# Run E2E tests in watch mode
npm run test:e2e:watch

# Run with specific file
npx vitest run --config vitest.e2e.config.ts test/e2e/api-integration.e2e.test.ts
```

## Test Approach

### API Integration Tests (Primary)
The `api-integration.e2e.test.ts` file tests the full stack through HTTP requests:
- ✅ No browser automation required
- ✅ Fast execution
- ✅ No TextEncoder/Node compatibility issues
- ✅ Tests actual API contracts
- ✅ Suitable for CI/CD

### Browser-based Tests (Optional)
Other test files use `@nuxt/test-utils` for browser automation:
- Useful for UI/UX validation
- Slower execution
- May have Node compatibility issues in CI
- Better for local development testing

## Prerequisites

1. Ensure the backend server is running on `http://localhost:8080`
2. Ensure the Nuxt dev server is running on `http://localhost:3000`
3. Database should be initialized with test data

## Test Coverage

The E2E tests cover:

### Authentication
- ✅ Login page display and form validation
- ✅ Registration page display and form validation
- ✅ Navigation between login and register
- ✅ Authentication error handling

### Events
- ✅ Events listing page
- ✅ Search and filter functionality
- ✅ Event details page navigation
- ✅ Event details display
- ✅ Quantity controls
- ✅ Add to cart/buy buttons

### Navigation
- ✅ Home page navigation
- ✅ Navigation menu functionality
- ✅ Back/forward navigation
- ✅ State persistence across navigation
- ✅ 404 error handling

### Shopping Cart
- ✅ Cart page display
- ✅ Empty cart message
- ✅ Cart items display
- ✅ Checkout and action buttons
- ✅ Total price calculation

### Event Creation
- ✅ Create event page display
- ✅ Authentication requirement
- ✅ Form fields validation
- ✅ Required field validation
- ✅ Photo upload capability
- ✅ Date/time inputs
- ✅ Price and capacity fields

## Configuration

E2E tests use the `vitest.e2e.config.ts` configuration file with:
- Extended timeout: 30 seconds
- Browser environment: jsdom
- Test pattern: `test/e2e/**/*.e2e.test.ts`

## Best Practices

1. **Keep tests independent**: Each test should be able to run in isolation
2. **Use appropriate selectors**: Prefer data-testid > semantic selectors > CSS classes
3. **Add proper waits**: Use `waitForSelector` or `waitForTimeout` for async operations
4. **Clean up state**: Reset any state changes after tests
5. **Mock external services**: Use MSW or similar for API mocking when needed

## Troubleshooting

### Tests timing out
- Increase `testTimeout` in `vitest.e2e.config.ts`
- Ensure dev server is running
- Check if backend API is responding

### Elements not found
- Add `waitForSelector` before interacting with elements
- Check if selectors match the actual DOM structure
- Use browser dev tools to inspect the page

### Navigation failures
- Ensure routes are properly configured in Nuxt
- Check if authentication redirects are interfering
- Verify that navigation guards are not blocking navigation

## CI/CD Integration

E2E tests are integrated into the GitHub Actions workflow:

```yaml
- name: Run E2E Tests
  run: npm run test:e2e
  env:
    BACKEND_URL: http://localhost:8080
    NUXT_PUBLIC_API_BASE: http://localhost:8080
```

## Future Enhancements

- [ ] Add visual regression testing with Playwright
- [ ] Add accessibility testing with axe-core
- [ ] Add performance monitoring
- [ ] Add mobile viewport testing
- [ ] Add cross-browser testing
- [ ] Add API response mocking
- [ ] Add test data seeding and cleanup
- [ ] Add screenshot capture on failure
