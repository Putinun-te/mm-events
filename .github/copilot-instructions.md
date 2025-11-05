# Copilot Instructions for this Repo

Purpose: Enable AI agents to be productive quickly in this monorepo by following the project’s actual patterns and workflows.

## Big Picture
- Monorepo with two main apps:
  - Backend: Spring Boot REST API for auth and users at `main_backend/`.
  - Frontend: Nuxt 4 app at `main_frontend/concert1/` consuming the backend.
- Data flow:
  - Frontend pages/components call server-side API modules (Nuxt server routes) under `concert1/server/**`.
  - Those server routes use Axios to hit the backend at `http://localhost:8080`.
  - Backend uses Spring Security + JWT; controllers in `com.concert.controller` return DTOs (e.g., `AuthResponse`).

## Repo Layout
- `docker-compose.yml`, `init.sql` (root): optional runtime stack; not needed for backend tests.
- Backend (Spring Boot): `main_backend/`
  - Code: `src/main/java/com/concert/{config,controller,dto,model,repository,security,service}`
  - Tests: `src/test/java/com/concert/**` (unit, integration, and docker-based tests)
  - Build/CI: `pom.xml` (JaCoCo, Surefire, Spring Boot plugin)
- Frontend (Nuxt 4): `main_frontend/concert1/`
  - App code: `app/{pages,components,assets,layouts}`
  - SSR/server routes: `server/{login,register}`
  - Tests/config: `vitest.config.ts`, `vitest.setup.ts`, `package.json`

## Backend: How to Build, Test, and Cover
- Java and Maven:
  - Source targets Java 17, but run tests with JDK 21 to avoid JaCoCo/Mockito bytecode issues on newer JDKs.
  - Set Java for commands: `JAVA_HOME=$(/usr/libexec/java_home -v 21)` on macOS.
- Commands:
  - Run app: `mvn spring-boot:run`
  - Run tests with coverage (and stable forks):
    - `JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn -DforkCount=1 -DreuseForks=false test jacoco:report`
  - Coverage HTML: `main_backend/target/site/jacoco/index.html`
- Testcontainers:
  - Several tests spin up MySQL via Testcontainers; Docker Desktop must be running.
  - No docker-compose needed for tests.
- JaCoCo/Surefire specifics (pom.xml):
  - JaCoCo 0.8.12 with include filter to only instrument `com/concert/**` (avoids JDK/Hibernate/Mockito proxies).
  - Surefire adds `-Dnet.bytebuddy.experimental=true --add-opens java.base/java.lang=ALL-UNNAMED` to support proxies.
- API boundaries (examples):
  - Auth: `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/test` in `AuthController`.
  - Security: `JwtAuthenticationFilter`, `JwtService` under `com.concert.security`/`service`.
  - DTOs: `AuthResponse`, `LoginRequest`, `RegisterRequest` under `com.concert.dto`.
- Test patterns:
  - Unit tests end with `*Test.java`; broader flows `*IntegrationTest.java`; Docker-backed tests include `DockerTest`.

## Frontend: How to Build, Test, and Cover
- Commands (run in `main_frontend/concert1/`):
  - Dev server: `npm run dev` (Nuxt 4)
  - Unit tests: `npm run test` (Vitest)
- Vitest config (`vitest.config.ts`):
  - `environment: 'jsdom'`, `globals: true`, setup via `vitest.setup.ts`.
  - Aliases: `@`, `~`, `~~` resolve to project root; `assets` → `app/assets`.
  - Coverage reporters: `text`, `html` (HTML output under `coverage/`).
- Server routes (integration points):
  - `server/login/login.ts`, `server/register/register.ts` call the backend via Axios at `http://localhost:8080`.
  - Components `Login.vue` and `Register.vue` use these routes; tokens returned in `AuthResponse.token`.

## Conventions and Gotchas
- Keep backend tests runnable with Docker active; failures often due to Docker not running.
- If you see "Unsupported class file major version 68" or Hibernate/Mockito proxy instrumentation errors, ensure:
  - JDK 21 is used for tests; and JaCoCo include filter remains `com/concert/**`.
- Frontend tests rely on Testing Library with jest-dom; use NuxtLink stubs when rendering components with router links.
- Unused legacy files (e.g., `RegisterCheck.vue`) may still exist but are not wired in pages; check `app/pages/index.vue` for current usage.

## **CRITICAL: Documentation Policy**
- **DO NOT create markdown documentation files** unless explicitly requested by the user.
- When making changes (code fixes, deployments, configuration updates), just make the changes directly.
- No need for summary files, status reports, or "COMPLETE" documents after each task.
- Focus on: fixing issues, writing code, running commands, testing functionality.
- User wants action, not documentation.

## Useful Paths to Read First
- Backend security flow: `com/concert/security/JwtAuthenticationFilter.java`, `com/concert/service/JwtService.java`.
- Auth endpoints and DTOs: `com/concert/controller/AuthController.java`, `com/concert/dto/*`.
- Frontend auth UI and calls: `app/components/{Login.vue,Register.vue}`, `server/{login,register}/*.ts`.
- Test examples: `src/test/java/com/concert/controller/*Test.java`, `repository/*DockerTest.java`.

If anything here seems outdated or unclear, ask which part to refine and I’ll update these instructions.
