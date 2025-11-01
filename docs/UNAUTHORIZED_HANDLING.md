# Unauthorized User Handling (Logged Out Users)

## Overview
This document explains how the application handles unauthorized users (when users are logged out or their session expires).

## Problem Solved
When users are not authorized (logged out), the application needs to:
1. Detect unauthorized access attempts
2. Clear any stale authentication data
3. Show appropriate error messages
4. Redirect to login page
5. Remember where they wanted to go
6. Redirect back after successful login

## Components

### 1. Global Auth Middleware (`middleware/auth.global.ts`)

**Purpose**: Automatically checks authentication before accessing protected routes

**Protected Routes**:
- `/AccountPage` - User profile and settings
- `/MyBookingsPage` - View user's bookings
- `/MyEventsPage` - View user's events
- `/CreateEventPage` - Create new events
- `/EditEventPage` - Edit existing events

**How it works**:
```typescript
// Checks for JWT token in localStorage/sessionStorage
const token = localStorage.getItem('jwt_token') || sessionStorage.getItem('jwt_token')

if (!token) {
  // Store intended destination
  localStorage.setItem('redirect_after_login', to.fullPath)
  
  // Redirect to login
  return navigateTo('/LoginPage')
}
```

**Example Flow**:
1. User (logged out) tries to access `/MyBookingsPage`
2. Middleware detects no token
3. Stores `/MyBookingsPage` for later redirect
4. Redirects to `/LoginPage`
5. After login, redirects back to `/MyBookingsPage`

### 2. Unauthorized Handler Composable (`composables/useUnauthorizedHandler.ts`)

**Purpose**: Centralized handling for 401/403 errors from API calls

**Methods**:

#### `handleUnauthorized(message?, currentPath?)`
Handles unauthorized state:
- Clears authentication data
- Shows error message
- Stores current path
- Redirects to login

#### `isUnauthorizedError(error)`
Checks if error is 401 or 403:
```typescript
const status = error?.statusCode || error?.status || error?.response?.status
return status === 401 || status === 403
```

#### `handleApiError(error, currentPath?)`
Automatic error handling:
```typescript
if (isUnauthorizedError(error)) {
  handleUnauthorized(message, currentPath)
  return true  // Error was handled
}
return false  // Not an auth error, handle differently
```

**Usage Example**:
```vue
<script setup>
import { useUnauthorizedHandler } from '~/composables/useUnauthorizedHandler'

const { handleApiError } = useUnauthorizedHandler()

async function fetchData() {
  try {
    const data = await $fetch('/api/bookings/me', {
      headers: { Authorization: `Bearer ${token}` }
    })
    // Handle success
  } catch (error) {
    // Automatically handle 401/403
    if (handleApiError(error, '/MyBookingsPage')) {
      return  // User was logged out, redirected to login
    }
    
    // Handle other errors
    showError('Failed to load data')
  }
}
</script>
```

### 3. Updated Login Component

**New Feature**: Redirect to intended page after login

```typescript
// After successful login
const redirectPath = localStorage.getItem('redirect_after_login')
if (redirectPath) {
  localStorage.removeItem('redirect_after_login')
  await navigateTo(redirectPath)  // Go to originally requested page
} else {
  await navigateTo('/')  // Default to home
}
```

**User Experience Flow**:
1. User (logged out) tries to view bookings → redirected to login
2. User logs in successfully
3. Automatically redirected to bookings page
4. Seamless experience!

### 4. Updated Pages with Auth Handling

