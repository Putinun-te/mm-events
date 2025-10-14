# Concert Booking Platform - MM Concerts

A full-stack concert booking and event management platform built with Spring Boot and Nuxt 4.

## 🚀 Quick Start

### Start the Application
```bash
docker compose up -d
```

**Access Points:**
- 🌐 **Frontend:** http://localhost:3000/concert/
- 🔧 **Backend API:** http://localhost:8080
- 🗄️ **MySQL:** localhost:3306

### Default Test Account
```
Email: john@example.com
Password: password123
```

## 📋 Project Structure

```
.
├── main_backend/          # Spring Boot REST API (Java 21)
│   ├── src/main/java/com/concert/
│   │   ├── controller/    # REST Controllers
│   │   ├── service/       # Business Logic
│   │   ├── repository/    # Data Access
│   │   ├── model/         # Entities
│   │   ├── dto/           # Data Transfer Objects
│   │   ├── security/      # JWT & Security Config
│   │   └── config/        # Application Config
│   └── src/test/java/     # Unit & Integration Tests
│
├── main_frontend/concert1/ # Nuxt 4 Application
│   ├── app/
│   │   ├── pages/         # Route Pages
│   │   ├── components/    # Vue Components
│   │   ├── composables/   # Reusable Logic
│   │   ├── layouts/       # Page Layouts
│   │   └── assets/        # Static Assets
│   ├── server/            # API Routes (SSR)
│   ├── middleware/        # Route Middleware
│   └── tests/             # E2E Tests (Cypress)
│
├── init.sql               # Database Schema & Sample Data
└── docker-compose.yml     # Container Orchestration
```

## 🎯 Core Features

### Authentication & Authorization
- ✅ JWT-based authentication
- ✅ Remember Me functionality (localStorage/sessionStorage)
- ✅ Protected routes with middleware
- ✅ Silent auth redirects (no "Unauthorized" messages)
- ✅ Role-based access control

### Event Management
- ✅ Create, edit, and delete events
- ✅ Event categories (Music, Sports, Tech, Art, Food, Business, Other)
- ✅ Rich event details (title, description, location, dates, images)
- ✅ User's own events dashboard

### Booking System
- ✅ Book tickets for events
- ✅ View booking history
- ✅ Cancel bookings
- ✅ Quantity selection
- ✅ Real-time availability

### User Account
- ✅ Profile management
- ✅ Edit personal information
- ✅ View booking history
- ✅ Secure logout

## 🧪 Testing Strategy

### Testing Architecture

This project uses a **3-tier testing approach** with **Cypress** as the unified E2E/component testing framework:

```
Backend Testing:
  ├─ Unit Tests → Maven (Java)
  ├─ Integration Tests → Maven + MySQL (GitHub Actions)
  └─ E2E API Tests → Cypress

Frontend Testing:
  ├─ Component Tests → Cypress
  └─ E2E Full Stack → Cypress
```

### Backend Testing

#### 1. Unit Tests (Maven)
**Run locally:**
```bash
cd main_backend
./mvnw clean test -P unit-tests -B
```
- Fast, no external dependencies
- Excludes integration and Docker tests

#### 2. Integration Tests (Maven + MySQL)
**Run locally (requires Docker):**
```bash
cd main_backend
./mvnw test -P integration-tests -B
```
- Tests with real MySQL database
- Uses Testcontainers for Docker MySQL

#### 3. E2E API Tests (Cypress)
**Run locally:**
```bash
cd main_backend/cypress-tests
npm install
npx cypress run          # Headless
npx cypress open         # Interactive UI
```

**View Coverage Report:**
```bash
open main_backend/target/site/jacoco/index.html
```

### Frontend Testing

#### 1. Component Tests (Cypress)
**Run locally:**
```bash
cd main_frontend/concert1
npm install
npx cypress run --component    # Headless
npx cypress open --component   # Interactive UI
```
- Tests Vue components in isolation
- No backend required

#### 2. Full Stack E2E Tests (Cypress)
**Run locally (requires backend + MySQL):**
```bash
cd main_frontend/concert1
npm install
npx cypress run --e2e     # Headless
npx cypress open --e2e    # Interactive UI
```
- Tests complete user workflows
- Requires MySQL + Backend + Frontend running

### GitHub Actions CI/CD

**4 automated workflows on every push:**

1. **backend-tests.yml** - Maven unit + integration tests
2. **backend-e2e.yml** - Cypress API tests
3. **frontend-tests.yml** - Cypress component tests
4. **frontend-e2e.yml** - Cypress full stack E2E tests

**View test results:** Check the Actions tab in GitHub

### System Health Check

Run the stability check script:
```bash
./check-stability.sh
```

Checks:
- ✅ Docker containers status
- ✅ MySQL connectivity
- ✅ Backend API health
- ✅ Frontend serving
- ✅ Error log scanning

## 🛠️ Development

