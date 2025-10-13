<script setup lang="ts">
import { useToast } from '~/composables/useToast'
const { toasts, dismiss } = useToast()

const getToastStyles = (type: string) => {
  const baseStyles = 'px-5 py-4 rounded-lg shadow-lg text-sm backdrop-blur-sm border'
  const typeStyles = {
    success: 'bg-green-50 border-green-200 text-green-900',
    error: 'bg-red-50 border-red-200 text-red-900',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-900',
    info: 'bg-blue-50 border-blue-200 text-blue-900'
  }
  return `${baseStyles} ${typeStyles[type as keyof typeof typeStyles] || typeStyles.info}`
}

const getIconSvg = (type: string) => {
  const icons = {
    success: `<svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
    </svg>`,
    error: `<svg class="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
    </svg>`,
    warning: `<svg class="w-5 h-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
    </svg>`,
    info: `<svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
    </svg>`
  }
  return icons[type as keyof typeof icons] || icons.info
}
</script>

<template>
  <div class="fixed top-4 right-4 z-50 space-y-3 max-w-md">
    <transition-group name="toast">
      <div
        v-for="t in toasts"
        :key="t.id"
        :class="getToastStyles(t.type)"
        class="toast-enter-active toast-leave-active"
      >
        <div class="flex items-start gap-3">
          <!-- Icon -->
          <div class="flex-shrink-0 mt-0.5" v-html="getIconSvg(t.type)"></div>
          
          <!-- Content -->
          <div class="flex-1 min-w-0">
            <p v-if="t.title" class="font-semibold mb-1">{{ t.title }}</p>
            <p class="text-sm leading-relaxed">{{ t.message }}</p>
          </div>
          
          <!-- Close button -->
          <button
            @click="dismiss(t.id)"
            class="flex-shrink-0 opacity-60 hover:opacity-100 transition-opacity p-1 rounded hover:bg-black/5"
            aria-label="Dismiss notification"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
      </div>
    </transition-group>
  </div>
</template>

<style scoped>
.toast-enter-active {
  animation: slideInRight 0.3s ease-out;
}

.toast-leave-active {
  animation: slideOutRight 0.3s ease-in;
}

@keyframes slideInRight {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes slideOutRight {
  from {
    transform: translateX(0);
    opacity: 1;
  }
  to {
    transform: translateX(100%);
    opacity: 0;
  }
}
</style>
