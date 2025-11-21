# 🎵 MM Concerts - Concert Booking Platform

## ⚡ TL;DR (Run in One Command)

```bash
git clone https://github.com/MorningMores/develop.git
cd develop
docker compose up -d

<div align="center">

A modern, full-stack concert booking and event management platform built with Spring Boot 3.2 and Nuxt 4.

![Build Status](https://img.shields.io/github/actions/workflow/status/MorningMores/develop/ci-tests.yml?branch=main)
![Coverage](https://img.shields.io/badge/coverage-96%25-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2-brightgreen)
![Nuxt](https://img.shields.io/badge/Nuxt-4.0-00DC82)

[Features](#-features) • [Quick Start](#-quick-start) • [Tech Stack](#-tech-stack) • [Documentation](#-documentation) • [API](#-api-documentation)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Development](#-development)
- [Testing](#-testing)
- [API Documentation](#-api-documentation)
- [Deployment](#-deployment)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## 🎯 Overview

MM Concerts is a comprehensive event management platform that enables users to discover concerts, manage bookings, and create events. Built with modern technologies, it provides a seamless experience for both event organizers and attendees.

### Key Highlights

- 🎫 **Real-time Booking** - Instant seat availability and confirmation
- 🔐 **Secure Authentication** - JWT-based auth with session management
- 📱 **Responsive Design** - Mobile-first, works on all devices
- 🎨 **Modern UI** - Sleek interface with Nuxt 4 and Vue 3
- 🚀 **High Performance** - Optimized backend with Spring Boot 3.2
- 🧪 **Well Tested** - 798+ tests with 96% backend coverage
- 🐳 **Docker Ready** - Full containerization support
- 🔄 **CI/CD Pipeline** - Automated testing and deployment via GitHub Actions

---

## ✨ Features

### For Users

- 🔍 **Event Discovery** - Browse concerts by category, date, and location
- 🎟️ **Ticket Booking** - Easy booking with quantity selection
- 📅 **My Bookings** - View and manage all your tickets
- 👤 **Profile Management** - Update personal information and preferences
- 💳 **Secure Checkout** - Safe payment processing with JWT auth
- ❌ **Cancellation** - Cancel bookings with automatic booking removal

### For Event Organizers

- ➕ **Create Events** - Add new concerts with rich details and images
- ✏️ **Edit Events** - Update event information anytime
- 📊 **Event Dashboard** - Track your events and bookings
- 🗑️ **Delete Events** - Remove cancelled events (auto-cancels all bookings)
- ��️ **Image Upload** - Add event posters and galleries
- 🎭 **Category Management** - Organize events by type

### Technical Features

- ✅ JWT-based authentication with Remember Me functionality
- ✅ Protected routes with middleware
- ✅ Silent auth redirects (no "Unauthorized" messages)
- ✅ Role-based access control
- ✅ Real-time booking availability
- ✅ Automatic booking cancellation on event deletion
- ✅ Comprehensive error handling
- ✅ Terms & Conditions validation for registration

---

## 🛠️ Tech Stack

### Backend

- **Framework**: Spring Boot 3.2.0
- **Language**: Java 21
- **Database**: MySQL 8.0
- **Security**: Spring Security + JWT
- **Testing**: JUnit 5, Mockito, Testcontainers
- **Build**: Maven
- **Coverage**: JaCoCo (96% instruction coverage)

### Frontend

- **Framework**: Nuxt 4
- **Language**: TypeScript
- **UI Framework**: Vue 3 (Composition API)
- **State Management**: Composables & Pinia
- **Testing**: Vitest, Vue Test Utils, Cypress
- **Build**: Vite
- **Coverage**: 570+ tests passing

### DevOps

- **Containerization**: Docker & Docker Compose
- **CI/CD**: GitHub Actions
- **Version Control**: Git
- **Code Quality**: ESLint, Prettier
- **API Testing**: Postman Collection included

---

## 🚀 Quick Start

### Prerequisites

- **Docker** & **Docker Compose** (recommended)
- **Java 21** (for backend development)
- **Node.js 20+** (for frontend development)
- **MySQL 8.0** (if not using Docker)

### Option 1: Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/MorningMores/develop.git
cd develop

# Start all services
docker compose up -d

# View logs
docker compose logs -f
```

