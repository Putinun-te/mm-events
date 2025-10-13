# GitHub Branch Protection Setup Guide

**Date:** October 13, 2025  
**Repository:** MorningMores/develop  
**Branches to Protect:** `main`, `version1.0`, `develop`

---

## 🎯 Overview

This guide walks through configuring GitHub Branch Protection rules and Codecov integration to enforce quality gates before merging code.

---

## 📋 Prerequisites

- [ ] GitHub repository admin access
- [ ] CI/CD workflow pushed to repository (`.github/workflows/ci.yml`)
- [ ] Codecov account (free for public repositories)

---

## Part 1: Setup Codecov Token

### Step 1: Create Codecov Account

1. Go to [codecov.io](https://codecov.io)
2. Click **"Sign up with GitHub"**
3. Authorize Codecov to access your repositories
4. Select the `MorningMores/develop` repository

### Step 2: Get Codecov Upload Token

1. Navigate to your repository in Codecov dashboard
2. Go to **Settings** → **General**
3. Find the **Repository Upload Token** section
4. Click **"Copy"** to copy the token (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
5. **⚠️ IMPORTANT:** Keep this token secure - treat it like a password!

### Step 3: Add Token to GitHub Secrets

1. Go to your GitHub repository: `https://github.com/MorningMores/develop`
2. Click **Settings** (repository settings, not your profile)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **"New repository secret"**
5. Fill in the form:
   - **Name:** `CODECOV_TOKEN`
   - **Secret:** Paste the token from Step 2
6. Click **"Add secret"**

### Step 4: Verify Badge Display

1. **Check README badges:**
   - Navigate to your repository homepage
   - Verify the following badges appear:
     ```markdown
     [![CI/CD Pipeline](https://github.com/MorningMores/develop/actions/workflows/ci.yml/badge.svg)](...)
     [![Frontend Coverage](https://codecov.io/gh/MorningMores/develop/branch/main/graph/badge.svg?flag=frontend)](...)
     [![Backend Coverage](https://codecov.io/gh/MorningMores/develop/branch/main/graph/badge.svg?flag=backend)](...)
     ```

2. **Trigger a CI build:**
   ```bash
   git add .
   git commit -m "test: Trigger CI to upload coverage"
   git push origin version1.0
   ```

3. **Wait for CI to complete** (5-10 minutes)

4. **Check Codecov dashboard:**
   - Go to `https://codecov.io/gh/MorningMores/develop`
   - Verify coverage data appears
   - Check that `frontend` and `backend` flags show separate coverage

5. **Verify badges update:**
   - Refresh your GitHub repository page
   - Badges should now show actual coverage percentages
   - Click badges to ensure they link to correct reports

---

## Part 2: Configure Branch Protection Rules

### For Branch: `main`

1. **Navigate to Branch Protection:**
   - Go to `https://github.com/MorningMores/develop/settings/branches`
   - Click **"Add branch protection rule"**

2. **Branch Name Pattern:**
   ```
   main
   ```

3. **Protect Matching Branches - Check These Options:**

   #### ✅ Require a pull request before merging
   - Check this box
   - **Required approvals:** `1` (or `2` for stricter control)
   - ✅ **Dismiss stale pull request approvals when new commits are pushed**
   - ✅ **Require review from Code Owners** (if you have CODEOWNERS file)
   - ⬜ Allow specified actors to bypass pull request requirements (leave unchecked unless needed)

   #### ✅ Require status checks to pass before merging
   - Check this box
   - ✅ **Require branches to be up to date before merging**
   - **Status checks that are required:**
     - Search and add: `frontend-tests`
     - Search and add: `backend-tests`
     - Search and add: `e2e-tests`
     - Search and add: `docker-build`
     - ⚠️ **Note:** These checks will only appear after the first CI run

   #### ✅ Require conversation resolution before merging
   - Check this box (ensures all review comments addressed)

   #### ✅ Require signed commits (Optional but recommended)
   - Check this box for enhanced security
   - Requires developers to setup GPG signing

   #### ✅ Require linear history (Optional)
   - Check this box to enforce rebase/squash merges
   - Prevents merge commits

   #### ⬜ Require deployments to succeed before merging
   - Leave unchecked (unless you have deployment checks)

   #### ✅ Lock branch
   - ⬜ Leave unchecked (locks prevent all pushes)

   #### ⬜ Do not allow bypassing the above settings
   - Leave unchecked initially (allows admins to force-push in emergencies)
   - ✅ Check this for maximum protection (recommended for production)

   #### ✅ Restrict who can push to matching branches (Optional)
   - Check if you want to limit who can push
   - Add specific teams/users

4. **Rules applied to everyone including administrators:**
   - ✅ **Include administrators** (recommended)
   - Ensures even admins follow the rules

5. **Allow force pushes:**
   - ⬜ Leave unchecked (force pushes can rewrite history)

6. **Allow deletions:**
   - ⬜ Leave unchecked (prevents accidental branch deletion)

7. **Click "Create"** to save the rule

---

### For Branch: `version1.0`

**Repeat the same steps as `main`, but with branch name pattern:**
```
version1.0
```

**Recommended differences for `version1.0`:**
- Required approvals: `1` (can be same as main)
- Status checks: Same as main (all 4 checks)
- Linear history: Optional (may allow merge commits for version branches)

---

### For Branch: `develop`

**Repeat the same steps, but with branch name pattern:**
```
develop
```

**Recommended differences for `develop`:**
- Required approvals: `1` (can be more lenient)
- Status checks: **Required** (all 4 checks must pass)
- Conversation resolution: Optional (can be unchecked for faster iteration)
- Linear history: Optional
- Signed commits: Optional

---

## Part 3: Configure Status Check Requirements

### Step 1: Trigger Initial CI Run

If you haven't pushed the CI workflow yet:

```bash
# Ensure CI workflow is committed
git add .github/workflows/ci.yml
git commit -m "ci: Add comprehensive CI/CD pipeline"
git push origin version1.0

# Wait for CI to complete
# Check: https://github.com/MorningMores/develop/actions
```

### Step 2: Add Status Checks to Branch Protection

After the first CI run completes:

1. Go back to **Settings** → **Branches**
2. Click **"Edit"** on the `main` branch protection rule
3. Scroll to **"Require status checks to pass before merging"**
4. In the search box, type: `frontend-tests`
5. Click the check that appears (it will now be visible)
6. Repeat for: `backend-tests`, `e2e-tests`, `docker-build`
7. Click **"Save changes"**

### Step 3: Verify Status Checks

1. Create a test branch and make a change:
   ```bash
   git checkout -b test-branch-protection
   echo "# Test" >> README.md
   git add README.md
   git commit -m "test: Verify branch protection"
   git push origin test-branch-protection
   ```

2. Create a Pull Request on GitHub:
   - Go to your repository
   - Click **"Pull requests"** → **"New pull request"**
   - Select `main` as base, `test-branch-protection` as compare
   - Click **"Create pull request"**

3. Verify the following:
   - ⏳ 4 status checks appear (frontend-tests, backend-tests, e2e-tests, docker-build)
   - ⏳ "Merging is blocked" message shows while checks run
   - ✅ After checks pass, "Merge pull request" becomes available
   - ✅ "Review required" message if you configured approvals

---

## Part 4: Testing Branch Protection

### Test 1: Verify Direct Push Blocked

```bash
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "test: Direct push"
git push origin main
```

**Expected Result:**
```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: error: At least 1 approving review is required by reviewers with write access.
```

✅ **Protection working!**

### Test 2: Verify PR Required

1. Create a branch with changes
2. Push to GitHub
3. Try to merge without PR → Should be blocked
4. Create PR → Should require approvals and status checks

### Test 3: Verify Status Checks Required

1. Create a PR
2. Wait for CI checks
3. If any check fails → Merge button disabled
4. All checks pass → Merge button enabled (if approvals met)

---

## Part 5: Codecov Configuration (Optional Advanced Setup)

Create `codecov.yml` in repository root for custom configuration:

```yaml
# codecov.yml
coverage:
  status:
    project:
      default:
        target: 80%        # Minimum coverage target
        threshold: 2%      # Allow 2% drop
    patch:
      default:
        target: 70%        # New code coverage target
        
comment:
  layout: "header, diff, flags, components, footer"
  behavior: default
  require_changes: false

flags:
  frontend:
    paths:
      - main_frontend/concert1/
    carryforward: true
  backend:
    paths:
      - main_backend/src/
    carryforward: true

ignore:
  - "**/*.spec.ts"
  - "**/*.test.ts"
  - "**/test/**"
  - "**/tests/**"
  - "**/node_modules/**"
  - "**/target/**"
```

Commit this file:
```bash
git add codecov.yml
git commit -m "ci: Configure Codecov settings"
git push origin version1.0
```

---

## 📊 Verification Checklist

After completing all steps:

- [ ] Codecov token added to GitHub secrets
- [ ] Coverage badges displaying correctly in README
- [ ] Branch protection enabled for `main`
- [ ] Branch protection enabled for `version1.0`
- [ ] Branch protection enabled for `develop`
- [ ] Status checks required: frontend-tests, backend-tests, e2e-tests, docker-build
- [ ] PR reviews required (1+ approvals)
- [ ] Direct pushes to protected branches blocked
- [ ] Test PR created and verified all checks run
- [ ] Codecov dashboard showing coverage data

---

## 🚨 Troubleshooting

### Status Checks Not Appearing

**Problem:** Can't add status checks in branch protection  
**Solution:** 
- Ensure CI workflow has run at least once
- Check workflow file is in `.github/workflows/ci.yml`
- Verify workflow syntax is correct
- Check Actions tab for any errors

### Codecov Badge Shows "Unknown"

**Problem:** Coverage badge displays "unknown" instead of percentage  
**Solution:**
- Wait for CI to complete (can take 5-10 minutes)
- Verify `CODECOV_TOKEN` is correctly set in secrets
- Check Codecov dashboard for upload errors
- Ensure coverage reports are generated (check CI logs)

### Pull Request Merge Blocked Even When Checks Pass

**Problem:** Can't merge even though all checks are green  
**Solution:**
- Check if PR review approvals are required
- Verify branch is up to date with base branch
- Check for unresolved conversations (if required)
- Ensure you have write access to the repository

### Coverage Upload Fails in CI

**Problem:** CI workflow fails at Codecov upload step  
**Solution:**
```yaml
# In ci.yml, ensure token is referenced correctly:
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    token: ${{ secrets.CODECOV_TOKEN }}  # ← Check this line
    flags: backend
    fail_ci_if_error: false  # ← Don't fail CI if Codecov is down
```

---

## 📚 Additional Resources

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [Codecov Documentation](https://docs.codecov.com/docs)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Status Check Requirements](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks)

---

## 🎉 Success Criteria

Your branch protection is correctly configured when:

✅ You **cannot** push directly to `main`, `version1.0`, or `develop`  
✅ All changes **must** go through Pull Requests  
✅ PRs **require** 1+ approvals before merging  
✅ PRs **require** all 4 CI checks to pass (frontend, backend, e2e, docker)  
✅ Coverage badges display actual percentages in README  
✅ Codecov dashboard shows separate frontend/backend coverage  
✅ Failed CI checks **block** PR merging  
✅ Unreviewed PRs **cannot** be merged  

---

**Setup Time:** ~30 minutes  
**Maintenance:** Minimal (update status checks when adding new CI jobs)  
**Security Level:** High (enforces code quality and review process)
