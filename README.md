# Concert Management System

[![CI/CD Pipeline](https://github.com/MorningMores/develop/actions/workflows/ci.yml/badge.svg)](https://github.com/MorningMores/develop/actions/workflows/ci.yml)
[![Codecov](https://img.shields.io/badge/Codecov-coverage-blue)](https://app.codecov.io/gh/MorningMores/develop)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A full-stack application for managing concerts and events.

- Backend: Spring Boot 3.5 (Java 21), MySQL, JWT auth
- Frontend: Nuxt 4, Tailwind v4, Vitest unit tests, Playwright E2E
- CI: GitHub Actions (unit + coverage + E2E + Docker smoke)

---

## Features

- User registration/login with JWT
- Event creation, tickets, orders, and favorites
- REST API with DTOs and Spring Security
- SSR frontend (Nuxt) wired to backend via server routes

## Getting started

Prerequisites

- Java 21 (Temurin recommended)
- Node.js 20+
- Docker Desktop (for optional stack and Testcontainers)

Clone and setup
```bash
git clone https://github.com/MorningMores/develop.git
cd develop
cp .env.example .env  # fill in values (generate a strong JWT_SECRET)
```

### Run with Docker (recommended for local dev)
```bash
docker compose up -d
```

- Backend: <http://localhost:8080>
- Frontend: <http://localhost:3000>

Stop/clean
```bash
docker compose stop             # stop only
docker compose down             # remove containers
docker compose down -v          # remove containers + volumes
```

### Backend (local)
```bash
cd main_backend
./mvnw spring-boot:run
```
Tests + coverage
```bash
./mvnw -DforkCount=1 -DreuseForks=false clean test jacoco:report
# HTML: main_backend/target/site/jacoco/index.html
```

### Frontend (local)
```bash
cd main_frontend/concert1
npm install
npm run dev
```
Unit tests + coverage
```bash
npm test -- --run
npm test -- --coverage --run
```

### E2E (Playwright)
```bash
cd main_frontend/concert1
npx playwright install --with-deps chromium
npm run test:e2e:headless
```

## CI/CD
Unified workflow: `.github/workflows/ci.yml`
- Frontend (Node 20, 22): unit tests + coverage → Codecov
- Backend (JDK 21): unit tests + JaCoCo → Codecov
- E2E: Playwright against services
- Docker: Build and smoke test stack

Add repo secrets before enabling required checks:
- `CODECOV_TOKEN` (from Codecov)
- Optional Docker Hub: `DOCKER_USERNAME`, `DOCKER_PASSWORD`

Branch protection and Codecov setup guide: `docs/deployment/github-branch-protection-setup.md`

## Configuration
Backend properties are env-driven. See `main_backend/src/main/resources/application.properties` and `.env.example`.
- JWT_SECRET must be at least 256 bits for HMAC-SHA (e.g., HS256). Generate with `openssl rand -hex 32`.

## Documentation
- Project roadmap: `docs/IMPLEMENTATION_ROADMAP.md`
- Testing plans:
  - Controllers coverage: `docs/guides/controller-coverage-improvement-plan.md`
  - E2E enhancements: `docs/guides/e2e-test-enhancement-plan.md`
- Branch protection & Codecov: `docs/deployment/github-branch-protection-setup.md`
- Local Docker summary: `docs/LOCAL-DOCKER-TESTING-SUMMARY.md`

## Contributing
See `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`. Issues and PR templates are provided under `.github/`.

## Security
Please report vulnerabilities as described in `SECURITY.md`. Never commit real secrets. Use `.env` files (gitignored).

## License
MIT © Contributors. See `LICENSE`.


