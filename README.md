# 🎵 MM Concerts - Concert Booking Platform# Concert Booking Platform - MM Concerts



<div align="center">A full-stack concert booking and event management platform built with Spring Boot and Nuxt 4.



![Build Status](https://img.shields.io/github/actions/workflow/status/MorningMores/develop/ci-tests.yml?branch=main)## 🚀 Quick Start

![Coverage](https://img.shields.io/badge/coverage-85.51%25-yellow)

![License](https://img.shields.io/badge/license-MIT-blue)### Start the Application

![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2-brightgreen)```bash

![Nuxt](https://img.shields.io/badge/Nuxt-4.0-00DC82)docker compose up -d

```

A modern, full-stack concert booking and event management platform with real-time availability, secure authentication, and comprehensive event management features.

**Access Points:**

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [API](#-api) • [Contributing](#-contributing)

# Concert Project

</div>

This repository contains the backend (Spring Boot) and frontend (Nuxt 4) for the Concert application.

---

- Backend: `main_backend/`

## 📋 Table of Contents- Frontend: `main_frontend/concert1/`



- [Overview](#-overview)Documentation has been consolidated into the `doce/` folder. See `doce/INDEX.md` for an index of moved documents.

- [Features](#-features)

- [Tech Stack](#-tech-stack)Password: password123

- [Quick Start](#-quick-start)```

- [Project Structure](#-project-structure)

- [Development](#-development)## 📋 Project Structure

- [Testing](#-testing)

- [API Documentation](#-api-documentation)```

- [Deployment](#-deployment).

- [Documentation](#-documentation)├── main_backend/          # Spring Boot REST API (Java 21)

- [Contributing](#-contributing)│   ├── src/main/java/com/concert/

- [License](#-license)│   │   ├── controller/    # REST Controllers

│   │   ├── service/       # Business Logic

---│   │   ├── repository/    # Data Access

│   │   ├── model/         # Entities

## 🎯 Overview│   │   ├── dto/           # Data Transfer Objects

│   │   ├── security/      # JWT & Security Config

MM Concerts is a comprehensive event management platform that enables users to discover concerts, manage bookings, and create events. Built with modern technologies, it provides a seamless experience for both event organizers and attendees.│   │   └── config/        # Application Config

│   └── src/test/java/     # Unit & Integration Tests

### Key Highlights│

├── main_frontend/concert1/ # Nuxt 4 Application

- 🎫 **Real-time Booking** - Instant seat availability and confirmation│   ├── app/

- 🔐 **Secure Authentication** - JWT-based auth with session management│   │   ├── pages/         # Route Pages

- 📱 **Responsive Design** - Mobile-first, works on all devices│   │   ├── components/    # Vue Components

- 🎨 **Modern UI** - Sleek interface with Nuxt 4 and Vue 3│   │   ├── composables/   # Reusable Logic

- 🚀 **High Performance** - Optimized backend with Spring Boot 3│   │   ├── layouts/       # Page Layouts

- 🧪 **Well Tested** - 798+ tests with 85%+ coverage│   │   └── assets/        # Static Assets

- 🐳 **Docker Ready** - Full containerization support│   ├── server/            # API Routes (SSR)

- 🔄 **CI/CD Pipeline** - Automated testing and deployment│   ├── middleware/        # Route Middleware

│   └── tests/             # E2E Tests (Cypress)

---│

├── init.sql               # Database Schema & Sample Data

## ✨ Features└── docker-compose.yml     # Container Orchestration

```

### For Users

- 🔍 **Event Discovery** - Browse concerts by category, date, location## 🎯 Core Features

- 🎟️ **Ticket Booking** - Easy booking with quantity selection

- 📅 **My Bookings** - View and manage all your tickets### Authentication & Authorization

- 👤 **Profile Management** - Update personal information- ✅ JWT-based authentication

- 🔔 **Notifications** - Real-time booking confirmations- ✅ Remember Me functionality (localStorage/sessionStorage)

- 💳 **Secure Checkout** - Safe payment processing- ✅ Protected routes with middleware

- ❌ **Cancellation** - Cancel bookings with refund support- ✅ Silent auth redirects (no "Unauthorized" messages)

- ✅ Role-based access control

### For Event Organizers

- ➕ **Create Events** - Add new concerts with details### Event Management

- ✏️ **Edit Events** - Update event information- ✅ Create, edit, and delete events

- 📊 **Event Dashboard** - Track bookings and sales- ✅ Event categories (Music, Sports, Tech, Art, Food, Business, Other)

- 🗑️ **Delete Events** - Remove cancelled events- ✅ Rich event details (title, description, location, dates, images)

- 📈 **Analytics** - View booking statistics- ✅ User's own events dashboard

- 🖼️ **Image Upload** - Add event posters and galleries

### Booking System

### Admin Features- ✅ Book tickets for events

- 👥 **User Management** - Manage user accounts- ✅ View booking history

- 🎭 **Event Moderation** - Review and approve events- ✅ Cancel bookings

- 📊 **System Analytics** - Platform-wide statistics- ✅ Quantity selection

- 🔧 **Configuration** - System settings management- ✅ Real-time availability



---### User Account

- ✅ Profile management

## 🛠️ Tech Stack- ✅ Edit personal information

- ✅ View booking history

### Backend- ✅ Secure logout

- **Framework**: Spring Boot 3.2

- **Language**: Java 21## 🧪 Testing

- **Database**: MySQL 8.0

- **Security**: Spring Security + JWT### Backend Tests with Coverage

- **Testing**: JUnit 5, Mockito, Testcontainers

- **Build**: Maven**Local (macOS, JDK 21 required):**

- **Coverage**: JaCoCo (97% instructions, 89% branches)```bash

JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report -f main_backend/pom.xml

### Frontend```

- **Framework**: Nuxt 4

- **Language**: TypeScript**Docker:**

- **UI Framework**: Vue 3 (Composition API)```bash

- **State**: Composables & Piniadocker compose run --rm backend-tests

- **Testing**: Vitest, Vue Test Utils```

- **Build**: Vite

- **Coverage**: Vitest (91% statements, 85% branches)**View Coverage Report:**

```bash

### DevOpsopen main_backend/target/site/jacoco/index.html

- **Containerization**: Docker & Docker Compose```

- **CI/CD**: GitHub Actions

- **Version Control**: Git### Frontend E2E Tests (Cypress)

- **Code Quality**: ESLint, Prettier

- **API Testing**: Postman**Run E2E Tests:**

```bash

---cd main_frontend/concert1

npm run test:e2e

## 🚀 Quick Start```



### Prerequisites**CI/CD:** Tests run automatically via `.github/workflows/frontend-e2e.yml`



- **Docker** & **Docker Compose** (recommended)### System Health Check

- **Java 21** (for backend development)

- **Node.js 20+** (for frontend development)Run the stability check script:

- **MySQL 8.0** (if not using Docker)```bash

./check-stability.sh

### Option 1: Docker (Recommended)```



```bashChecks:

# Clone the repository- ✅ Docker containers status

git clone https://github.com/MorningMores/develop.git- ✅ MySQL connectivity

cd develop- ✅ Backend API health

- ✅ Frontend serving

# Create environment file- ✅ Error log scanning

cp .env.example .env

## 🛠️ Development

# Start all services

docker-compose up -d### Prerequisites

- Docker & Docker Compose

# View logs- JDK 21 (for local backend development)

docker-compose logs -f- Node.js 18+ (for local frontend development)

```

### Local Backend Development

**Access the application:**```bash

- Frontend: http://localhost:3000cd main_backend

- Backend API: http://localhost:8080mvn spring-boot:run

- API Docs: http://localhost:8080/swagger-ui.html```



### Option 2: Manual Setup### Local Frontend Development

```bash

#### Backend Setupcd main_frontend/concert1

npm install

```bashnpm run dev

cd main_backend```



# Install dependencies & run tests## 🗄️ Database

mvn clean install

### Schema

# Run the application- **Users:** Authentication and profiles

mvn spring-boot:run- **Events:** Concert/event information

- **Tickets:** Event ticket inventory

# Or build and run JAR- **Bookings:** User ticket purchases

mvn package- **Orders:** Payment records

java -jar target/concert-backend-1.0.0.jar- **Favorites:** User saved events

```

### Reset Database

Backend will start on http://localhost:8080```bash

docker compose down -v

#### Frontend Setupdocker compose up -d

```

```bash

cd main_frontend/concert1Sample data includes:

- 21 test users

# Install dependencies- 7 sample events (various categories)

npm install- 14 ticket types



# Run development server## 🔒 Security Features

npm run dev

- JWT token authentication

# Build for production- Password hashing (BCrypt)

npm run build- CORS configuration

npm run preview- SQL injection prevention (JPA)

```- XSS protection

- Secure session handling

Frontend will start on http://localhost:3000

## 📚 Documentation

---

- 📖 **[Remember Me Testing Guide](REMEMBER_ME_TESTING.md)** - Auth flow testing

## 📁 Project Structure- 📖 **[Remember Me Fix Summary](REMEMBER_ME_FIX_SUMMARY.md)** - Implementation details

- 📖 **[Stability Report](STABILITY_REPORT.md)** - System health status

```- 📖 **[Cleanup Summary](CLEANUP_SUMMARY.md)** - Repository maintenance

develop/- 📖 **[Unauthorized Handling](UNAUTHORIZED_HANDLING.md)** - Error handling guide

├── .github/

│   ├── workflows/              # GitHub Actions CI/CD## 🐛 Troubleshooting

│   │   ├── ci-tests.yml       # Main test pipeline

│   │   ├── frontend-tests.yml # Frontend tests### Container Issues

│   │   ├── backend-ci.yml     # Backend tests```bash

│   │   └── docker-image.yml   # Docker builds# View logs

│   ├── ISSUE_TEMPLATE/        # Issue templatesdocker logs concert-backend

│   └── PULL_REQUEST_TEMPLATE.mddocker logs concert-frontend

│docker logs concert-mysql

├── main_backend/              # Spring Boot API

│   ├── src/main/java/com/concert/# Restart specific service

│   │   ├── controller/        # REST endpointsdocker compose restart frontend

│   │   ├── service/           # Business logic

│   │   ├── repository/        # Data access layer# Full rebuild

│   │   ├── model/             # JPA entitiesdocker compose down

│   │   ├── dto/               # Data transfer objectsdocker compose up -d --build

│   │   ├── security/          # Auth & JWT```

│   │   └── config/            # Spring configuration

│   ├── src/test/java/         # Unit & integration tests### Port Conflicts

│   └── pom.xml                # Maven configurationIf ports are already in use:

│```bash

├── main_frontend/concert1/    # Nuxt 4 Application# Check what's using the port

│   ├── app/lsof -i :3000

│   │   ├── pages/             # Route pageslsof -i :8080

│   │   ├── components/        # Vue componentslsof -i :3306

│   │   ├── composables/       # Reusable logic

│   │   ├── layouts/           # Page layouts# Kill the process or change ports in docker-compose.yml

│   │   └── assets/            # Static assets```

│   ├── server/                # Server routes (SSR)

│   ├── test/unit/             # Unit tests (Vitest)### Frontend Build Errors

│   ├── nuxt.config.ts         # Nuxt configuration```bash

│   └── package.json           # Dependenciescd main_frontend/concert1

│rm -rf node_modules .nuxt .output

├── doce/                      # Documentationnpm install

│   ├── README.md              # Documentation index```

│   ├── QUICK_START_GUIDE.md   # Getting started

│   ├── CI_CD_SETUP.md         # CI/CD guide### Backend Test Failures

│   ├── TESTING_ROADMAP.md     # Testing strategyEnsure Docker is running (tests use Testcontainers):

│   └── ...                    # Additional docs```bash

│docker ps

├── docker-compose.yml         # Docker orchestration```

├── docker-compose.prod.yml    # Production config

├── init.sql                   # Database initialization## 🚦 System Status (October 2025)

├── .env.example               # Environment template

└── README.md                  # This file### Completed Features ✅

```- [x] Full authentication system with JWT

- [x] Remember Me functionality

---- [x] Event CRUD operations

- [x] Booking system with cancellation

## 💻 Development- [x] User profile management

- [x] Event categories

### Backend Development- [x] Protected routes with middleware

- [x] Silent auth redirects

```bash- [x] Comprehensive testing (121 backend tests)

cd main_backend- [x] E2E test framework (Cypress)

- [x] CI/CD pipelines (GitHub Actions)

# Run tests- [x] Docker containerization

mvn test- [x] System health monitoring



# Run with live reload### Recent Updates 🆕

mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.devtools.restart.enabled=true"- ✨ **Oct 14, 2025:** Improved Remember Me functionality

- 🧹 **Oct 14, 2025:** Repository cleanup (removed 9 unnecessary files)

# Generate coverage report- 🔒 **Oct 13, 2025:** Enhanced unauthorized user handling

mvn clean test jacoco:report- 📊 **Oct 13, 2025:** Added stability monitoring tools

open target/site/jacoco/index.html

```## 📝 Notes



**Backend URLs:**- Tests are **not** run automatically on `docker compose up`

- Application: http://localhost:8080- Backend tests require Docker (Testcontainers for MySQL)

- API Docs: http://localhost:8080/swagger-ui.html- Frontend uses Nuxt 4 with Vue 3 Composition API

- Actuator: http://localhost:8080/actuator/health- Backend uses Spring Boot 3.2.0 with Java 21

- Database schema is initialized via `init.sql`

### Frontend Development

## 🔗 Related Links

```bash

cd main_frontend/concert1- [Spring Boot Documentation](https://spring.io/projects/spring-boot)

- [Nuxt 4 Documentation](https://nuxt.com)

# Development server with hot reload- [Docker Compose Documentation](https://docs.docker.com/compose/)

npm run dev

## 📄 License

# Type checking

npm run typecheckThis is a development project for the MM Concerts platform.



# Lint & format---

npm run lint

npm run lint:fix**Last Updated:** October 14, 2025



# Build for production

npm run build
```

**Frontend URLs:**
- Dev Server: http://localhost:3000
- Production Preview: http://localhost:3000 (after build)

### Database Management

```bash
# Access MySQL in Docker
docker-compose exec mysql mysql -u concert_user -p concert_db

# Run migrations
mysql -h localhost -u concert_user -p concert_db < init.sql

# Backup database
docker-compose exec mysql mysqldump -u root -p concert_db > backup.sql
```

---

## 🧪 Testing

### Test Coverage Status

| Component | Tests | Statements | Branches | Functions |
|-----------|-------|------------|----------|-----------|
| **Frontend** | 570 | 91.17% | 85.51% | 77.98% |
| **Backend** | 228 | 97% | 89% | - |
| **Total** | **798** | **93.5%** | **86.8%** | - |

### Running Tests

#### Frontend Tests

```bash
cd main_frontend/concert1

# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test MyBookingsPage.test.ts

# Watch mode
npm test -- --watch

# UI mode
npm test -- --ui
```

#### Backend Tests

```bash
cd main_backend

# Run all tests
mvn test

# Run with coverage
mvn clean test jacoco:report

# Run specific test class
mvn test -Dtest=AuthControllerTest

# Run integration tests only
mvn test -Dtest=*IntegrationTest
```

#### Docker Integration Tests

```bash
# Build and test full stack
docker-compose -f docker-compose.yml up --build

# Run integration tests
./check-stability.sh
```

### Continuous Integration

Tests run automatically on every push and pull request via GitHub Actions:

- ✅ Frontend unit tests (Vitest)
- ✅ Backend unit tests (JUnit)
- ✅ Integration tests (Testcontainers)
- ✅ Docker build & health checks
- ✅ Coverage reporting
- ✅ Code quality checks

View workflow runs: [GitHub Actions](https://github.com/MorningMores/develop/actions)

---

## 📡 API Documentation

### Authentication Endpoints

```http
POST   /api/auth/register       # Register new user
POST   /api/auth/login          # Login
GET    /api/auth/test           # Test authentication
```

### User Endpoints

```http
GET    /api/users/profile       # Get user profile
PUT    /api/users/profile       # Update profile
```

### Event Endpoints

```http
GET    /api/events              # List all events
GET    /api/events/{id}         # Get event details
POST   /api/events              # Create event (auth required)
PUT    /api/events/{id}         # Update event (auth required)
DELETE /api/events/{id}         # Delete event (auth required)
GET    /api/events/user         # Get user's events
```

### Booking Endpoints

```http
GET    /api/bookings            # List user bookings
POST   /api/bookings            # Create booking
DELETE /api/bookings/{id}       # Cancel booking
GET    /api/bookings/{id}       # Get booking details
```

### API Testing

Use the provided Postman collection for API testing:

```bash
# Import collection (in doce/ folder)
# Or use cURL
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"REDACTED_PASSWORD_D!","fullName":"Test User"}'
```

**Detailed API Docs**: See [doce/POSTMAN_TESTING_GUIDE.md](doce/POSTMAN_TESTING_GUIDE.md)

---

## 🚀 Deployment

### Docker Deployment

```bash
# Production build
docker-compose -f docker-compose.prod.yml up -d

# Scale services
docker-compose -f docker-compose.prod.yml up -d --scale backend=3

# View logs
docker-compose logs -f backend frontend

# Stop services
docker-compose down
```

### Manual Deployment

#### Backend

```bash
cd main_backend

# Build production JAR
mvn clean package -DskipTests

# Run with production profile
java -jar target/concert-backend-1.0.0.jar --spring.profiles.active=prod
```

#### Frontend

```bash
cd main_frontend/concert1

# Build for production
npm run build

# Start production server
npm run preview

# Or use PM2
pm2 start npm --name "concert-frontend" -- run preview
```

### Environment Variables

Create a `.env` file from `.env.example`:

```env
# Database
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=concert_db
MYSQL_USER=concert_user
MYSQL_PASSWORD=your_password

# Backend
SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/concert_db
SPRING_DATASOURCE_USERNAME=concert_user
SPRING_DATASOURCE_PASSWORD=your_password
JWT_SECRET=your_jwt_secret_key_here

# Frontend
NUXT_PUBLIC_API_BASE=http://localhost:8080
```

---

## 📚 Documentation

Comprehensive documentation is available in the [`doce/`](doce/) directory:

### Quick Links

- 📖 [Quick Start Guide](doce/QUICK_START_GUIDE.md) - Get started in 5 minutes
- 🏗️ [Platform Architecture](doce/PLATFORM_ARCHITECTURE.md) - System design
- 🔧 [CI/CD Setup](doce/CI_CD_SETUP.md) - Continuous integration
- 🧪 [Testing Roadmap](doce/TESTING_ROADMAP.md) - Test strategy
- 🐳 [Docker Guide](doce/JSON_EVENTS_DOCKER_GUIDE.md) - Containerization
- 🗄️ [Database Schema](doce/SQL_SCHEMA_UPDATE.md) - Database structure
- ✨ [Features Guide](doce/FEATURES_READY.md) - All platform features
- 🐛 [Bug Fixes](doce/BOOKING_FIX_COMPLETE.md) - Known issues & solutions

**Full Index**: [doce/README.md](doce/README.md)

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](doce/CONTRIBUTING.md) for details.

### Development Workflow

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/develop.git`
3. **Create** a branch: `git checkout -b feature/amazing-feature`
4. **Make** your changes
5. **Test** thoroughly: `npm test` and `mvn test`
6. **Commit**: `git commit -m 'feat: Add amazing feature'`
7. **Push**: `git push origin feature/amazing-feature`
8. **Create** a Pull Request

### Code Standards

- Follow existing code style
- Write tests for new features
- Update documentation
- Ensure all tests pass
- Maintain coverage above 85%

### Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add new feature
fix: Fix bug
docs: Update documentation
test: Add tests
refactor: Code refactoring
style: Format code
chore: Update dependencies
```

---

## 📊 Project Status

### Current Version: 2.0.0

### Recent Updates

- ✅ GitHub Actions CI/CD pipeline
- ✅ Frontend coverage: 85.51% branches
- ✅ Backend coverage: 89% branches
- ✅ Docker integration tests
- ✅ Comprehensive documentation
- ✅ Automated issue creation
- ✅ PR coverage comments

### Roadmap

- [ ] Reach 90% branch coverage
- [ ] Add payment gateway integration
- [ ] Implement QR code tickets
- [ ] Add email notifications
- [ ] Mobile app (React Native)
- [ ] Admin dashboard
- [ ] Advanced analytics

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

**MM Concerts Development Team**

- **Project Lead**: [MorningMores](https://github.com/MorningMores)
- **Contributors**: See [Contributors](https://github.com/MorningMores/develop/graphs/contributors)

---

## 📞 Support

- 📧 Email: support@mmconcerts.com
- 🐛 Issues: [GitHub Issues](https://github.com/MorningMores/develop/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/MorningMores/develop/discussions)
- 📖 Docs: [Documentation](doce/README.md)

---

## 🙏 Acknowledgments

- Spring Boot Team for excellent framework
- Nuxt.js Team for amazing SSR framework
- Vue.js Team for reactive UI framework
- All open-source contributors

---

<div align="center">

**Made with ❤️ by MM Concerts Team**

⭐ Star us on GitHub — it motivates us a lot!

[Website](https://mmconcerts.com) • [Documentation](doce/README.md) • [Report Bug](https://github.com/MorningMores/develop/issues) • [Request Feature](https://github.com/MorningMores/develop/issues)

</div>
