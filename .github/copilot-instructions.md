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
  - **Spring Boot 3.5.0** (upgraded from 3.2.0 on Oct 13, 2025) with Spring Framework 6.2.x
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
- If you see “Unsupported class file major version 68” or Hibernate/Mockito proxy instrumentation errors, ensure:
  - JDK 21 is used for tests; and JaCoCo include filter remains `com/concert/**`.
- Frontend tests rely on Testing Library with jest-dom; use NuxtLink stubs when rendering components with router links.
- Unused legacy files (e.g., `RegisterCheck.vue`) may still exist but are not wired in pages; check `app/pages/index.vue` for current usage.

## Useful Paths to Read First
- Backend security flow: `com/concert/security/JwtAuthenticationFilter.java`, `com/concert/service/JwtService.java`.
- Auth endpoints and DTOs: `com/concert/controller/AuthController.java`, `com/concert/dto/*`.
- Frontend auth UI and calls: `app/components/{Login.vue,Register.vue}`, `server/{login,register}/*.ts`.
- Test examples: `src/test/java/com/concert/controller/*Test.java`, `repository/*DockerTest.java`.

If anything here seems outdated or unclear, ask which part to refine and I'll update these instructions.

---

## � Docker Configuration Verification Rules

**ALWAYS verify Docker configurations are up-to-date after fixing issues!**

### When to Check Docker Files

**After ANY of these actions:**
- Upgrading dependencies (backend or frontend)
- Fixing build/test issues that involve version changes
- Modifying package.json, pom.xml, or build configurations
- Resolving dependency conflicts or version mismatches
- Updating Java, Node.js, or framework versions

### Docker Files to Verify

**Backend Docker:**
- `main_backend/Dockerfile` - Check Java version, base image, Spring Boot version alignment
- `docker-compose.yml` - Verify backend service uses correct build context and environment

**Frontend Docker:**
- `docker-compose.yml` - Check Node.js version in frontend service matches package.json engines
- Frontend Dockerfile (if exists) - Verify Node version and npm/yarn versions

**Database Docker:**
- `docker-compose.yml` - Ensure MySQL version matches application requirements
- `init.sql` - Check if schema changes needed after dependency upgrades

### Verification Steps

1. ✅ **Check version alignment:**
   - Backend: Java version in Dockerfile matches pom.xml source/target
   - Frontend: Node.js version matches package.json engines field
   - Dependencies: Docker base images use compatible versions

2. ✅ **Update if needed:**
   - Spring Boot version change → May need new Java version in Dockerfile
   - Node.js package updates → May need newer Node base image
   - Database driver updates → May need newer MySQL version

3. ✅ **Test Docker build:**
   - Run `docker-compose build` to verify images build successfully
   - Run `docker-compose up -d` to verify containers start properly
   - Check `docker-compose ps` to ensure all services are healthy

4. ✅ **Document changes:**
   - Update relevant documentation if Docker configurations changed
   - Note any version changes in commit messages
   - Update deployment guides if Docker setup changed

### Example Scenarios

**Scenario 1: Spring Boot 3.2.0 → 3.5.0**
- Check: Does Dockerfile Java version support Spring Boot 3.5.0?
- Action: If using Java 17, verify compatibility or upgrade to Java 21
- Verify: `docker-compose build backend` succeeds

**Scenario 2: Node.js packages updated**
- Check: Does docker-compose.yml Node version match package.json?
- Action: Update `node:20-alpine` to `node:22-alpine` if packages require Node 22+
- Verify: `docker-compose build frontend` succeeds

**Scenario 3: Dependency conflict resolved**
- Check: Does resolution affect runtime environment in Docker?
- Action: Update base images or install commands if needed
- Verify: Full stack starts with `docker-compose up -d`

### Quick Verification Checklist

After fixing ANY issue:
- [ ] Read `main_backend/Dockerfile` - Check Java version
- [ ] Read `docker-compose.yml` - Check all service versions
- [ ] Read `main_backend/pom.xml` - Compare Java version
- [ ] Read `main_frontend/concert1/package.json` - Compare Node version
- [ ] Run `docker-compose build` if versions don't match
- [ ] Update Docker files with latest compatible versions
- [ ] Test with `docker-compose up -d` and `docker-compose ps`

---

## �🚨 CRITICAL SECURITY RULES

**NEVER put real API keys, tokens, passwords, or secrets in any files tracked by Git!**

### Safe Locations for Secrets

**Gitignored (safe):**
- `backend/.env`
- `frontend/.env`
- `.env` (root level)
- `.azure-secrets.local.txt`
- Any `*.local.*` files

