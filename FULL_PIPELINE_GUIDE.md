# Full CI/CD Pipeline Documentation

## 🚀 Overview

Comprehensive **8-stage CI/CD pipeline** with build, test, security, and optional deployment capabilities.

**Workflow File:** `.github/workflows/full-pipeline.yml`

---

## 📊 Pipeline Stages

### Stage 1: Build Backend 🔨
**Job:** `build-backend`  
**Duration:** ~1-2 minutes

**What it does:**
- Checkout code
- Setup JDK 21 (Temurin)
- Cache Maven dependencies
- Extract project version from pom.xml
- Build with `mvn clean package -DskipTests`
- Upload JAR artifact (7 days retention)

**Outputs:**
- `version`: Backend version number
- Artifact: `backend-jar` (compiled JAR file)

---

### Stage 2: Build Frontend 🎨
**Job:** `build-frontend`  
**Duration:** ~1-2 minutes

**What it does:**
- Checkout code
- Setup Node.js 20
- Cache npm dependencies
- Install with `npm ci --legacy-peer-deps`
- Build with `npm run build` (production mode)
- Upload build artifact (7 days retention)

**Outputs:**
- Artifact: `frontend-dist` (compiled frontend)

---

### Stage 3: Backend Unit Tests 🧪
**Job:** `test-backend-unit`  
**Duration:** ~2-3 minutes  
**Depends on:** `build-backend`

**What it does:**
- Run Maven tests with JaCoCo coverage
- Generate coverage reports
- Upload to Codecov (optional)
- Create test result artifacts
- Generate HTML coverage reports

**Artifacts:**
- `backend-test-results`: Surefire reports
- `backend-coverage`: JaCoCo HTML reports

**Coverage:**
- Tool: JaCoCo
- Format: XML + HTML
- Upload: Codecov (backend flag)

---

### Stage 4: Frontend Unit Tests 🎯
**Job:** `test-frontend-unit`  
**Duration:** ~1 minute  
**Depends on:** `build-frontend`

**What it does:**
- Run Vitest tests with coverage
- Generate coverage reports
- Upload to Codecov (optional)
- Create test result artifacts

**Artifacts:**
- `frontend-test-results`: Coverage reports

**Coverage:**
- Tool: Vitest
- Format: JSON + HTML
- Upload: Codecov (frontend flag)

---

### Stage 5: Integration Tests 🔗
**Job:** `test-backend-integration`  
**Duration:** ~3-5 minutes  
**Depends on:** `test-backend-unit`  
**Condition:** Only on `push` to `main` or `develop`

**What it does:**
- Start MySQL 8.0 service container
- Wait for MySQL readiness
- Run integration tests against real database
- Execute `*IntegrationTest` test classes

**Services:**
- MySQL 8.0
- Database: `concert_db`
- Credentials: root/rootpass

---

### Stage 6: Code Quality & Security 🛡️
**Job:** `code-quality`  
**Duration:** ~2-3 minutes  
**Depends on:** `test-backend-unit`, `test-frontend-unit`

**What it does:**
- Run Trivy security scanner
- Scan filesystem for vulnerabilities
- Generate SARIF report
- Upload to GitHub Security tab
- Check for CRITICAL, HIGH, MEDIUM severity issues

**Security Scan:**
- Tool: Trivy
- Scope: Filesystem
- Format: SARIF
- Severity: CRITICAL, HIGH, MEDIUM

---

### Stage 7: Docker Image Builds 🐳
**Job:** `build-docker`  
**Duration:** ~3-5 minutes  
**Depends on:** `test-backend-unit`, `test-frontend-unit`, `code-quality`  
**Condition:** Only on `push` to `main` or `develop`

**What it does:**
- Setup Docker Buildx
- Login to GitHub Container Registry (ghcr.io)
- Build and push backend Docker image
- Build and push frontend Docker image
- Tag with branch name and SHA
- Use GitHub Actions cache for layers

**Images:**
- Backend: `ghcr.io/{owner}/concert-backend`
- Frontend: `ghcr.io/{owner}/concert-frontend`

**Tags:**
- `{branch}` - Branch name
- `{branch}-{sha}` - Branch + commit SHA
- `latest` - Only on default branch

---

### Stage 8: Pipeline Summary 📋
**Job:** `pipeline-summary`  
**Duration:** ~10 seconds  
**Depends on:** All previous jobs  
**Runs:** Always

**What it does:**
- Generate comprehensive summary
- Show build results
- Show test results
- Show code quality status
- Display backend version
- Overall pass/fail status

**Summary includes:**
- Build Backend: success/failure
- Build Frontend: success/failure
- Backend Unit Tests: success/failure
- Frontend Unit Tests: success/failure
- Code Quality: success/failure
- Backend Version number
- Overall pipeline status

---

## ⚡ Execution Times

### For Pull Requests
```
Build Backend        1-2 min  │
Build Frontend       1-2 min  │ Parallel
                              │
Backend Unit Tests   2-3 min  │
Frontend Unit Tests  1 min    │ Parallel
                              │
Code Quality         2-3 min  │
                              │
Pipeline Summary     10 sec   │
                              
Total: ~5-7 minutes
```

### For main/develop Branches
```
Build Backend        1-2 min  │
Build Frontend       1-2 min  │ Parallel
                              │
Backend Unit Tests   2-3 min  │
Frontend Unit Tests  1 min    │ Parallel
                              │
Integration Tests    3-5 min  │
                              │
Code Quality         2-3 min  │
                              │
Docker Builds        3-5 min  │
                              │
Pipeline Summary     10 sec   │
                              
Total: ~10-15 minutes
```

---

## 🎯 Conditional Stages

