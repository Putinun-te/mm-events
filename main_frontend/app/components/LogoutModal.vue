<script setup lang="ts">
import { defineProps, defineEmits } from 'vue'

defineProps<{
  show: boolean
}>()

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()
</script>

<template>
  <Transition name="modal">
    <div v-if="show" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" @click.self="emit('cancel')">
      <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8 transform transition-all animate-modal-enter">
        <div class="text-center">
          <div class="text-6xl mb-4 animate-wave">👋</div>
          <h3 class="text-2xl font-bold text-gray-900 mb-2">Logout Confirmation</h3>
          <p class="text-gray-600 mb-8">Are you sure you want to logout? You'll need to login again to access your account.</p>
          
          <div class="flex gap-4">
            <button 
              @click="emit('cancel')"
              class="flex-1 px-6 py-3 border-2 border-gray-300 text-gray-700 rounded-lg font-semibold hover:bg-gray-50 active:scale-95 transition-all"
            >
              Cancel
            </button>
            <button 
              @click="emit('confirm')"
              class="flex-1 px-6 py-3 bg-gradient-to-r from-red-500 to-red-600 text-white rounded-lg font-semibold hover:shadow-lg active:scale-95 transition-all"
            >
              Yes, Logout
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.animate-modal-enter {
  animation: modalScale 0.3s ease;
}

@keyframes modalScale {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

.animate-wave {
  animation: wave 0.5s ease;
}

@keyframes wave {
  0%, 100% { transform: rotate(0deg); }
  25% { transform: rotate(-10deg); }
  75% { transform: rotate(10deg); }
}
</style>