### Prerequisites
- Docker & Docker Compose
- JDK 21 (for local backend development)
- Node.js 18+ (for local frontend development)

### Local Backend Development
```bash
cd main_backend
mvn spring-boot:run
```

### Local Frontend Development
```bash
cd main_frontend/concert1
npm install
npm run dev
```

## 🗄️ Database

### Schema
- **Users:** Authentication and profiles
- **Events:** Concert/event information
- **Tickets:** Event ticket inventory
- **Bookings:** User ticket purchases
- **Orders:** Payment records
- **Favorites:** User saved events

### Reset Database
```bash
docker compose down -v
docker compose up -d
```

Sample data includes:
- 21 test users
- 7 sample events (various categories)
- 14 ticket types

## 🔒 Security Features

- JWT token authentication
- Password hashing (BCrypt)
- CORS configuration
- SQL injection prevention (JPA)
- XSS protection
- Secure session handling

## 📚 Documentation

### Testing Documentation
- 📖 **[Cypress Testing Complete](CYPRESS_TESTING_COMPLETE.md)** - Complete testing architecture
- 📖 **[Testing Quick Reference](TESTING_QUICK_REFERENCE.md)** - Quick command reference
- 📖 **[Testing Clean Restart](TESTING_CLEAN_RESTART.md)** - Testing implementation details

### Feature Documentation
- 📖 **[Remember Me Testing Guide](REMEMBER_ME_TESTING.md)** - Auth flow testing
- 📖 **[Remember Me Fix Summary](REMEMBER_ME_FIX_SUMMARY.md)** - Implementation details
- 📖 **[Unauthorized Handling](UNAUTHORIZED_HANDLING.md)** - Error handling guide

### System Documentation
- 📖 **[Stability Report](STABILITY_REPORT.md)** - System health status
- 📖 **[Cleanup Summary](CLEANUP_SUMMARY.md)** - Repository maintenance

## 🐛 Troubleshooting

### Container Issues
```bash
# View logs
docker logs concert-backend
docker logs concert-frontend
docker logs concert-mysql

# Restart specific service
docker compose restart frontend

# Full rebuild
docker compose down
docker compose up -d --build
```

### Port Conflicts
If ports are already in use:
```bash
# Check what's using the port
lsof -i :3000
lsof -i :8080
lsof -i :3306

# Kill the process or change ports in docker-compose.yml
```

### Frontend Build Errors
```bash
cd main_frontend/concert1
rm -rf node_modules .nuxt .output
npm install
```

### Backend Test Failures
Ensure Docker is running (tests use Testcontainers):
```bash
docker ps
```

## 🚦 System Status (October 2025)

### Completed Features ✅
- [x] Full authentication system with JWT
- [x] Remember Me functionality
- [x] Event CRUD operations
- [x] Booking system with cancellation
- [x] User profile management
- [x] Event categories
- [x] Protected routes with middleware
- [x] Silent auth redirects
- [x] Comprehensive testing (121 backend tests)
- [x] **Cypress-only E2E testing** (Backend API + Frontend)
- [x] **Cypress component testing** (Frontend)
- [x] **4 GitHub Actions workflows** (Automated CI/CD)
- [x] Docker containerization
- [x] System health monitoring

### Testing Infrastructure ✅
- [x] **Maven Unit Tests** - Java unit testing
- [x] **Maven Integration Tests** - Database integration testing
- [x] **Cypress API Tests** - Backend E2E testing
- [x] **Cypress Component Tests** - Frontend component testing
- [x] **Cypress Full Stack E2E** - Complete user workflow testing
- [x] **GitHub Actions CI/CD** - Automated testing on every push
- [x] **JaCoCo Coverage** - 80% code coverage target

### Recent Updates 🆕
- 🧪 **Oct 15, 2025:** Complete Cypress testing implementation (backend + frontend)
- 🔧 **Oct 14, 2025:** Fixed npm install issues in CI/CD workflows
- ✨ **Oct 14, 2025:** Improved Remember Me functionality
- 🧹 **Oct 14, 2025:** Repository cleanup (removed 9 unnecessary files)
- 🔒 **Oct 13, 2025:** Enhanced unauthorized user handling
- 📊 **Oct 13, 2025:** Added stability monitoring tools

## 📝 Notes

- Tests are **not** run automatically on `docker compose up`
- Backend tests require Docker (Testcontainers for MySQL)
- Frontend uses Nuxt 4 with Vue 3 Composition API
- Backend uses Spring Boot 3.2.0 with Java 21
- Database schema is initialized via `init.sql`

## 🔗 Related Links

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Nuxt 4 Documentation](https://nuxt.com)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📄 License

This is a development project for the MoringMores Concerts platform.

---

**Last Updated:** October 15, 2025  
**Testing Framework:** Cypress (unified E2E + component testing)  
**CI/CD:** GitHub Actions (4 automated workflows)


