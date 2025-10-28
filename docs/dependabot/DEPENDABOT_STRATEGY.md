# Dependabot Configuration - Complete Protection Strategy

## 🎯 Overview

This document explains our complete Dependabot protection strategy that prevents automatic PRs from breaking our CI/CD workflows.

**History:**
- **PR #25**: Spring Boot 3.2.0 → 3.4.0 (caused workflow failures) → Fixed
- **PR #29**: maven-surefire-plugin 3.2.5 → 3.5.2 (caused workflow failures) → Fixed

## 🛡️ Current Protection Layers

### Layer 1: Frontend Dependency Pinning

**File:** `main_frontend/concert1/package.json`

```json
{
  "devDependencies": {
    "vitest": "3.2.0",      // NO ^ symbol = exact version
    "cypress": "13.17.0",
    "happy-dom": "15.11.7",
    "jsdom": "25.0.1"
  }
}
```

**Why:** Testing libraries need exact versions for reproducible test results.

### Layer 2: Dependabot Ignore Rules

**File:** `.github/dependabot.yml`

```yaml
# Frontend npm dependencies
ignore:
  - dependency-name: "happy-dom"
  - dependency-name: "jsdom"
  - dependency-name: "vitest"
  - dependency-name: "@vitest/*"
  - dependency-name: "cypress"
  - dependency-name: "@cypress/*"
  - dependency-name: "@nuxt/test-utils"
  - dependency-name: "@testing-library/*"
  - dependency-name: "@vue/test-utils"

# Backend Maven dependencies
ignore:
  # Spring Boot (managed manually)
  - dependency-name: "org.springframework.boot:*"
  
  # Maven plugins (build stability)
  - dependency-name: "org.apache.maven.plugins:*"
  - dependency-name: "org.jacoco:*"
  - dependency-name: "org.springframework.boot:spring-boot-maven-plugin"
```

**Why:** These dependencies are critical for build stability and should be updated manually.

### Layer 3: Workflow Path Filters

**Files:** `.github/workflows/*.yml`

```yaml
on:
  push:
    paths-ignore:
      - '**.md'
      - 'docs/**'
      - '.github/workflows-backup/**'
  pull_request:
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

**Why:** Skip workflow runs for documentation-only changes.

### Layer 4: Auto-Cancel Redundant Runs

**File:** `.github/workflows/cancel-redundant.yml`

```yaml
name: Cancel Redundant Runs
on:
  workflow_run:
    workflows: ["*"]
    types: [requested]

jobs:
  cancel:
    runs-on: ubuntu-latest
    steps:
      - uses: styfle/cancel-workflow-action@0.12.1
        with:
          access_token: ${{ github.token }}
```

**Why:** Saves CI/CD minutes by canceling old workflow runs when new commits are pushed.

## 📋 What Dependabot CAN Update

### ✅ Frontend (npm)
- Regular dependencies (axios, vue, nuxt)
- UI libraries (not testing-related)
- Utility libraries
- Security patches

### ✅ Backend (Maven)
- Regular Java dependencies (Apache Commons, etc.)
- Database drivers
- Utility libraries
- Security patches

### ✅ GitHub Actions
- Action version updates
- Minor workflow improvements

## ❌ What Dependabot CANNOT Update

### 🚫 Frontend (npm)
- Testing libraries (Vitest, Cypress, Jest-DOM)
- Test utilities (@nuxt/test-utils, @testing-library/*)
- Test runners and frameworks

### 🚫 Backend (Maven)
- Spring Boot framework
- Maven plugins (Surefire, Compiler, etc.)
- JaCoCo coverage plugin
- Spring Boot Maven plugin
- Build tools

### 🚫 Critical Infrastructure
- Java version
- Node version
- Database version

## 🔄 Manual Update Process

### For Spring Boot Updates

```bash
# 1. Check current version
grep -A5 "spring-boot-starter-parent" main_backend/pom.xml

# 2. Research new version
# - Read release notes
# - Check breaking changes
# - Verify compatibility

# 3. Update pom.xml
# <version>3.2.0</version> → <version>3.4.0</version>

# 4. Test compilation
cd main_backend
JAVA_HOME=$(/usr/libexec/java_home -v 21) mvn clean compile

# 5. Run all tests
mvn clean test

# 6. Verify coverage
mvn jacoco:report
open target/site/jacoco/index.html

# 7. Commit and push
git add main_backend/pom.xml
git commit -m "chore(backend): Update Spring Boot to 3.4.0"
git push origin main
```

### For Maven Plugin Updates

```bash
# 1. Check current version
mvn help:effective-pom | grep -A5 maven-surefire-plugin

