# Backend E2E Tests with Cypress

This directory contains end-to-end tests for the backend REST API using Cypress.

## Setup

### Prerequisites
- Node.js 18+ and npm
- Backend server running on `http://localhost:8080`
- MySQL database running and configured

### Installation

```bash
cd main_backend/cypress-tests
npm install
```

## Running Tests

### Interactive Mode (Cypress UI)
```bash
npm run cypress:open
```

### Headless Mode (CI/CD)
```bash
npm run cypress:run
```

### Run Specific Test Suites

**Auth Tests Only:**
```bash
npm run test:e2e:auth
```

**Events Tests Only:**
```bash
npm run test:e2e:events
```

**Bookings Tests Only:**
```bash
npm run test:e2e:bookings
```

## Test Structure

```
cypress/
├── e2e/
│   ├── auth/
│   │   └── auth-api.cy.js         # Authentication endpoint tests
│   ├── events/
│   │   └── events-api.cy.js       # Events endpoint tests
│   └── bookings/
│       └── bookings-api.cy.js     # Bookings endpoint tests
├── support/
│   ├── commands.js                # Custom Cypress commands
│   └── e2e.js                     # Support file
└── cypress.config.js              # Cypress configuration
```

## Test Coverage

### Auth API (`/api/auth`)
- ✅ User registration
- ✅ User login
- ✅ Protected endpoint access
- ✅ Token validation
- ✅ Error handling (invalid credentials, duplicate users)

### Events API (`/api/events`)
- ✅ Create event (authenticated)
- ✅ List all events (public)
- ✅ Get organizer's events
- ✅ Get event by ID
- ✅ Pagination support
- ✅ Authorization checks
- ✅ Error handling (invalid dates, not found)

### Bookings API (`/api/bookings`)
- ✅ Create booking
- ✅ Get user's bookings
- ✅ Get booking by ID
- ✅ Cancel booking
- ✅ Full booking lifecycle
- ✅ Authorization checks
- ✅ Error handling

## Custom Commands

### Authentication
```javascript
// Login and get JWT token
cy.login('username', 'password')

// Register new user
cy.register('username', 'email@example.com', 'password', 'Full Name')
```

### Authenticated Requests
```javascript
// Make authenticated API request
cy.authenticatedRequest('GET', '/events/me')
```

### Helper Commands
```javascript
// Create event
cy.createEvent(eventData)

// Create booking
cy.createBooking(bookingData)
```

## Configuration

Edit `cypress.config.js` to change:
- Base URL (default: `http://localhost:8080`)
- API URL (default: `http://localhost:8080/api`)
- Timeouts and viewport settings
- Video/screenshot settings

## CI/CD Integration

Tests run automatically in GitHub Actions:
- Workflow: `.github/workflows/backend-e2e-tests.yml`
- Runs on push to main branches
- Uploads videos and screenshots as artifacts
- Reports test results

## Troubleshooting

### Backend Not Running
Ensure backend is running before tests:
```bash
cd main_backend
./mvnw spring-boot:run
```

### Database Issues
Verify MySQL is running and accessible:
```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```

### Port Conflicts
If port 8080 is in use, update `baseUrl` in `cypress.config.js`

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Unique Data**: Use timestamps for unique test data
3. **Cleanup**: Tests create data but don't require manual cleanup (each test uses unique identifiers)
4. **Error Handling**: Always use `failOnStatusCode: false` when testing error cases
5. **Assertions**: Verify status codes, response structure, and data integrity

## Contributing

When adding new tests:
1. Follow existing patterns in test files
2. Add custom commands to `support/commands.js` if reusable
3. Update this README with new test coverage
4. Ensure tests pass both locally and in CI

## Reports

After running tests:
- **Videos**: `cypress/videos/`
- **Screenshots** (on failure): `cypress/screenshots/`
- **Test Results**: Console output and GitHub Actions summary