**External (safe):**
- GitHub Secrets (via web UI)
- Azure Key Vault
- Environment variables in deployment platforms

**Never (unsafe):**
- Any `.md` files
- Any tracked configuration files
- Commit messages
- Code comments
- Any files not in `.gitignore`

### AI Assistant Security Rules

When user provides secrets:
1. ✅ Store ONLY in `.env` files (gitignored)
2. ✅ Use placeholders in all documentation
3. ✅ Never echo back the actual secret
4. ✅ Remind user about security best practices

Example placeholders:
```bash
API_KEY=[YOUR_API_KEY_HERE]
API_KEY=your_key_here
API_KEY=${YOUR_KEY}
DATABASE_PASSWORD=<your-password>
JWT_SECRET=<generate-a-secure-random-string>
```

---

## 📁 File Organization Rules

**Documentation files (.md) belong in organized locations:**

### Correct Locations:
- `docs/` - General documentation
- `docs/deployment/` - Deployment guides
- `docs/guides/` - How-to guides
- `docs/reports/` - Reports and summaries
- `.github/` - GitHub-specific files (workflows, templates)
- Root - ONLY: README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, LICENSE.md

### Wrong Location:
- ❌ Random .md files in project root
- ❌ Documentation mixed with code
- ❌ Guides in root directory

**When creating .md files**:
1. ✅ Create in appropriate docs/ subdirectory
2. ✅ If unsure, ask user for preferred location
3. ✅ Move root .md files to docs/ when organizing
4. ✅ Update any references/links after moving

---

## 🔄 Consistency Rules

**CRITICAL: After creating/modifying ANY file:**
1. ✅ Review ALL related documentation for consistency
2. ✅ Update outdated references across the project
3. ✅ Check code patterns match across all files
4. ✅ Verify naming conventions are consistent
5. ✅ Update related files that reference changed content

**Examples:**
- Created new deployment guide? → Update other deployment docs + README
- Changed API endpoint? → Update all docs that reference it + frontend code
- Added new secret? → Update all setup guides + security docs
- Modified workflow? → Update deployment guides + troubleshooting docs

**Never leave inconsistencies:**
- ❌ Old instructions in some docs, new in others
- ❌ Different code patterns in similar files
- ❌ Broken links or outdated references
- ❌ Inconsistent naming/terminology

---

## 🔄 Cross-Stack Validation Rules

**CRITICAL: After fixing issues in ANY part of the stack, ALWAYS validate the ENTIRE stack!**

### The Golden Rule of Full-Stack Testing

**When fixing frontend issues → Check backend + database**  
**When fixing backend issues → Check frontend + database**  
**When fixing database issues → Check backend + frontend**

### Mandatory Validation Workflow

After fixing ANY issue:

1. ✅ **Fix the immediate issue** in the affected layer
2. ✅ **Validate the connected layer**:
   - Frontend fix? → Test backend APIs it calls
   - Backend fix? → Test frontend components that use it
   - Database fix? → Test backend repositories + frontend data display
3. ✅ **Run ALL relevant tests**:
   - Unit tests (layer-specific)
   - Integration tests (cross-layer)
   - E2E tests (full stack)
4. ✅ **Verify deployment readiness**:
   - Docker builds succeed
   - All containers start healthy
   - API connections work
   - Database migrations applied

### Test Coverage Requirements Before Merging

**Backend (Spring Boot):**
- [ ] Unit tests pass: `mvn test`
- [ ] JaCoCo coverage ≥80%: `mvn jacoco:report`
- [ ] Integration tests pass (Testcontainers)
- [ ] Docker-based tests pass
- [ ] API endpoints tested with Postman/curl

**Frontend (Nuxt 4):**
- [ ] Unit tests pass: `npm test -- --run`
- [ ] Coverage ≥80%: `npm test -- --coverage`
- [ ] Component tests for all interactive UI
- [ ] E2E tests pass: `npx playwright test`
- [ ] Cypress tests pass (if applicable): `npm run cypress:run`

**Database (MySQL):**
- [ ] Schema migrations applied successfully
- [ ] Test data seeds work
- [ ] Repository tests pass (JPA/Hibernate)
- [ ] Foreign key constraints valid
- [ ] Indexes optimized for queries

**Integration (Full Stack):**
- [ ] Frontend → Backend API calls work
- [ ] Backend → Database queries work
- [ ] Authentication flow works E2E
- [ ] All user journeys complete successfully
- [ ] Docker Compose stack runs: `docker-compose up -d`

### CI/CD Readiness Checklist

Before marking any work "complete":