**Access the application:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- MySQL: localhost:3306

**Test Credentials:**
- Email: `user1@test.com` / `user2@test.com` / ... / `user21@test.com`
- Password: `password123`

### Option 2: Manual Setup

#### Backend Setup

```bash
cd main_backend

# Install dependencies & run tests
mvn clean install

# Run the application
mvn spring-boot:run

# Backend will start on http://localhost:8080
```

#### Frontend Setup

```bash
cd main_frontend/concert1

# Install dependencies
npm install

# Run development server
npm run dev

# Frontend will start on http://localhost:3000
```

---

## 📁 Project Structure

```
develop/
├── .github/
│   └── workflows/              # GitHub Actions CI/CD
│       ├── ci-tests.yml        # Main test pipeline
│       └── frontend-tests.yml  # Frontend tests
│
├── main_backend/               # Spring Boot REST API (Java 21)
│   ├── src/main/java/com/concert/
│   │   ├── controller/         # REST Controllers
│   │   ├── service/            # Business Logic
│   │   ├── repository/         # Data Access Layer
│   │   ├── model/              # JPA Entities
│   │   ├── dto/                # Data Transfer Objects
│   │   ├── security/           # JWT & Security Config
│   │   └── config/             # Application Config
│   ├── src/test/java/          # Unit & Integration Tests
│   ├── cypress-tests/          # E2E Tests (Cypress)
│   ├── pom.xml                 # Maven Configuration
│   └── Dockerfile
│
├── main_frontend/concert1/     # Nuxt 4 Application
│   ├── app/
│   │   ├── pages/              # Route Pages
│   │   ├── components/         # Vue Components
│   │   ├── composables/        # Reusable Logic
│   │   ├── layouts/            # Page Layouts
│   │   └── assets/             # Static Assets
│   ├── server/                 # Server API Routes (SSR)
│   ├── test/unit/              # Unit Tests (Vitest)
│   ├── nuxt.config.ts          # Nuxt Configuration
│   ├── package.json            # Dependencies
│   └── Dockerfile
│
├── k8s/                        # Kubernetes Manifests
├── init.sql                    # Database Schema & Sample Data
├── docker-compose.yml          # Container Orchestration
└── README.md                   # This file
```

---

## 💻 Development

### Backend Development

```bash
cd main_backend

# Run tests
mvn test

# Run with live reload
mvn spring-boot:run

# Generate coverage report
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn clean test jacoco:report
open target/site/jacoco/index.html

# Build JAR
mvn clean package
java -jar target/concert-backend-1.0.0.jar
```

**Backend URLs:**
- Application: http://localhost:8080
- Health Check: http://localhost:8080/actuator/health
- Swagger API Docs: http://localhost:8080/swagger-ui.html (if configured)

### Frontend Development

```bash
cd main_frontend/concert1

# Development server with hot reload
npm run dev

# Type checking
npm run typecheck

# Lint & format
npm run lint
npm run lint:fix

# Build for production
npm run build
npm run preview
```

**Frontend URLs:**
- Dev Server: http://localhost:3000

### Database Management

```bash
# Access MySQL in Docker
docker compose exec mysql mysql -u concert_user -p concert_db

# Reset database
docker compose down -v
docker compose up -d

# Backup database
docker compose exec mysql mysqldump -u root -p concert_db > backup.sql
```

---

## 🧪 Testing

### Test Coverage Status