### Integration Tests
**Runs when:**
- Event: `push` (not PRs)
- Branch: `main` OR `develop`

**Skipped when:**
- Pull requests
- Other branches (feature/, release/*, etc.)

### Docker Image Builds
**Runs when:**
- Event: `push` (not PRs)
- Branch: `main` OR `develop`

**Skipped when:**
- Pull requests
- Other branches

---

## 📦 Artifacts

All artifacts retained for **7 days**:

| Artifact Name | Contains | Size |
|---------------|----------|------|
| `backend-jar` | Compiled JAR file | ~50-100 MB |
| `frontend-dist` | Built frontend (.output) | ~20-50 MB |
| `backend-test-results` | Surefire reports (XML/TXT) | ~1-5 MB |
| `backend-coverage` | JaCoCo HTML reports | ~5-10 MB |
| `frontend-test-results` | Vitest coverage | ~1-5 MB |

---

## 🔒 Security Features

### Trivy Scanning
- **Scope:** Full filesystem scan
- **Severity:** CRITICAL, HIGH, MEDIUM
- **Format:** SARIF (GitHub Security compatible)
- **Upload:** Automatic to Security tab

### GitHub Security Integration
- Results visible in Security → Code scanning alerts
- Detailed vulnerability information
- Remediation suggestions
- CVE references

---

## 📊 Coverage Reporting

### Backend (JaCoCo)
- **Location:** `target/site/jacoco/`
- **Formats:** XML, HTML, CSV
- **Upload:** Codecov (optional)
- **Flag:** `backend`

### Frontend (Vitest)
- **Location:** `coverage/`
- **Formats:** JSON, HTML, LCOV
- **Upload:** Codecov (optional)
- **Flag:** `frontend`

### Codecov Integration
- Automatic upload after tests
- Trend tracking
- Coverage badges
- PR comments with diff

---

## 🐳 Docker Registry

**Registry:** GitHub Container Registry (ghcr.io)

**Authentication:**
- Username: GitHub actor
- Password: `GITHUB_TOKEN` (automatic)

**Image Naming:**
```
ghcr.io/<owner>/concert-backend:<tag>
ghcr.io/<owner>/concert-frontend:<tag>
```

**Tags:**
- `main` - Main branch builds
- `develop` - Develop branch builds
- `main-abc1234` - Main + commit SHA
- `latest` - Latest from default branch

---

## 🔄 Workflow Triggers

### On Push
```yaml
branches:
  - main
  - develop
  - release/**
paths:
  - main_backend/**
  - main_frontend/**
  - .github/workflows/full-pipeline.yml
```

**Runs full pipeline** when pushing to these branches with changes in specified paths.

### On Pull Request
```yaml
branches:
  - main
  - develop
  - release/**
```

**Runs build + test + security** (skips integration tests and Docker builds).

### Manual Trigger
```yaml
workflow_dispatch: {}
```

Can be triggered manually from GitHub Actions UI.

---

## 🚦 Status Checks

Pipeline fails if:
- ❌ Backend build fails
- ❌ Frontend build fails
- ❌ Backend tests fail
- ❌ Frontend tests fail
- ❌ Code quality check fails

Pipeline succeeds if:
- ✅ All builds pass
- ✅ All tests pass
- ✅ Security scan completes

**Note:** Integration tests and Docker builds are optional and don't affect overall status if skipped.

---

## 📈 Monitoring

### GitHub Actions UI
**View at:** `https://github.com/{owner}/develop/actions`

**Shows:**
- Workflow runs history
- Current run status
- Job-level details
- Artifact downloads
- Re-run capabilities

### Summary Tab
Each run generates a summary with:
- Build status per component
- Test results
- Code quality status
- Backend version
- Overall pass/fail

---

## 🛠️ Configuration

### Environment Variables
```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ${{ github.repository_owner }}
```

### Maven Options
```bash
MAVEN_OPTS: -Xmx1024m
```

### Node Environment
```bash
NODE_ENV: production  # For builds
```

---

## 🔧 Customization

### Add More Tests
Edit test jobs to include additional test suites:
```yaml
- name: Run E2E tests
  run: |
    cd main_frontend/concert1
    npm run test:e2e
```

### Change Docker Registry
Update `REGISTRY` environment variable:
```yaml
env:
  REGISTRY: docker.io  # Docker Hub
  # or
  REGISTRY: your-registry.com  # Private registry
```

### Adjust Conditions
Modify conditional logic:
```yaml
if: github.ref == 'refs/heads/main'  # Only main
if: startsWith(github.ref, 'refs/heads/release/')  # All releases
```

---

## 📝 Best Practices

### For Developers
1. **Run tests locally before pushing:**
   ```bash
   cd main_backend && mvn test
   cd main_frontend/concert1 && npm test
   ```

2. **Check security scan results** in the Security tab

3. **Review coverage reports** in artifacts

4. **Fix failing tests immediately** - don't merge with red builds

### For Maintainers
1. Monitor artifact storage usage (7-day retention)
2. Review security alerts regularly
3. Update dependencies when vulnerabilities found
4. Keep Docker images lean and updated

---

## 🎯 Current Status

**Commit:** `a60eab8`  
**Branch:** `release/v1.0.0`  
**Status:** ✅ ACTIVE

**Running at:**
👉 https://github.com/MorningMores/develop/actions

---

## 🚀 Next Steps

1. **Watch First Run:** Check Actions tab for pipeline execution
2. **Review Artifacts:** Download and inspect generated artifacts
3. **Check Coverage:** View coverage reports after tests complete
4. **Security Scan:** Review any vulnerabilities in Security tab
5. **Docker Images:** Verify images in Packages (if pushed to main/develop)

---

**This pipeline provides comprehensive CI/CD without deployment complexity!** 🎉
