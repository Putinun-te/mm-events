# Controller Coverage Improvement Plan

**Current Coverage:** 63%  
**Target Coverage:** 80%+  
**Package:** `com.concert.controller`  
**Priority:** Medium (Short-term)

---

## 📊 Current State Analysis

### Coverage Breakdown (from JaCoCo report)

| Metric | Current | Target | Gap |
|--------|---------|--------|-----|
| Instructions | 211/334 (63%) | 80%+ | +17% needed |
| Branches | 9/38 (23%) | 70%+ | +47% needed |
| Lines | 55/75 (73%) | 80%+ | +7% needed |
| Methods | 17/19 (89%) | 90%+ | +1% needed |

**Critical Issue:** Branch coverage at only 23% indicates many error paths and edge cases are untested.

---

## 🎯 Test Strategy

### Priority 1: Error Path Testing (Branches +25%)
Focus on HTTP error responses: 400, 401, 403, 404, 409, 500

### Priority 2: Validation Testing (Branches +15%)
Test @Valid annotations, constraint violations, malformed requests

### Priority 3: Edge Cases (Branches +7%)
Boundary conditions, null handling, empty collections

---

## 📝 Test Cases to Implement

### 1. AuthController Error Tests

**New File:** `AuthControllerErrorTest.java`

**Test Cases (22 tests):**

```java
// Registration validation errors (400)
- register_WithMissingUsername_ShouldReturn400BadRequest
- register_WithEmptyUsername_ShouldReturn400BadRequest
- register_WithInvalidEmail_ShouldReturn400BadRequest
- register_WithMissingEmail_ShouldReturn400BadRequest
- register_WithMissingPassword_ShouldReturn400BadRequest
- register_WithShortPassword_ShouldReturn400BadRequest
- register_WithNullBody_ShouldReturn400BadRequest

// Registration conflict errors (409)
- register_WithExistingUsername_ShouldReturn409Conflict
- register_WithExistingEmail_ShouldReturn409Conflict

// Login validation errors (400)
- login_WithMissingEmail_ShouldReturn400BadRequest
- login_WithMissingPassword_ShouldReturn400BadRequest
- login_WithInvalidEmailFormat_ShouldReturn400BadRequest
- login_WithEmptyBody_ShouldReturn400BadRequest

// Login authentication errors (401)
- login_WithNonExistentUser_ShouldReturn401Unauthorized
- login_WithWrongPassword_ShouldReturn401Unauthorized

// Protected endpoint errors (401)
- getCurrentUser_WithoutAuthentication_ShouldReturn401Unauthorized
- getCurrentUser_WithInvalidToken_ShouldReturn401Unauthorized
- getCurrentUser_WithMalformedToken_ShouldReturn401Unauthorized
- getCurrentUser_WithMissingBearerPrefix_ShouldReturn401Unauthorized

// Health check
- testEndpoint_ShouldReturnOkWithMessage

// Existing user creation error
- register_AfterDatabaseError_ShouldReturn500InternalServerError
```

**Expected Gains:**
- Instructions: +15%
- Branches: +25%
- Lines: +12%

---

### 2. EventController Error Tests

**New File:** `EventControllerErrorTest.java`

**Test Cases (25 tests):**

```java
// GET /api/events error paths
- getAllEvents_WhenEmpty_ShouldReturnEmptyList
- getAllEvents_WithDatabaseError_ShouldReturn500InternalServerError

// GET /api/events/{id} error paths (404)
- getEventById_WithNonExistentId_ShouldReturn404NotFound
- getEventById_WithInvalidId_ShouldReturn400BadRequest
- getEventById_WithNegativeId_ShouldReturn400BadRequest

// POST /api/events validation errors (400)
- createEvent_WithMissingTitle_ShouldReturn400BadRequest
- createEvent_WithEmptyTitle_ShouldReturn400BadRequest
- createEvent_WithMissingStartDate_ShouldReturn400BadRequest
- createEvent_WithMissingEndDate_ShouldReturn400BadRequest
- createEvent_WithStartDateAfterEndDate_ShouldReturn400BadRequest
- createEvent_WithPastStartDate_ShouldReturn400BadRequest
- createEvent_WithNegativePrice_ShouldReturn400BadRequest
- createEvent_WithNegativePersonLimit_ShouldReturn400BadRequest
- createEvent_WithInvalidCategory_ShouldReturn400BadRequest

// POST /api/events authentication errors (401)
- createEvent_WithoutAuthentication_ShouldReturn401Unauthorized
- createEvent_WithInvalidToken_ShouldReturn401Unauthorized

// PUT /api/events/{id} errors
- updateEvent_WithNonExistentId_ShouldReturn404NotFound
- updateEvent_WithoutAuthentication_ShouldReturn401Unauthorized
- updateEvent_ByNonOwner_ShouldReturn403Forbidden
- updateEvent_WithInvalidData_ShouldReturn400BadRequest

// DELETE /api/events/{id} errors
- deleteEvent_WithNonExistentId_ShouldReturn404NotFound
- deleteEvent_WithoutAuthentication_ShouldReturn401Unauthorized
- deleteEvent_ByNonOwner_ShouldReturn403Forbidden
```