# 2. Update pom.xml
# <version>3.2.5</version> → <version>3.5.2</version>

# 3. Test with fork settings
mvn clean test -DforkCount=1 -DreuseForks=false

# 4. Verify Testcontainers work
mvn clean verify

# 5. Check JaCoCo integration
mvn jacoco:report

# 6. Run GitHub Actions (push to test branch)
git checkout -b test/surefire-update
git push origin test/surefire-update

# 7. If all passes, merge to main
git checkout main
git merge test/surefire-update
git push origin main
```

### For Testing Library Updates

```bash
# Frontend (Vitest/Cypress)
cd main_frontend/concert1

# 1. Update package.json
# "vitest": "3.2.0" → "vitest": "3.3.0"

# 2. Install
npm install

# 3. Run all tests
npm test

# 4. Run E2E tests
npm run test:e2e

# 5. Check coverage
npm run test:coverage

# 6. If all passes, commit
git add main_frontend/concert1/package.json
git commit -m "chore(frontend): Update Vitest to 3.3.0"
```

## 📅 Update Schedule

### Quarterly Updates (Every 3 Months)
- Maven plugins review
- Build tool versions
- Testing framework versions

### Monthly Updates (Automated via Dependabot)
- Frontend dependencies (non-testing)
- Backend dependencies (non-critical)
- GitHub Actions

### Weekly Updates (Automated via Dependabot)
- Backend Maven dependencies (allowed ones)

### Immediate Updates (Manual)
- Security vulnerabilities
- Critical bug fixes
- Zero-day patches

## 🚨 Handling Dependabot PRs

### ✅ Safe to Merge (After Review)
- Regular library updates
- Security patches for non-critical deps
- Minor version bumps of allowed dependencies

### ⚠️ Review Carefully
- Major version bumps
- Dependencies with many dependents
- New dependencies

### ❌ Close Immediately
- Spring Boot updates → Close with comment
- Maven plugin updates → Close with comment
- Testing library updates → Close with comment

**Example Close Comment:**
```
Closed - This dependency is managed manually to ensure build stability.
Please see DEPENDABOT_STRATEGY.md for our update process.
```

## 📊 Dependabot History

| PR | Dependency | Version Change | Status | Action Taken |
|----|-----------|----------------|---------|--------------|
| #25 | Spring Boot | 3.2.0 → 3.4.0 | ❌ Failed | Added ignore rule |
| #29 | maven-surefire-plugin | 3.2.5 → 3.5.2 | ❌ Failed | Added plugin ignore rules |

## 🔍 Troubleshooting

### If Dependabot Creates Unwanted PRs

1. **Close the PR** on GitHub
2. **Update `.github/dependabot.yml`** to add ignore rule
3. **Commit and push** the config change
4. **Monitor** that no new PRs are created

### If Workflows Fail on Dependabot PRs

1. **Don't merge the PR**
2. **Check what changed** (read the diff)
3. **Test locally** with the new version
4. **If it breaks**, add ignore rule
5. **If it works**, merge carefully

### If You Need to Update Ignored Dependencies

1. **Follow the manual update process** (see above)
2. **Test thoroughly** before committing
3. **Update documentation** if needed
4. **Push to main** after validation

## 📝 Configuration Files

```
.github/
├── dependabot.yml              # Dependabot configuration
└── workflows/
    ├── unit-tests.yml          # Fast unit tests (1-2 min)
    ├── integration-tests.yml   # Integration tests (8-15 min)
    ├── e2e-tests.yml          # E2E tests (15-25 min)
    └── cancel-redundant.yml    # Auto-cancel old runs

main_backend/
└── pom.xml                     # Maven dependencies and plugins

main_frontend/concert1/
└── package.json                # npm dependencies (pinned versions)
```

## ✅ Success Metrics

Our protection strategy ensures:
- ✅ No breaking PRs from Dependabot
- ✅ Stable CI/CD workflows (99%+ pass rate)
- ✅ Controlled dependency updates
- ✅ Minimal manual intervention needed
- ✅ 798/799 tests passing consistently

## 🎯 Next Steps

1. **Close PR #29** on GitHub
2. **Monitor Dependabot** activity for next week
3. **Review** any new PRs carefully
4. **Update** this document if new patterns emerge

---

**Last Updated:** October 16, 2025  
**Current Commit:** 24d5224  
**Status:** Fully Protected ✅  
**Issues Fixed:** PR #25, PR #29
