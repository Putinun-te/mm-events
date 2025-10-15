# Remember Me Feature - Testing Guide

## What Was Fixed

### Issues Before Fix:
1. ❌ "Unauthorized" message showing on protected pages when not logged in
2. ❌ Error toasts appearing before redirect to login
3. ❌ Inconsistent behavior between localStorage and sessionStorage
4. ❌ User stayed logged in even when "Remember Me" was unchecked after browser/container restart

### Changes Made:

#### 1. **middleware/auth.global.ts**
- Changed redirect to use `replace: true` for silent navigation
- Improved logic to only store redirect path when not coming from login page
- Removed unnecessary logging that could expose auth flow

#### 2. **app/composables/useAuth.ts**
- Fixed `loadFromStorage()` to respect "Remember Me" choice
- When `remember_me === 'true'`: Load from localStorage (persistent)
- When `remember_me !== 'true'`: Load from sessionStorage (cleared on browser close)
- No more fallback between storages

#### 3. **app/composables/useUnauthorizedHandler.ts**
- Added `showMessage` parameter to control when error toasts appear
- Error messages now only show for actual API failures (401/403 responses)
- No error message on initial page load - middleware handles silent redirect

#### 4. **app/pages/MyEventsPage.vue**
- Removed manual redirect logic (middleware handles this)
- Added proper unauthorized error handling for API calls
- Distinguishes between initial load (no token) and API failure (expired token)

#### 5. **app/pages/MyBookingsPage.vue**
- Same improvements as MyEventsPage
- Clean separation between navigation auth and API auth

#### 6. **app/components/Login.vue**
- Uses `replace: true` for all navigation after login
- Prevents back button from returning to login page

## Testing Scenarios

### Scenario 1: Remember Me - CHECKED ✅

**Test Steps:**
1. Open http://localhost:3000/concert/LoginPage
2. Enter credentials (e.g., `john@example.com` / `password123`)
3. ✅ **CHECK** the "Remember Me" checkbox
4. Click "Login"
5. Verify you're redirected and logged in
6. Open DevTools → Application → Storage:
   - localStorage should have: `jwt_token`, `user_email`, `username`, `remember_me=true`
   - sessionStorage should be empty
7. **Close browser completely**
8. **Restart Docker containers:**
   ```bash
   docker-compose restart
   ```
9. Open http://localhost:3000/concert/MyEventsPage

**Expected Result:**
- ✅ User stays logged in
- ✅ Page loads with user's events
- ✅ No redirect to login
- ✅ Token loaded from localStorage

---

### Scenario 2: Remember Me - UNCHECKED ❌

**Test Steps:**
1. **Clear all storage first:**
   - Open DevTools → Application → Storage
   - Clear localStorage and sessionStorage
2. Open http://localhost:3000/concert/LoginPage
3. Enter credentials
4. ❌ **UNCHECK** the "Remember Me" checkbox (or leave it unchecked)
5. Click "Login"
6. Verify login success
7. Open DevTools → Application → Storage:
   - sessionStorage should have: `jwt_token`, `user_email`, `username`
   - localStorage should NOT have `jwt_token` (might have `remember_me=false`)
8. **Close browser completely**
9. **Restart Docker containers:**
   ```bash
   docker-compose restart
   ```
10. Open http://localhost:3000/concert/MyEventsPage

**Expected Result:**
- ✅ User is logged out (sessionStorage cleared on browser close)
- ✅ Immediately redirected to /LoginPage
- ✅ **NO "Unauthorized" message shown**
- ✅ **NO error toast appears**
- ✅ Silent redirect to login page
- ✅ After login, redirected back to /MyEventsPage

---

### Scenario 3: Container Restart (Remember Me = Checked)

**Test Steps:**
1. Login with "Remember Me" checked
2. **WITHOUT closing browser:**
   ```bash
   docker-compose restart
   ```
3. Refresh the page or navigate to http://localhost:3000/concert/MyEventsPage

**Expected Result:**
- ✅ User stays logged in
- ✅ Token persists in localStorage
- ✅ No redirect needed

---

### Scenario 4: Container Restart (Remember Me = Unchecked)

**Test Steps:**
1. Login with "Remember Me" unchecked
2. **WITHOUT closing browser:**
   ```bash
   docker-compose restart
   ```
3. Refresh the page or navigate to http://localhost:3000/concert/MyEventsPage

**Expected Result:**
- ✅ User stays logged in (sessionStorage persists within same browser session)
- ✅ Token still available in sessionStorage
- ✅ No redirect needed

---

### Scenario 5: Expired Token (API Returns 401)

**Test Steps:**
1. Login successfully
2. Manually modify the JWT token in storage to make it invalid:
   - DevTools → Application → Storage
   - Change `jwt_token` value to `invalid_token_xxx`
3. Navigate to http://localhost:3000/concert/MyEventsPage
4. Wait for API call to fail

**Expected Result:**
- ✅ API returns 401 Unauthorized
- ✅ Error toast appears: "Your session has expired. Please login again."
- ✅ Redirected to login page
- ✅ After login, redirected back to /MyEventsPage

---

### Scenario 6: Direct Access to Protected Page (No Token)

**Test Steps:**
1. Clear all storage (logout)
2. Directly navigate to http://localhost:3000/concert/MyBookingsPage

**Expected Result:**
- ✅ Immediately redirected to /LoginPage
- ✅ **NO "Unauthorized" message**
- ✅ **NO error toast**
- ✅ Path stored: `/MyBookingsPage`
- ✅ After login, redirected back to /MyBookingsPage

---

### Scenario 7: Multiple Tabs (Remember Me = Unchecked)

**Test Steps:**
1. Login with "Remember Me" unchecked
2. Open the app in multiple tabs
3. Close all tabs
4. Reopen browser and navigate to protected page

**Expected Result:**
- ✅ All tabs logged out
- ✅ sessionStorage cleared
- ✅ Silent redirect to login

---

## Technical Details

### Storage Strategy

| Remember Me | Storage Used    | Persists After    | Cleared When           |
|-------------|-----------------|-------------------|------------------------|
| ✅ Checked  | localStorage    | Browser close     | Manual logout / Clear data |
| ❌ Unchecked| sessionStorage  | Container restart | Browser close / New session |

### Middleware vs API Auth

| Scenario                  | Handler                | Action                          | Message |
|---------------------------|------------------------|---------------------------------|---------|
| Initial page load (no token) | auth.global.ts middleware | Silent redirect to /LoginPage | None    |
| API call fails (401/403)   | useUnauthorizedHandler | Show error + redirect          | "Session expired..." |
| Token valid                | No handler              | Continue normally              | None    |

### Protected Routes

These routes are protected by `auth.global.ts`:
- `/AccountPage`
- `/MyBookingsPage`
- `/MyEventsPage`
- `/CreateEventPage`
- `/EditEventPage`

## Quick Test Commands

```bash
# Restart containers
docker-compose restart

# Check if frontend is running
docker ps | grep concert-frontend

# View frontend logs
docker logs concert-frontend --tail 50

# Clear all Docker volumes (nuclear option)
docker-compose down -v
docker-compose up -d --build
```

## Success Criteria

✅ **All scenarios pass without:**
- "Unauthorized" text appearing on page load
- Error toasts on initial navigation
- Inconsistent storage behavior
- Users staying logged in when they shouldn't

✅ **Remember Me works as expected:**
- Checked = Persistent across browser restarts
- Unchecked = Cleared when browser closes

✅ **Silent redirects work:**
- No error messages for navigation-based auth checks
- Error messages only for API call failures
