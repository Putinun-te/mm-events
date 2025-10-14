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

## 🧪 Testing

### Backend Tests with Coverage

**Local (macOS, JDK 21 required):**
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report -f main_backend/pom.xml
```

**Docker:**
```bash
docker compose run --rm backend-tests
```

**View Coverage Report:**
```bash
open main_backend/target/site/jacoco/index.html
```

### Frontend E2E Tests (Cypress)

**Run E2E Tests:**
```bash
cd main_frontend/concert1
npm run test:e2e
```

**CI/CD:** Tests run automatically via `.github/workflows/frontend-e2e.yml`

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

- 📖 **[Remember Me Testing Guide](REMEMBER_ME_TESTING.md)** - Auth flow testing
- 📖 **[Remember Me Fix Summary](REMEMBER_ME_FIX_SUMMARY.md)** - Implementation details
- 📖 **[Stability Report](STABILITY_REPORT.md)** - System health status
- 📖 **[Cleanup Summary](CLEANUP_SUMMARY.md)** - Repository maintenance
- 📖 **[Unauthorized Handling](UNAUTHORIZED_HANDLING.md)** - Error handling guide

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
- [x] E2E test framework (Cypress)
- [x] CI/CD pipelines (GitHub Actions)
- [x] Docker containerization
- [x] System health monitoring

### Recent Updates 🆕
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

This is a development project for the MM Concerts platform.

---

**Last Updated:** October 14, 2025


