# Toast Notifications - Enhanced System Guide

## Overview
The toast notification system has been significantly enhanced with better visual design, icons, animations, and helper methods for improved developer experience and user feedback.

## Features

### 1. **Enhanced Visual Design**
- **Clean, modern cards** with backdrop blur and subtle borders
- **Color-coded backgrounds** based on notification type
- **Proper spacing and typography** for better readability
- **Smooth slide-in/slide-out animations** from the top-right corner

### 2. **Icon System**
Each notification type has a dedicated SVG icon:
- ✓ **Success** - Checkmark icon in green
- ✗ **Error** - X mark icon in red
- ⚠ **Warning** - Alert triangle icon in yellow
- ℹ **Info** - Information circle icon in blue

### 3. **Helper Methods**
Convenient methods for each notification type:

```typescript
const { success, error, warning, info } = useToast()

// Success notifications (5 seconds, green)
success('Operation completed', 'Success!')

// Error notifications (7 seconds, red)
error('Something went wrong', 'Error')

// Warning notifications (6 seconds, yellow)
warning('Please review your input', 'Warning')

// Info notifications (5 seconds, blue)
info('New feature available', 'Info')
```

### 4. **Optional Titles**
Each notification can have an optional title for better context:

```typescript
success('Your profile has been updated successfully', 'Profile Updated')
error('Failed to connect to server', 'Connection Error')
```

### 5. **Auto-Dismiss**
Notifications automatically dismiss after a set duration:
- **Success**: 5 seconds
- **Error**: 7 seconds (longer for users to read error details)
- **Warning**: 6 seconds
- **Info**: 5 seconds

### 6. **Manual Dismissal**
Users can manually dismiss any notification by clicking the X button in the top-right corner.

### 7. **Multiple Notifications**
The system supports showing multiple notifications simultaneously, stacked vertically.

## Usage Examples

### Basic Usage

```vue
<script setup lang="ts">
import { useToast } from '~/composables/useToast'

const { success, error, info, warning } = useToast()

async function saveData() {
  try {
    await $fetch('/api/save', { method: 'POST', body: data })
    success('Data saved successfully!', 'Success')
  } catch (e) {
    error('Failed to save data', 'Error')
  }
}
</script>
```

### Advanced Usage

```typescript
// Custom timeout (in milliseconds)
const { push } = useToast()
push('Custom message', 'info', 10000, 'Custom Title') // 10 seconds

// Dismiss all notifications
const { dismissAll } = useToast()
dismissAll()

// Dismiss specific notification
const { dismiss } = useToast()
dismiss(notificationId)
```

## Updated Files

### Files Modified:
1. **`app/composables/useToast.ts`**
   - Added `warning` type support
   - Added helper methods: `success()`, `error()`, `info()`, `warning()`
   - Added optional `title` parameter
   - Added `dismissAll()` method
   - Adjusted default timeouts based on severity

2. **`app/components/Toasts.vue`**
   - Complete redesign with better styling
   - SVG icon system for each notification type
   - Smooth slide-in/slide-out animations
   - Backdrop blur effect for modern look
   - Better color schemes (using Tailwind utility classes)
   - Close button with hover effects

3. **Updated all pages to use new helper methods:**
   - `app/components/NavBar.vue`
   - `app/pages/ProductPageDetail/[id].vue`
   - `app/pages/AccountPage.vue`
   - `app/pages/CreateEventPage.vue`

## Before & After

### Before:
```typescript
const { push: toast } = useToast()
toast('Logged out successfully', 'success')
```

### After:
```typescript
const { success } = useToast()
success('Logged out successfully', 'Goodbye!')
```

## Benefits

1. **Better UX** - Clear, visually appealing notifications with proper icons
2. **Improved DX** - Cleaner API with helper methods instead of remembering type strings
3. **Consistency** - All notifications follow the same design pattern
4. **Accessibility** - Clear visual hierarchy, dismissible, auto-dismiss for non-critical info
5. **Modern Design** - Backdrop blur, smooth animations, and proper spacing
6. **Contextual Timing** - Errors stay longer than success messages for better readability

## Animation Details

- **Slide In**: 0.3s ease-out from right (translateX: 100% → 0%)
- **Slide Out**: 0.3s ease-in to right (translateX: 0% → 100%)
- **Opacity**: Fades in/out alongside slide animation

## Positioning
- Fixed position: Top-right corner (16px from top and right)
- Z-index: 50 (ensures notifications appear above most content)
- Max-width: 448px (md breakpoint)
- Stacked vertically with 12px gap

## Next Steps

Consider adding:
- Progress bar showing time until auto-dismiss
- Sound effects for different notification types (optional, user preference)
- Notification history/log
- Grouped notifications (e.g., "3 new notifications")
- Custom action buttons within notifications
- Persistent notifications (no auto-dismiss) for critical errors
