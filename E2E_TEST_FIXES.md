# E2E Test Fixes - Authentication Endpoints

## Problem Summary

3 E2E tests were failing with incorrect HTTP status codes:

### Failed Tests:
1. **GET /api/auth/test without token**
   - Expected: 401 or 403
   - Actual: 200 (OK)
   
2. **GET /api/auth/test with invalid token**
   - Expected: 401 or 403
   - Actual: 500 (Internal Server Error)
   
3. **GET /api/events/me without authentication**
   - Expected: 401 or 403
   - Actual: 500 (Internal Server Error)

## Root Causes

### Issue 1: /api/auth/test was publicly accessible
**Location:** `SecurityConfig.java`
```java
.requestMatchers("/api/auth/test").permitAll()  // ❌ Wrong - should require auth
```

### Issue 2: Invalid tokens caused 500 errors
**Location:** `JwtAuthenticationFilter.java`
- No exception handling for malformed/invalid JWT tokens
- Uncaught exceptions resulted in 500 errors instead of 401

### Issue 3: /api/events/me was incorrectly made public
**Location:** `SecurityConfig.java`
```java
.requestMatchers(HttpMethod.GET, "/api/events", "/api/events/", "/api/events/**").permitAll()
```
This pattern incorrectly matched `/api/events/me` and made it public

### Issue 4: No custom authentication entry point
- Spring Security's default behavior returns 403 Forbidden
- E2E tests expect 401 Unauthorized for auth failures

## Solutions Implemented

### 1. Fixed SecurityConfig.java

**Before:**
```java
.authorizeHttpRequests(authz -> authz
    .requestMatchers("/api/auth/register").permitAll()
    .requestMatchers("/api/auth/login").permitAll()
    .requestMatchers("/api/auth/test").permitAll()  // ❌ Wrong
    .requestMatchers(HttpMethod.GET, "/api/events", "/api/events/", "/api/events/**").permitAll()
    // ...
)
```

**After:**
```java
.authorizeHttpRequests(authz -> authz
    .requestMatchers("/api/auth/register").permitAll()
    .requestMatchers("/api/auth/login").permitAll()
    // /api/auth/test now requires authentication ✅
    .requestMatchers("/api/events/me").authenticated()  // ✅ Explicit auth required
    .requestMatchers(HttpMethod.GET, "/api/events", "/api/events/", "/api/events/**").permitAll()
    // ...
)
```

### 2. Created JwtAuthenticationEntryPoint.java

**New file:** `src/main/java/com/concert/security/JwtAuthenticationEntryPoint.java`

```java
@Component
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {
    @Override
    public void commence(HttpServletRequest request, 
                        HttpServletResponse response,
                        AuthenticationException authException) throws IOException {
        
        // Return 401 Unauthorized for any authentication failure
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.getWriter().write("{\"error\": \"Unauthorized\", \"message\": \"" 
            + authException.getMessage() + "\"}");
    }
}
```

### 3. Updated SecurityConfig to use custom entry point

```java
@Autowired
private JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        // ...
        .exceptionHandling(exception -> exception
            .authenticationEntryPoint(jwtAuthenticationEntryPoint)  // ✅ Custom 401 handler
        )
        // ...
}
```

### 4. Added exception handling in JwtAuthenticationFilter

**Before:**
```java
jwt = authHeader.substring(7);
username = jwtService.extractUsername(jwt);  // ❌ Can throw exception
```

**After:**
```java
try {
    jwt = authHeader.substring(7);
    username = jwtService.extractUsername(jwt);
    // ... validation logic
} catch (Exception e) {
    // Invalid token - clear context and let Spring Security handle it
    SecurityContextHolder.clearContext();
    logger.error("JWT validation failed: " + e.getMessage());
}
```

## Test Results

### Before Fix:
```
✖  auth/auth-api.cy.js      9 tests   7 passing   2 failing
✔  bookings/bookings-api.cy.js  14 tests  14 passing  0 failing
✖  events/events-api.cy.js     11 tests  10 passing  1 failing
-----------------------------------------------------------
✖  2 of 3 failed (67%)        34 tests  31 passing  3 failing
```

### Expected After Fix:
```
✔  auth/auth-api.cy.js      9 tests   9 passing   0 failing
✔  bookings/bookings-api.cy.js  14 tests  14 passing  0 failing
✔  events/events-api.cy.js     11 tests  11 passing  0 failing
-----------------------------------------------------------
✔  3 of 3 passed (100%)       34 tests  34 passing  0 failing
```

## Files Changed

| File | Type | Changes |
|------|------|---------|
| `SecurityConfig.java` | Modified | - Removed permitAll() from /api/auth/test<br>- Added .authenticated() for /api/events/me<br>- Added custom authenticationEntryPoint |
| `JwtAuthenticationEntryPoint.java` | **New** | Custom entry point returning 401 for auth failures |
| `JwtAuthenticationFilter.java` | Modified | Added try-catch for invalid token handling |

## Security Implications

### ✅ Improvements:
1. **Better error responses:** 401 instead of 500 for auth failures
2. **Proper endpoint protection:** /api/auth/test now requires authentication
3. **Explicit security rules:** /api/events/me explicitly requires auth
4. **Graceful error handling:** Invalid tokens don't crash the app

### 🔒 No Security Regressions:
- All other endpoints maintain same security posture
- Public endpoints still public (register, login, GET events)
- Protected endpoints still protected (bookings, my events, etc.)

## Verification Steps

1. **Run E2E tests:**
   ```bash
   cd main_backend/cypress-tests
   npm run test:e2e
   ```

2. **Manual testing:**
   ```bash
   # Should return 401
   curl -i http://localhost:8080/api/auth/test
   
   # Should return 401
   curl -i -H "Authorization: Bearer invalid.token" http://localhost:8080/api/auth/test
   
   # Should return 401
   curl -i http://localhost:8080/api/events/me
   ```

3. **Check GitHub Actions:**
   - E2E tests in workflow should pass
   - Test reporter should show all tests passing

## Commit Details

```
Commit: 7480bb3
Branch: BE-Tester
Author: [Your Name]
Date: October 14, 2025

fix: Fix E2E test failures for authentication endpoints

Changes:
1. Removed permitAll() from /api/auth/test
2. Added explicit .authenticated() for /api/events/me
3. Created JwtAuthenticationEntryPoint for 401 responses
4. Updated JwtAuthenticationFilter with exception handling
5. Added custom exception handling in SecurityConfig

Fixes 3 E2E test failures:
- GET /api/auth/test without token
- GET /api/auth/test with invalid token  
- GET /api/events/me without auth
```

## Next Steps

1. ✅ **Pushed to BE-Tester branch** - Changes are live
2. 🔄 **GitHub Actions will run** - Verify E2E tests pass
3. 📋 **Review PR** - Merge to main when ready
4. 🧪 **Monitor production** - Ensure 401 responses work as expected

## Related Documentation

- [Spring Security Exception Handling](https://docs.spring.io/spring-security/reference/servlet/architecture.html#servlet-exceptiontranslationfilter)
- [Custom Authentication Entry Point](https://www.baeldung.com/spring-security-custom-authentication-failure-handler)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

---

**Status:** ✅ Fixed and Pushed to `devops/BE-Tester`
