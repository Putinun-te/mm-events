# Testing Roadmap - Coverage Improvement Plan

**Date**: October 16, 2025  
**Current Status**: 85.51% Branches → **Goal: 90% Branches**  
**Gap**: +4.49% needed

---

## 📊 Current Test Status

### Frontend (Nuxt 4)
- **Tests**: 570 passed | 1 skipped (571 total)
- **Test Files**: 34 files
- **Coverage**:
  - ✅ Statements: **91.17%** (Goal: 90%)
  - ✅ Lines: **91.17%** (Goal: 90%)
  - ⚠️ Branches: **85.51%** (Goal: 90%, need +4.49%)
  - ⚠️ Functions: **77.98%** (Goal: 90%, need +12.02%)

### Backend (Spring Boot)
- **Tests**: 228 tests
- **Coverage**:
  - ✅ Instructions: **97%** (Excellent)
  - ✅ Branches: **89%** (Near target)

---

## 🎯 Priority Order for Frontend Branch Coverage

### **Step 1: MyBookingsPage.vue** ⭐⭐⭐⭐⭐ (HIGHEST PRIORITY)
- **Current**: 63.63% branches (21 tests)
- **Target**: 85-90% branches
- **Gap**: 26.37% (BIGGEST IMPACT)
- **Estimated Tests**: +15-18 tests
- **Uncovered Lines**: 80, 89-93, 95-142

**Focus Areas**:
```javascript
✓ fetchBookings() - Error handling paths
  - Token validation (no token case)
  - Non-array response handling
  - Empty bookings array
  - Error responses with/without messages
  - Default error fallback

✓ confirmCancelBooking() - All error branches
  - No bookingToCancel (early return)
  - Missing token validation
  - Non-ok response (status !== 200)
  - 401/403 status codes (auth errors)
  - JSON parse errors
  - Error message fallbacks
  - Local state updates after cancel

✓ formatDate() - Edge cases
  - Empty string → 'TBA'
  - Null/undefined → 'TBA'
  - Valid date formatting

✓ openCancelModal() - Validation
  - Setting bookingToCancel
  - Modal state management
```

**Testing Strategy**:
- ✅ Use explicit function calls (not mount-time behavior)
- ✅ Mock responses AFTER mount, before function call
- ✅ Ensure useAuth mock includes `isLoggedIn: { value: true }`
- ✅ Use vi.clearAllMocks() between tests
- ❌ Avoid testing onMounted side effects

---

### **Step 2: ProductPageDetail/[id].vue** ⭐⭐⭐⭐
- **Current**: 73.68% branches (39 tests)
- **Target**: 88-90% branches
- **Gap**: 16.32%
- **Estimated Tests**: +12-15 tests
- **Uncovered Lines**: 85-86, 330, 389-425

**Focus Areas**:
```javascript
✓ Route param validation
  - Missing id parameter
  - Invalid id format
  - Non-existent event id

✓ fetchEventDetail() - Error paths
  - API errors
  - Event not found (404)
  - Network failures
  - Token validation

✓ Booking flow branches
  - Quantity validation (min/max)
  - Insufficient availability
  - Authentication checks
  - Payment calculation branches

✓ addToCart() - Edge cases
  - Guest vs authenticated user
  - Cart limit validation
  - Duplicate event handling
```

---

### **Step 3: EditEventPage.vue** ⭐⭐⭐
- **Current**: 79.59% branches (37 tests)
- **Target**: 90%+ branches
- **Gap**: 10.41%
- **Estimated Tests**: +8-10 tests
- **Uncovered Lines**: 149-152, 199-202

**Focus Areas**:
```javascript
✓ Form validation edge cases
  - Missing required fields
  - Invalid date ranges
  - Negative prices/quantities

✓ Image upload error handling
  - Large file size
  - Invalid file types
  - Upload failures

✓ Update event errors
  - API failures
  - Validation errors from backend
  - Unauthorized updates
```

---