#### MyBookingsPage.vue
```vue
<script setup>
import { useUnauthorizedHandler } from '~/composables/useUnauthorizedHandler'

const { handleApiError } = useUnauthorizedHandler()

async function fetchBookings() {
  try {
    const res = await $fetch('/api/bookings/me', {
      headers: { Authorization: `Bearer ${token}` }
    })
    // Success
  } catch (err) {
    // Auto-handle unauthorized
    if (handleApiError(err, '/MyBookingsPage')) return
    
    // Handle other errors
    message.value = 'Failed to load bookings'
  }
}

async function cancelBooking(id) {
  try {
    const response = await fetch(`/api/bookings/${id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    })
    
    // Check for unauthorized
    if (response.status === 401 || response.status === 403) {
      if (handleApiError({ statusCode: response.status }, '/MyBookingsPage')) {
        return
      }
    }
    
    // Success handling
  } catch (err) {
    // Error handling
  }
}
</script>
```

## Error Messages

### User-Friendly Messages:
- **Session Expired**: "Your session has expired. Please login again."
- **Not Logged In**: "You must be logged in to access this page."
- **Authentication Required**: "Please login to continue."

### Where Messages Appear:
1. **Toast Notifications** - Top-right corner using `useToast`
2. **Inline Messages** - On the page itself
3. **Modal Dialogs** - For critical actions

## Backend API Responses

### Standard 401 Response:
```json
{
  "statusCode": 401,
  "statusMessage": "Authorization header missing",
  "message": "Please login to continue"
}
```

### Standard 403 Response:
```json
{
  "statusCode": 403,
  "statusMessage": "Forbidden",
  "message": "You don't have permission to access this resource"
}
```

## Testing Scenarios

### Scenario 1: Token Expires During Session
1. User is logged in, viewing bookings
2. Token expires (or backend invalidates it)
3. User tries to cancel a booking
4. API returns 401
5. `handleApiError` detects 401
6. User sees "Session expired" message
7. Redirected to login page
8. After login, redirected back to bookings

### Scenario 2: Direct URL Access While Logged Out
1. User (logged out) pastes `/MyBookingsPage` URL
2. Middleware intercepts
3. No token found
4. Stores `/MyBookingsPage` for later
5. Redirects to `/LoginPage`
6. User logs in
7. Automatically goes to `/MyBookingsPage`

### Scenario 3: Manual Logout
1. User clicks "Logout" button
2. `clearAuth()` removes token and user data
3. Redirected to home page
4. If user tries to access protected page
5. Middleware catches it
6. Redirects to login

## Best Practices

### 1. Always Check Token Before API Calls
```typescript
const token = localStorage.getItem('jwt_token')
if (!token) {
  router.push('/LoginPage')
  return
}
```

### 2. Use Unauthorized Handler for API Errors
```typescript
catch (error) {
  if (handleApiError(error, currentPath)) return
  // Handle other errors
}
```

### 3. Provide Clear User Feedback
```typescript
error('Your session has expired. Please login again.', 'Authentication Required')
```

### 4. Preserve User Intent
```typescript
localStorage.setItem('redirect_after_login', currentPath)
```

## Files Modified/Created

### Created:
- ✅ `middleware/auth.global.ts` - Global auth middleware
- ✅ `composables/useUnauthorizedHandler.ts` - Centralized unauthorized handling
- ✅ `UNAUTHORIZED_HANDLING.md` - This documentation

### Modified:
- ✅ `app/components/Login.vue` - Added redirect after login
- ✅ `app/pages/MyBookingsPage.vue` - Integrated unauthorized handler
- 🔄 Need to update: `AccountPage.vue`, `MyEventsPage.vue`, `CreateEventPage.vue`, `EditEventPage.vue`

## Next Steps

To apply unauthorized handling to other pages:

1. Import the composable:
```typescript
import { useUnauthorizedHandler } from '~/composables/useUnauthorizedHandler'
```

2. Use it in error handling:
```typescript
const { handleApiError } = useUnauthorizedHandler()

catch (error) {
  if (handleApiError(error, '/CurrentPage')) return
  // Handle other errors
}
```

3. Test the flow:
- Access page while logged out
- Let token expire during session
- Try actions after logout

## Summary

This implementation provides:
- ✅ Automatic detection of logged-out users
- ✅ Graceful redirect to login
- ✅ Preservation of user intent
- ✅ Clear error messages
- ✅ Consistent handling across the app
- ✅ Better user experience
- ✅ Secure access control
