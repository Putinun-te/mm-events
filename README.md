## How to use:

Start app stack (no tests)<br />
```docker compose up -d```
<br />
Run tests on demand<br />
```docker compose run --rm backend-tests```
<br />
Or enable tests profile<br />
```docker compose --profile tests up backend-tests```
<br />

## Options to shut down<br />
Stop containers (keep them for quick restart)<br />
```run docker compose stop```
<br />
Stop and remove containers + network <br />
```run docker compose down```
<br />
Also remove DB volume (wipe data) <br />
```run docker compose down -v (or remove the named volume after docker volume ls)```
<br />
Stop specific services only <br />
```run docker compose stop backend frontend```
<br />
If running locally with mvn spring-boot:run: press Ctrl+C in that terminal

## Coverage test

Local (macOS, use JDK 21 for tests)
```bash
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report
```

Docker (uses Maven JDK 21 image)
```bash
docker compose run --rm backend-tests
# or if profiles are enforced on your setup
# docker compose --profile tests run --rm backend-tests
```

Open the HTML report after it finishes:
```
main_backend/target/site/jacoco/index.html
```