### **Step 4: MyEventsPage.vue** ⭐⭐
- **Current**: 80.55% branches (52 tests)
- **Target**: 90%+ branches
- **Gap**: 9.45%
- **Estimated Tests**: +6-8 tests
- **Uncovered Lines**: 71-72, 78-79

**Focus Areas**:
```javascript
✓ Event deletion edge cases
  - Delete confirmation flow
  - Delete API errors
  - Events with active bookings

✓ Status filtering branches
  - All/Active/Past filters
  - Empty state handling per filter
```

---

### **Step 5: CreateEventPage.vue** ⭐⭐ (ALREADY EXCELLENT)
- **Current**: 92.45% branches (56 tests) ✅
- **Target**: 95%+ branches (polish)
- **Gap**: Only 2.55% below target (but already above 90%!)
- **Estimated Tests**: +3-5 tests
- **Uncovered Lines**: 80-83, 175

---

## ⚠️ Files to AVOID (Low ROI)

| File | Current | Reason |
|------|---------|--------|
| AccountPage.vue | 81.53% | Previous attempt: +15 tests = only +0.02% overall gain |
| Login.vue | 85.71% | Already high, diminishing returns |
| Register.vue | 96.29% | Already excellent |
| MapTestingPage.vue | N/A | Has unhandled errors (longdo API issues) |

---

## 📅 Execution Timeline

### **Week 1: MyBookingsPage.vue**
- Day 1-2: Analyze uncovered branches, write 15-18 tests
- Day 3: Run tests, debug mock issues
- Day 4: Verify coverage improvement
- **Expected**: 63.63% → 85%+ branches

### **Week 2: ProductPageDetail/[id].vue**
- Day 1-2: Write 12-15 route/booking tests
- Day 3: Test and debug
- **Expected**: 73.68% → 88%+ branches

### **Week 3: EditEventPage.vue**
- Day 1: Write 8-10 validation tests
- Day 2: Test and verify
- **Expected**: 79.59% → 90%+ branches

### **Week 4: Polish MyEventsPage.vue**
- Day 1: Write 6-8 edge case tests
- **Expected**: 80.55% → 90%+ branches

**Result**: Overall 85.51% → 90%+ ✅ **GOAL ACHIEVED**

---

## 🧪 Testing Best Practices Learned

### ✅ What Works Best
1. **Target files in 60-80% range** (best ROI)
2. **Test explicit function calls**, not mount-time behavior
3. **Focus on error paths**: early returns, validations, edge cases
4. **Proper mock setup**:
   - Module-level mocks only
   - Include all required properties (e.g., `isLoggedIn: { value: true }`)
   - Clear mocks between tests with `vi.clearAllMocks()`

### ❌ What to Avoid
1. **Files above 80%** → Diminishing returns (AccountPage example)
2. **Complex mount behavior testing** → Timing issues, unreliable tests
3. **Inline vi.mock() in tests** → ReferenceError issues
4. **Testing side effects** → Test explicit calls instead

---

## 🔧 Mock Setup Patterns

### Correct Mock Pattern:
```typescript
// Module level (CORRECT)
vi.mock('~/composables/useAuth', () => ({
  useAuth: () => ({
    clearAuth: vi.fn(),
    loadFromStorage: vi.fn(),
    isLoggedIn: { value: true }  // ✅ Include all required properties
  })
}))

// In test
it('should handle specific case', async () => {
  const wrapper = mount(Component, {
    global: { plugins: [router] }
  })
  await wrapper.vm.$nextTick()
  
  // Mock AFTER mount for explicit call
  ;(global.$fetch as any).mockResolvedValueOnce({ data: 'value' })
  
  // Call function explicitly
  await wrapper.vm.functionName()
  
  expect(wrapper.vm.state).toBe('expected')
})
```

### Incorrect Pattern (AVOID):
```typescript
it('test', async () => {
  const mockFn = vi.fn()
  vi.mock('~/composables/useToast', () => ({  // ❌ WRONG - inline mock
    useToast: () => ({
      error: mockFn  // ❌ ReferenceError: mockFn not defined
    })
  }))
})
```

---

## 📈 Progress Tracking

