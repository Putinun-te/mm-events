<script setup lang="ts">
import { ref } from 'vue'
import { useAuth } from '~/composables/useAuth'

const props = defineProps<{
  show: boolean
  eventName?: string
}>()

const emit = defineEmits<{
  close: []
  loginSuccess: []
  switchToRegister: []
}>()

const auth = useAuth()
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const rememberMe = ref(false)
const isLoading = ref(false)
const errorMessage = ref('')

const handleSubmit = async () => {
  if (!email.value || !password.value) {
    errorMessage.value = 'Please fill in all fields'
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    const response = await fetch('http://localhost:8080/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: email.value, password: password.value })
    })

    if (response.ok) {
      const data = await response.json()
      auth.saveAuth(data, rememberMe.value)
      emit('loginSuccess')
      emit('close')
    } else {
      errorMessage.value = 'Invalid email or password'
    }
  } catch (error) {
    errorMessage.value = 'Login failed. Please try again.'
  } finally {
    isLoading.value = false
  }
}

const handleBackdropClick = (event: MouseEvent) => {
  if (event.target === event.currentTarget) {
    emit('close')
  }
}
</script>

<template>
  <Transition name="modal">
    <div v-if="show" @click="handleBackdropClick" class="fixed inset-0 bg-black/60 backdrop-blur-md z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-2xl shadow-2xl max-w-md w-full transform transition-all">
        <div class="bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 text-white px-6 py-8 rounded-t-2xl text-center">
          <div class="text-5xl mb-4">🎪</div>
          <h2 class="text-2xl font-bold mb-2">Login Required</h2>
          <p v-if="eventName" class="text-purple-100 text-sm">Please login to register for "{{ eventName }}"</p>
          <p v-else class="text-purple-100 text-sm">Please login to continue</p>
        </div>

        <form @submit.prevent="handleSubmit" class="p-8 space-y-6">
          <div v-if="errorMessage" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
            <p class="text-red-700 text-sm">{{ errorMessage }}</p>
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Email</label>
            <input v-model="email" type="email" placeholder="your@email.com" class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all" required />
          </div>

          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">Password</label>
            <div class="relative">
              <input v-model="password" :type="showPassword ? 'text' : 'password'" placeholder="••••••••" class="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all pr-12" required />
              <button type="button" @click="showPassword = !showPassword" class="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700">
                {{ showPassword ? '👁️' : '🙈' }}
              </button>
            </div>
          </div>

          <div class="flex items-center justify-between">
            <label class="flex items-center gap-2 cursor-pointer">
              <input v-model="rememberMe" type="checkbox" class="w-4 h-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500" />
              <span class="text-sm text-gray-700">Remember me</span>
            </label>
            <a href="#" class="text-sm text-purple-600 hover:text-purple-700 font-medium">Forgot password?</a>
          </div>

          <button type="submit" :disabled="isLoading" class="w-full py-3 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2">
            <LoadingSpinner v-if="isLoading" />
            <span>{{ isLoading ? 'Logging in...' : 'Login & Continue' }}</span>
          </button>

          <div class="text-center">
            <p class="text-sm text-gray-600">
              Don't have an account?
              <button type="button" @click="emit('switchToRegister')" class="text-purple-600 hover:text-purple-700 font-semibold">
                Sign up here
              </button>
            </p>
          </div>
        </form>

        <button @click="emit('close')" class="absolute top-4 right-4 w-8 h-8 flex items-center justify-center bg-white/20 hover:bg-white/30 backdrop-blur-sm rounded-full text-white transition-all">
          ✕
        </button>
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
