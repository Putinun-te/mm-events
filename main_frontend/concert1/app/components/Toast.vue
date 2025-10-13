<script setup lang="ts">
interface Props {
  type?: 'success' | 'error' | 'info' | 'warning'
  message: string
  show: boolean
}

const props = withDefaults(defineProps<Props>(), {
  type: 'info'
})

const emit = defineEmits<{
  close: []
}>()

const icons = {
  success: '✅',
  error: '❌',
  info: 'ℹ️',
  warning: '⚠️'
}

const colors = {
  success: 'bg-green-50 border-green-200 text-green-800',
  error: 'bg-red-50 border-red-200 text-red-800',
  info: 'bg-blue-50 border-blue-200 text-blue-800',
  warning: 'bg-yellow-50 border-yellow-200 text-yellow-800'
}
</script>

<template>
  <Transition name="toast">
    <div v-if="show" :class="['fixed top-20 right-4 z-50 max-w-md p-4 rounded-lg shadow-2xl border-2 flex items-center gap-3 animate-slide-in', colors[type]]">
      <span class="text-2xl">{{ icons[type] }}</span>
      <p class="flex-1 font-medium">{{ message }}</p>
      <button @click="emit('close')" class="text-gray-500 hover:text-gray-700 font-bold text-xl">×</button>
    </div>
  </Transition>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100px);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100px);
}

@keyframes slide-in {
  from {
    transform: translateX(100px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.animate-slide-in {
  animation: slide-in 0.3s ease-out;
}
</style>