### Completed Sessions:
- ✅ Login.vue: 68% → 86% (+16 tests)
- ✅ MyBookingsPage.vue (v1): 63.63% → 75.67% (+15 tests)
- ✅ CreateEventPage.vue: 69.04% → 92.45% (+21 tests)
- ✅ MyEventsPage.vue (v1): 71.87% → 80.55% (+13 tests)
- ✅ EditEventPage.vue (v1): 53.84% → 79.59% (+21 tests)
- ⚠️ AccountPage.vue: 81.25% → 81.53% (+15 tests, +0.02% overall) - LOW ROI
- ❌ MyBookingsPage.vue (v2): 75.67% → Abandoned (+18 tests, 3 failures)

### Current Coverage by Category:
```
Components:
  ✅ CartEach.vue:        100% branches
  ✅ CategoriesTop.vue:   100% branches
  ✅ DatabaseInfo.vue:    100% branches
  ✅ EmptyState.vue:      100% branches
  ✅ EventCardSkeleton:   100% branches
  ✅ LogoutModal.vue:     100% branches
  ✅ SideSearchBar.vue:   100% branches
  ⚠️ Login.vue:           85.71% branches
  ⚠️ Register.vue:        96.29% branches
  ⚠️ NavBar.vue:          80% branches
  ⚠️ ProductCard.vue:     89.47% branches
  ⚠️ Toasts.vue:          60% branches

Pages:
  ✅ AboutUS.vue:         100% branches
  ✅ CartPage.vue:        100% branches
  ✅ DatabasePage.vue:    100% branches
  ✅ LoginPage.vue:       100% branches
  ✅ RegisterPage.vue:    100% branches
  ✅ ProfilePage.vue:     96.66% branches
  ✅ ProductPage.vue:     97.77% branches
  ✅ CreateEventPage.vue: 92.45% branches ⭐
  ⚠️ EditEventPage.vue:   79.59% branches
  ⚠️ MyEventsPage.vue:    80.55% branches
  ⚠️ AccountPage.vue:     81.53% branches
  ⚠️ ProductDetail [id]:  73.68% branches
  ❌ MyBookingsPage.vue:  63.63% branches (NEEDS WORK)
```

---

## 🎯 Success Criteria

### Branch Coverage Target: 90%
- ✅ MyBookingsPage.vue: 63.63% → 85%+
- ✅ ProductPageDetail: 73.68% → 88%+
- ✅ EditEventPage.vue: 79.59% → 90%+
- ✅ MyEventsPage.vue: 80.55% → 90%+

### Overall Impact:
- Current: 85.51% branches
- After Step 1 (MyBookings): ~87.5%
- After Step 2 (ProductDetail): ~89%
- After Step 3 (EditEvent): ~90%+ ✅ **GOAL REACHED**

---

## 📝 Notes

**Key Insight**: Files with coverage above 80% have diminishing returns. AccountPage gained only +0.02% overall despite adding 15 tests. Focus on files in the 60-80% range for maximum impact.

**Mock Stability**: Complex mount-time behavior is difficult to test reliably. Previous MyBookingsPage v2 attempt encountered persistent mock issues and was abandoned. New approach should test explicit function calls.

**Docker Integration**: Backend tests use Testcontainers and require Docker Desktop running. No docker-compose needed for tests.

---

## 🚀 Quick Start Commands

### Frontend Tests
```bash
cd main_frontend/concert1

# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test MyBookingsPage.test.ts

# Watch mode
npm test -- --watch
```

### Backend Tests
```bash
cd main_backend

# Run tests with coverage (JDK 21 required)
export JAVA_HOME=$(/usr/libexec/java_home -v 21)  # macOS
mvn -DforkCount=1 -DreuseForks=false test jacoco:report

# View coverage report
open target/site/jacoco/index.html
```

### Coverage Reports
- Frontend: `main_frontend/concert1/coverage/index.html`
- Backend: `main_backend/target/site/jacoco/index.html`

---

**Last Updated**: October 16, 2025  
**Next Review**: After completing Step 1 (MyBookingsPage.vue)