| Component | Tests | Coverage | Status |
|-----------|-------|----------|--------|
| **Backend** | 228 tests | 96% instruction | ✅ All passing |
| **Frontend** | 570 tests | 90%+ | ✅ All passing |
| **Total** | **798 tests** | **~96% overall** | ✅ **Production Ready** |

### Backend Tests

**Run all tests with coverage (macOS):**
```bash
cd main_backend
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report
open target/site/jacoco/index.html
```

**Test Types:**
- ✅ Unit Tests (179 tests) - Service, Model, DTO tests
- ✅ Integration Tests (20 tests) - Full auth flow tests
- ✅ Docker/Testcontainers Tests (22 tests) - Real MySQL container tests
- ✅ Application Context Tests (7 tests) - Spring Boot startup tests

**Important:** Ensure Docker is running before executing tests (Testcontainers requirement).

### Frontend Tests

```bash
cd main_frontend/concert1

# Run all tests
npm test

# Run with coverage
npm test -- --coverage
open coverage/index.html

# Run specific test file
npm test MyBookingsPage.test.ts

# Watch mode
npm test -- --watch
```

**Test Suites:**
- ✅ Component Tests (18 files) - Login, Register, NavBar, etc.
- ✅ Page Tests (13 files) - MyEventsPage, AccountPage, etc.
- ✅ Composables Tests (3 files) - useAuth, useToast, etc.
- ✅ Layout Tests (1 file)

### Cypress E2E Tests

```bash
cd main_backend/cypress-tests

# Install dependencies (first time only)
npm install

# Run in headless mode
npm test

# Open Cypress Test Runner
npx cypress open
```

### System Health Check

Run the stability check script:
```bash
./check-stability.sh
```

**Checks:**
- ✅ Docker containers status
- ✅ MySQL connectivity
- ✅ Backend API health
- ✅ Frontend serving
- ✅ Error log scanning

---

## 📚 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/auth/register` | Register new user | ❌ |
| POST | `/api/auth/login` | Login user | ❌ |
| GET | `/api/auth/test` | Test auth endpoint | ✅ |

### User Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/users/profile` | Get user profile | ✅ |
| PUT | `/api/users/profile` | Update user profile | ✅ |
| GET | `/api/users/{id}` | Get user by ID | ✅ |

### Event Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/events/json` | List all events | ❌ |
| GET | `/api/events/json/{id}` | Get event by ID | ❌ |
| POST | `/api/events/json` | Create event | ✅ |
| PUT | `/api/events/json/{id}` | Update event | ✅ |
| DELETE | `/api/events/json/{id}` | Delete event | ✅ |

### Booking Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/bookings/my-bookings` | Get user bookings | ✅ |
| POST | `/api/bookings` | Create booking | ✅ |
| DELETE | `/api/bookings/{id}` | Cancel booking | ✅ |
| DELETE | `/api/bookings/event/{eventId}` | Cancel all event bookings | ✅ |

**Postman Collection:** Import `Concert_Backend_API.postman_collection.json` for complete API documentation and examples.

---

## 🐳 Deployment

### Docker Deployment

```bash
# Build and start all services
docker compose up -d --build

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Full cleanup (remove volumes)
docker compose down -v
```

### Kubernetes Deployment

```bash
# Apply all manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/

# Check status
kubectl get pods -n concert-platform
kubectl get services -n concert-platform

# View logs
kubectl logs -f <pod-name> -n concert-platform
```

See [k8s/README.md](k8s/README.md) for detailed Kubernetes setup guide.

### Production Build

**Backend:**
```bash
cd main_backend
mvn clean package -DskipTests
java -jar target/concert-backend-1.0.0.jar
```

**Frontend:**
```bash
cd main_frontend/concert1
npm run build
npm run preview
```

---

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

