<script setup lang="ts">
interface Props {
  show: boolean
  title?: string
  confirmText?: string
  cancelText?: string
  confirmColor?: string
}

const props = withDefaults(defineProps<Props>(), {
  confirmText: 'Confirm',
  cancelText: 'Cancel',
  confirmColor: 'bg-purple-600 hover:bg-purple-700'
})

const emit = defineEmits<{
  confirm: []
  cancel: []
  close: []
}>()

const handleBackdropClick = (event: MouseEvent) => {
  if (event.target === event.currentTarget) {
    emit('close')
  }
}
</script>

<template>
  <Transition name="modal">
    <div v-if="show" @click="handleBackdropClick" class="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full transform transition-all">
        <div v-if="title" class="px-6 pt-6 pb-4 border-b border-gray-200">
          <h3 class="text-xl font-bold text-gray-900">{{ title }}</h3>
        </div>
        
        <div class="p-6">
          <slot></slot>
        </div>
        
        <div class="px-6 pb-6 flex gap-3 justify-end">
          <button @click="emit('cancel')" class="px-6 py-2.5 border-2 border-gray-300 text-gray-700 font-semibold rounded-lg hover:bg-gray-50 transition-colors">
            {{ cancelText }}
          </button>
          <button @click="emit('confirm')" :class="['px-6 py-2.5 text-white font-semibold rounded-lg transition-colors', confirmColor]">
            {{ confirmText }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .bg-white,
.modal-leave-to .bg-white {
  transform: scale(0.9);
}
</style>