**Expected Gains:**
- Instructions: +12%
- Branches: +20%
- Lines: +10%

---

### 3. UserController Error Tests

**New File:** `UserControllerErrorTest.java`

**Test Cases (15 tests):**

```java
// PUT /api/users/me validation errors (400)
- updateUser_WithMissingFields_ShouldReturn400BadRequest
- updateUser_WithInvalidEmail_ShouldReturn400BadRequest
- updateUser_WithEmptyUsername_ShouldReturn400BadRequest

// PUT /api/users/me authentication errors (401)
- updateUser_WithoutAuthentication_ShouldReturn401Unauthorized
- updateUser_WithInvalidToken_ShouldReturn401Unauthorized

// PUT /api/users/me conflict errors (409)
- updateUser_WithExistingEmail_ShouldReturn409Conflict
- updateUser_WithExistingUsername_ShouldReturn409Conflict

// GET /api/users/{id} errors (404)
- getUserById_WithNonExistentId_ShouldReturn404NotFound
- getUserById_WithInvalidId_ShouldReturn400BadRequest
- getUserById_WithNegativeId_ShouldReturn400BadRequest

// DELETE /api/users/{id} errors
- deleteUser_WithoutAuthentication_ShouldReturn401Unauthorized
- deleteUser_WrongUser_ShouldReturn403Forbidden
- deleteUser_NonExistentUser_ShouldReturn404NotFound

// Edge cases
- getAllUsers_WhenEmpty_ShouldReturnEmptyList
- getUserProfile_WithDeletedUser_ShouldReturn404NotFound
```

**Expected Gains:**
- Instructions: +8%
- Branches: +15%
- Lines: +7%

---

## 🔨 Implementation Steps

### Step 1: Setup Test Base Class (Optional)