If JaCoCo coverage errors occur, ensure you're using JDK 21:
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn test
```

---

## 📖 Documentation

Additional documentation can be found in the project:

- 📖 **[Testing Infrastructure Complete](TESTING_INFRASTRUCTURE_COMPLETE.md)** - Comprehensive testing guide
- 📖 **[Remember Me Testing](REMEMBER_ME_TESTING.md)** - Auth flow testing
- 📖 **[Remember Me Fix Summary](REMEMBER_ME_FIX_SUMMARY.md)** - Implementation details
- 📖 **[Stability Report](STABILITY_REPORT.md)** - System health status
- 📖 **[Cleanup Summary](CLEANUP_SUMMARY.md)** - Repository maintenance
- 📖 **[Unauthorized Handling](UNAUTHORIZED_HANDLING.md)** - Error handling guide
- 📖 **[Event Deletion Fix](EVENT_DELETION_WITH_BOOKINGS_FIX.md)** - Auto-cancel bookings
- 📖 **[S3 Upload Fix](S3_UPLOAD_FIX_SUMMARY.md)** - S3 upload configuration fix
- 📖 **[S3 Upload Troubleshooting](S3_UPLOAD_TROUBLESHOOTING.md)** - S3 troubleshooting guide
- 📖 **[Participant Tracking Fix](PARTICIPANT_TRACKING_FIX.md)** - Real-time participant tracking
- 📖 **[EKS Deployment Guide](EKS_DEPLOYMENT_GUIDE.md)** - AWS EKS deployment with IAM setup
- 📖 **[Kubernetes Guide](k8s/README.md)** - K8s deployment instructions

---

## 🔒 Security Features

- 🔐 JWT token authentication
- 🔑 Password hashing (BCrypt)
- 🛡️ CORS configuration
- 💉 SQL injection prevention (JPA)
- 🚫 XSS protection
- 🔒 Secure session handling
- ✅ Role-based access control
- �� Remember Me with secure storage
- 🚨 Silent auth redirects

---

## 🗄️ Database Schema

### Main Tables

- **Users** - User accounts and authentication
- **Events** - Concert/event information (JSON-based storage)
- **Bookings** - User ticket purchases
- **Roles** - User role definitions
- **User_Roles** - User-role associations

### Sample Data

- 21 test users (user1@test.com - user21@test.com)
- 7 sample events across various categories
- Multiple bookings for testing

**Reset Database:**
```bash
docker compose down -v
docker compose up -d
```

---

## 🚦 System Status

### Completed Features ✅

- [x] Full authentication system with JWT
- [x] Remember Me functionality
- [x] Event CRUD operations
- [x] Booking system with cancellation
- [x] User profile management
- [x] Event categories
- [x] Protected routes with middleware
- [x] Silent auth redirects
- [x] Auto-cancel bookings on event deletion
- [x] Terms & Conditions validation for registration
- [x] Comprehensive testing (798 tests, 96% backend coverage)
- [x] E2E test framework (Cypress)
- [x] CI/CD pipelines (GitHub Actions)
- [x] Docker containerization
- [x] Kubernetes deployment support
- [x] System health monitoring

### Recent Updates 🆕

- ✨ **Jan 15, 2025:** Added real-time participant tracking and EKS deployment guide
- ✨ **Nov 9, 2025:** Fixed S3 upload 500 error (region/bucket configuration)
- ✨ **Oct 16, 2025:** Fixed all tests (798 passing, 96% backend coverage)
- ✨ **Oct 16, 2025:** Added comprehensive testing infrastructure
- ✨ **Oct 15, 2025:** Implemented event deletion with auto-booking cancellation
- ✨ **Oct 14, 2025:** Improved Remember Me functionality
- 🧹 **Oct 14, 2025:** Repository cleanup
- 🔒 **Oct 13, 2025:** Enhanced unauthorized user handling

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow existing code style
- Write tests for new features
- Ensure all tests pass before submitting PR
- Update documentation as needed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Related Links

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Nuxt 4 Documentation](https://nuxt.com)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

<div align="center">

**MM Concerts Platform** - Built with ❤️ by MorningMores

**Last Updated:** October 16, 2025

</div>