**Pre-Commit:**
- [ ] All tests passing locally
- [ ] No console errors/warnings
- [ ] Code formatted/linted
- [ ] Documentation updated

**CI Pipeline Requirements:**
- [ ] GitHub Actions workflow exists
- [ ] Tests run on: push, pull_request
- [ ] Multi-environment testing (dev, staging)
- [ ] Coverage reports generated
- [ ] Artifacts uploaded on failure

**Deployment Pipeline:**
- [ ] Docker images build successfully
- [ ] Environment variables configured
- [ ] Database migrations automated
- [ ] Health checks implemented
- [ ] Rollback strategy defined

### Cross-Stack Testing Order

Always test in this sequence after ANY fix:

1. **Unit Tests** (fastest, most isolated)
   - Backend: `mvn test`
   - Frontend: `npm test -- --run`

2. **Integration Tests** (layer interactions)
   - Backend: `*IntegrationTest.java`
   - Frontend: API call tests

3. **E2E Tests** (full user flows)
   - Playwright: `npx playwright test`
   - Cypress: `npm run cypress:run`

4. **Docker Stack Test** (deployment simulation)
   ```bash
   docker-compose down
   docker-compose build
   docker-compose up -d
   # Wait for health checks
   # Run smoke tests
   ```

### Example: Frontend Fix Validation Flow

```
User reports: "Login button not working"
↓
1. Fix frontend Login.vue component
2. ✅ Test Login component: npm test Login.spec.ts
3. ✅ Check backend /api/auth/login endpoint
4. ✅ Test AuthController: mvn test -Dtest=AuthControllerTest
5. ✅ Verify database user table schema
6. ✅ Test UserRepository: mvn test -Dtest=UserRepositoryTest
7. ✅ Run E2E login flow: npx playwright test auth.spec.ts
8. ✅ Test in Docker: docker-compose up -d && curl localhost:8080/api/auth/test
9. ✅ Generate coverage reports for both stacks
10. ✅ Update documentation if API changed
```

### Example: Database Fix Validation Flow

```
DBA adds new column: users.phone_number
↓
1. Apply migration: ALTER TABLE users ADD phone_number VARCHAR(20)
2. ✅ Update backend User model: add phoneNumber field
3. ✅ Update UserRepository tests
4. ✅ Update AuthController to handle phone in registration
5. ✅ Test backend: mvn test
6. ✅ Update frontend Register.vue form
7. ✅ Update RegisterRequest DTO display
8. ✅ Test frontend: npm test Register.spec.ts
9. ✅ Run E2E registration: npx playwright test register flow
10. ✅ Verify in Docker with full stack
```

### Red Flags That Indicate Incomplete Validation

❌ **NEVER consider work done if:**
- Only one layer tested (e.g., fixed frontend but didn't check backend)
- Tests pass locally but Docker build fails
- Unit tests pass but integration tests skipped
- E2E tests not run after API changes
- Coverage dropped below threshold
- Documentation not updated for API changes
- No rollback plan for database migrations

### Quick Validation Commands Reference

```bash
# Backend full test suite
cd main_backend
mvn clean test jacoco:report
open target/site/jacoco/index.html  # Check coverage

# Frontend full test suite
cd main_frontend/concert1
npm test -- --coverage --run
npx playwright test
open coverage/index.html  # Check coverage

# Full stack Docker test
docker-compose down -v
docker-compose build
docker-compose up -d
docker-compose ps  # All should be healthy
docker logs concert-backend --tail 50
docker logs concert-frontend --tail 50

# Quick smoke test
curl http://localhost:8080/api/auth/test
curl http://localhost:3000/concert/
```

---

## ✅ Quick Checks Before Suggesting Code

- [ ] No hardcoded secrets?
- [ ] Using environment variables?
- [ ] Documentation uses placeholders?
- [ ] User reminded about `.env` setup?
- [ ] New .md files created in correct location (docs/ folder)?
- [ ] Links updated if files were moved?
- [ ] All related docs checked for consistency?
- [ ] Code patterns consistent across project?
- [ ] References to changed content updated everywhere?
- [ ] **Cross-stack validation completed?** ⭐ NEW
- [ ] **All test suites passing?** ⭐ NEW
- [ ] **Docker stack tested?** ⭐ NEW
- [ ] **CI/CD pipeline ready?** ⭐ NEW

---

**Remember**: 
- 🔐 Prevention is better than detection!
- 📁 Organization matters - keep docs in docs/!
- 🔄 Consistency is key - update ALL related files!
- 🔄 **Cross-stack validation is MANDATORY - never skip it!** ⭐ NEW
