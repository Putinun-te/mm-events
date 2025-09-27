# How to use

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

## Backend tests + JaCoCo quick commands

Run tests with coverage (fail build if coverage < thresholds in pom):
```bash
mvn -f main_backend/pom.xml test jacoco:report
```
Allow build to pass even if coverage below thresholds (override halt flag):
```bash
mvn -f main_backend/pom.xml -Djacoco.haltOnFailure=false test jacoco:report
```
Generate XML only (for codecov etc.):
```bash
mvn -f main_backend/pom.xml -Djacoco.haltOnFailure=false test jacoco:report && \
  echo "XML: main_backend/target/site/jacoco/jacoco.xml"
```
Run only the coverage check goal (after tests already run):
```bash
mvn -f main_backend/pom.xml jacoco:check
```
Current enforced minimums (see pom): LINE >= 60%, BRANCH >= 60%.

## Frontend E2E tests (Cypress)

Local headed (open Cypress GUI):
```bash
cd main_frontend/concert1
npm ci
npm run dev &
NUXT_PID=$!
for i in {1..40}; do curl -sf http://localhost:3000/concert/ >/dev/null && break || sleep 2; done
npm run test:e2e:headed
kill $NUXT_PID || true
```
Headless (CI style):
```bash
cd main_frontend/concert1
npm ci
npm run dev &
NUXT_PID=$!
for i in {1..40}; do curl -sf http://localhost:3000/concert/ >/dev/null && break || sleep 2; done
npm run test:e2e
kill $NUXT_PID || true
```
GitHub Actions workflow: `.github/workflows/ci.yml` (job `frontend-e2e`). Remove old Playwright workflow if not needed: `.github/workflows/frontend-e2e.yml`.

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
- [x] Switch to Cypress for E2E
- [x] Frontend E2E job integrated in `.github/workflows/ci.yml`
- [x] Jenkins pipeline added `Jenkinsfile`
- [x] GitLab CI pipeline added `.gitlab-ci.yml`
- [ ] Expand E2E tests with real backend assertions
- [ ] Jenkins / GitLab pipeline templates (future)

## Notes
- Tests are not run automatically on `docker compose up`. The `backend-tests` service is behind the `tests` profile and must be invoked explicitly as shown above.


