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

## Notes
- Tests are not run automatically on `docker compose up`. The `backend-tests` service is behind the `tests` profile and must be invoked explicitly as shown above.


