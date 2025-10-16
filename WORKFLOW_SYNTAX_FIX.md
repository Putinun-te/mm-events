# Workflow Syntax Fix - backend-ci.yml

## Issue Found
After deploying the dependabot skip conditions, workflows started **actually running** on the main branch (they were skipped before on dependabot PRs). This exposed a pre-existing syntax error in `backend-ci.yml`.

## Error
```yaml
Line 83:
if: ${{ always() && secrets.CODECOV_TOKEN != '' }}
```

**Problem:** Cannot access `secrets` context in `if` conditions in this way. GitHub Actions requires proper syntax for secret checks.

## Fix Applied
**Commit:** `46f5a78`

**Before:**
```yaml
- name: Upload coverage to Codecov (optional)
  if: ${{ always() && secrets.CODECOV_TOKEN != '' }}
  uses: codecov/codecov-action@v4
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: main_backend/target/site/jacoco/jacoco.xml
    fail_ci_if_error: false
```

**After:**
```yaml
- name: Upload coverage to Codecov (optional)
  if: always()
  uses: codecov/codecov-action@v4
  continue-on-error: true
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: main_backend/target/site/jacoco/jacoco.xml
    fail_ci_if_error: false
```

## Changes Made:
1. ✅ Removed secret check from `if` condition
2. ✅ Added `continue-on-error: true` to handle missing secrets gracefully
3. ✅ Kept `if: always()` to ensure step runs even if previous steps fail
4. ✅ Kept `fail_ci_if_error: false` for additional safety

## Why This Approach:
- **`continue-on-error: true`** is the recommended way to make steps optional
- If `CODECOV_TOKEN` is not set, the step will fail but won't break the workflow
- If the token is set, coverage will upload successfully
- Simpler and more maintainable than complex secret checks

## Impact:
- ✅ Backend CI workflow will now run without syntax errors
- ✅ Workflow will complete successfully whether codecov token exists or not
- ✅ Test results will still be reported even if codecov upload fails

## Commit Pushed:
```
Commit: 46f5a78
Message: "fix(workflow): Fix secrets context in backend-ci.yml"
Status: Pushed to main
```

## Next Steps:
The workflows should now run properly on the main branch. Check the Actions tab to verify:
- https://github.com/MorningMores/develop/actions

Expected result:
- ✅ Frontend E2E should pass
- ✅ Backend CI should pass
- ✅ CI - Frontend & Backend Tests should pass

---

**Note:** This was a pre-existing issue that only surfaced when we fixed the dependabot skip conditions. The workflows are now actually running, which is the correct behavior!