Create `BaseControllerTest.java` for shared test utilities:

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public abstract class BaseControllerTest {
    
    @Autowired
    protected MockMvc mockMvc;
    
    @Autowired
    protected ObjectMapper objectMapper;
    
    protected String registerAndGetToken(String username, String email) throws Exception {
        // Helper method to create user and get JWT token
    }
    
    protected ResultActions performWithAuth(MockHttpServletRequestBuilder request, String token) {
        // Helper method to add Authorization header
    }
}
```

### Step 2: Create AuthControllerErrorTest

```bash
cd main_backend/src/test/java/com/concert/controller
# Create new file: AuthControllerErrorTest.java
# Implement 22 test cases from the list above
```

**Key Patterns:**

```java
@Test
void register_WithMissingUsername_ShouldReturn400BadRequest() throws Exception {
    RegisterRequest request = new RegisterRequest();
    request.setEmail("test@example.com");
    request.setPassword("password123");
    // Missing username
    
    mockMvc.perform(post("/api/auth/register")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").exists());
}
```

### Step 3: Create EventControllerErrorTest

```bash
# Create new file: EventControllerErrorTest.java
# Implement 25 test cases
```

**Key Patterns:**

```java
@Test
void createEvent_WithoutAuthentication_ShouldReturn401Unauthorized() throws Exception {
    CreateEventRequest request = validEventRequest();
    
    mockMvc.perform(post("/api/events")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isUnauthorized());
}

@Test
void updateEvent_ByNonOwner_ShouldReturn403Forbidden() throws Exception {
    // Create event as user1
    String user1Token = registerAndGetToken("user1", "user1@example.com");
    Long eventId = createEvent(user1Token);
    
    // Try to update as user2
    String user2Token = registerAndGetToken("user2", "user2@example.com");
    
    mockMvc.perform(put("/api/events/" + eventId)
            .header("Authorization", "Bearer " + user2Token)
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(validEventRequest())))
            .andExpect(status().isForbidden());
}
```

### Step 4: Create UserControllerErrorTest

```bash
# Create new file: UserControllerErrorTest.java
# Implement 15 test cases
```

### Step 5: Run Tests and Verify Coverage

```bash
cd main_backend
$env:JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-25.0.0.36-hotspot\"
.\mvnw.cmd clean test jacoco:report -DforkCount=1 -DreuseForks=false
```

**Check coverage:**
```bash
# Open: target/site/jacoco/index.html
# Navigate to: com.concert.controller package
# Verify:
# - Instructions: 80%+ (target met)
# - Branches: 70%+ (significant improvement)
# - Lines: 80%+ (target met)
```

---

## 📈 Expected Results After Implementation

### Before (Current)
```
Package: com.concert.controller
Instructions: 211/334 (63%)
Branches: 9/38 (23%)
Lines: 55/75 (73%)
Methods: 17/19 (89%)
```

### After (Projected)
```
Package: com.concert.controller
Instructions: 300/334 (90%) ✅ +27%
Branches: 32/38 (84%) ✅ +61%
Lines: 68/75 (91%) ✅ +18%
Methods: 19/19 (100%) ✅ +11%
```

### Total New Tests
- AuthControllerErrorTest: 22 tests
- EventControllerErrorTest: 25 tests
- UserControllerErrorTest: 15 tests
- **Total: 62 new tests**

### New Backend Test Count
- Current: 134 tests
- After: 196 tests (+46%)

---

## 🧪 Testing Checklist

### Phase 1: Validation Errors (400)
- [ ] Missing required fields
- [ ] Empty strings
- [ ] Invalid formats (email, etc.)
- [ ] Constraint violations (@NotBlank, @Min, @Max)
- [ ] Null values
- [ ] Invalid JSON syntax

### Phase 2: Authentication Errors (401)
- [ ] Missing Authorization header
- [ ] Invalid JWT token
- [ ] Expired JWT token
- [ ] Malformed token format
- [ ] Wrong credentials

### Phase 3: Authorization Errors (403)
- [ ] Access other user's resources
- [ ] Modify without ownership
- [ ] Delete without ownership

### Phase 4: Not Found Errors (404)
- [ ] Non-existent resource IDs
- [ ] Deleted resources
- [ ] Invalid ID formats

### Phase 5: Conflict Errors (409)
- [ ] Duplicate username
- [ ] Duplicate email
- [ ] Unique constraint violations

### Phase 6: Server Errors (500)
- [ ] Database connection failures
- [ ] Unexpected exceptions
- [ ] Service layer errors

---

## 🎯 Success Criteria

✅ Controller package coverage ≥ 80%  
✅ Branch coverage ≥ 70%  
✅ All HTTP error codes tested (400, 401, 403, 404, 409, 500)  
✅ All validation constraints tested  
✅ All authentication/authorization paths tested  
✅ No regression in existing tests  
✅ All new tests passing  
✅ JaCoCo report shows green for controllers  

---

## 📚 Additional Resources

- [Spring MockMvc Documentation](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/servlet/MockMvc.html)
- [Testing REST Controllers](https://spring.io/guides/gs/testing-web/)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)
- [MockMvc Status Matchers](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/test/web/servlet/result/StatusResultMatchers.html)

---

## 🚀 Quick Start Commands

```bash
# Navigate to backend
cd main_backend

# Create test files
New-Item -ItemType File -Path "src/test/java/com/concert/controller/AuthControllerErrorTest.java"
New-Item -ItemType File -Path "src/test/java/com/concert/controller/EventControllerErrorTest.java"
New-Item -ItemType File -Path "src/test/java/com/concert/controller/UserControllerErrorTest.java"

# Run tests
$env:JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-25.0.0.36-hotspot\"
.\mvnw.cmd test -Dtest=*ErrorTest

# Full test suite with coverage
.\mvnw.cmd clean test jacoco:report -DforkCount=1 -DreuseForks=false

# Open coverage report
Invoke-Item target\site\jacoco\index.html
```

---

**Estimated Time:** 4-6 hours  
**Complexity:** Medium  
**Impact:** High (coverage improvement + better error handling validation)
