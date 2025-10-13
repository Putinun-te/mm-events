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

## 🚨 CRITICAL SECURITY RULES

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

---

**Remember**: 
- 🔐 Prevention is better than detection!
- 📁 Organization matters - keep docs in docs/!
- 🔄 Consistency is key - update ALL related files!
