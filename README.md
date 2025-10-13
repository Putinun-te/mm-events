# Concert Management System

[![CI/CD Pipeline](https://github.com/MorningMores/develop/actions/workflows/ci.yml/badge.svg)](https://github.com/MorningMores/develop/actions/workflows/ci.yml)
[![Frontend Coverage](https://img.shields.io/badge/Frontend%20Coverage-93.36%25-brightgreen)](./docs/reports/test-coverage-summary.md)
[![Backend Coverage](https://img.shields.io/badge/Backend%20Coverage-Check%20CI-blue)](./main_backend/target/site/jacoco/index.html)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> Full-stack web application for concert and event management with Spring Boot backend and Nuxt 4 frontend

---

## How to use

## Start the app stack (no tests)
```bash
docker compose up -d
```
- Backend: http://localhost:8080
- Frontend (Nuxt dev): http://localhost:3000

## Run tests on demand
```bash
docker compose run --rm backend-tests
```

## Run backend tests with coverage

Local (macOS, use JDK 21 for tests):
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report -f main_backend/pom.xml
```

Docker (uses Maven JDK 21 image):
```bash
docker compose run --rm backend-tests
# or, if you prefer profiles
# docker compose --profile tests run --rm backend-tests
```

Open the HTML coverage report:
```
main_backend/target/site/jacoco/index.html
```

## Frontend E2E tests (Playwright)

Local run (headed Chromium):
```bash
cd main_frontend/concert1
npm ci
npx playwright install --with-deps chromium
npm run dev &
NUXT_PID=$!
# wait for dev server
for i in {1..40}; do curl -sf http://localhost:3000/concert/ >/dev/null && break || sleep 2; done
npm run test:e2e
kill $NUXT_PID || true
```
Headless (CI style):
```bash
npm run test:e2e:headless
```
GitHub Actions workflow: `.github/workflows/frontend-e2e.yml` runs automatically on pushes/PRs to `main` or `FE-Testing`.

## Shut down
- Stop containers (keep for quick restart):
  ```bash
  docker compose stop
  ```
- Stop and remove containers + network:
  ```bash
  docker compose down
  ```
- Also remove DB volume (wipe data):
  ```bash
  docker compose down -v
  ```
- Stop specific services only:
  ```bash
  docker compose stop backend frontend
  ```
- If running locally with Spring Boot:
  ```
  Press Ctrl+C in the terminal running: mvn spring-boot:run
  ```

## Status (27 Sep)
- [x] Backend CI (GitHub Actions) `.github/workflows/backend-ci.yml`
- [x] Initial E2E framework (Playwright) added
- [x] Frontend E2E GitHub Action workflow stub `.github/workflows/frontend-e2e.yml`
- [x] Jenkins pipeline added `Jenkinsfile`
- [x] GitLab CI pipeline added `.gitlab-ci.yml`
- [ ] Expand E2E tests to cover all user stories (add real selectors & flows)
- [ ] Jenkins / GitLab pipeline templates (future)

## Notes
- Tests are not run automatically on `docker compose up`. The `backend-tests` service is behind the `tests` profile and must be invoked explicitly as shown above.


